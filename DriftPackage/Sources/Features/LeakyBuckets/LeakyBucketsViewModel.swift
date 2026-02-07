import Foundation
import SwiftUI
import Core
import Services

/// Filter options for leaky bucket analysis
///
/// Detection always uses a 90-day lookback window so recurring patterns
/// can be identified. The filter controls which *display period* is shown,
/// letting users see "this week's leaks" vs "this month's leaks" while
/// the underlying detection stays accurate.
public enum LeakyBucketFilter: Equatable, Hashable {
    case lastWeek
    case lastMonth
    case last3Months
    case dateRange(Date, Date)

    public var label: String {
        switch self {
        case .lastWeek: return "Week"
        case .lastMonth: return "Month"
        case .last3Months: return "3 Months"
        case .dateRange: return "Range"
        }
    }

    /// The short chip label for the segmented control
    public var chipLabel: String { label }

    /// The display period — buckets are filtered to those with activity in this window
    public var dateRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        switch self {
        case .lastWeek:
            let start = calendar.date(byAdding: .day, value: -7, to: now)!
            return (start, now)
        case .lastMonth:
            let start = calendar.date(byAdding: .month, value: -1, to: now)!
            return (start, now)
        case .last3Months:
            let start = calendar.date(byAdding: .month, value: -3, to: now)!
            return (start, now)
        case .dateRange(let from, let to):
            return (from, to)
        }
    }

    /// The analysis window — always at least 90 days to detect recurring patterns
    public var analysisRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        let displayRange = dateRange
        let minStart = calendar.date(byAdding: .day, value: -90, to: now)!
        let analysisStart = min(displayRange.start, minStart)
        return (analysisStart, displayRange.end)
    }

    /// Fixed cases for iteration in the picker (excludes dateRange)
    public static var fixedCases: [LeakyBucketFilter] {
        [.lastWeek, .lastMonth, .last3Months]
    }
}

/// View model for leaky buckets detection
@MainActor
public final class LeakyBucketsViewModel: ObservableObject {
    @Published public private(set) var buckets: [LeakyBucket] = []
    @Published public private(set) var isLoading = false
    @Published public private(set) var isAnalyzing = false
    @Published public private(set) var isAIEnhanced = false
    @Published public private(set) var aiStage: AIProcessingStage?
    @Published public var error: Error?
    @Published public var selectedFilter: LeakyBucketFilter = .lastMonth {
        didSet {
            Task { await analyze() }
        }
    }

    private let transactionService: TransactionService
    private let detector: LeakyBucketDetector
    private let aiService: FoundationModelService
    private var analyzeTask: Task<Void, Never>?
    private var aiEnhanceTask: Task<Void, Never>?
    private var cachedMerchantGroups: [String: [String]]?

    public init(
        transactionService: TransactionService = .shared,
        detector: LeakyBucketDetector = LeakyBucketDetector(),
        aiService: FoundationModelService = .shared
    ) {
        self.transactionService = transactionService
        self.detector = detector
        self.aiService = aiService
    }

    // MARK: - Computed Properties

    public var filterLabel: String {
        selectedFilter.label
    }

    public var totalMonthlyImpact: Decimal {
        buckets.map(\.monthlyImpact).reduce(0, +)
    }

    public var totalYearlyImpact: Decimal {
        totalMonthlyImpact * 12
    }

    public var formattedMonthlyImpact: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: totalMonthlyImpact as NSDecimalNumber) ?? "$0"
    }

    public var formattedYearlyImpact: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: totalYearlyImpact as NSDecimalNumber) ?? "$0"
    }

    public var bucketsByCategory: [(SpendingCategory, [LeakyBucket])] {
        let grouped = Dictionary(grouping: buckets, by: \.category)
        return SpendingCategory.allCases.compactMap { category in
            guard let buckets = grouped[category], !buckets.isEmpty else { return nil }
            return (category, buckets)
        }
    }

    // MARK: - Actions

    public func analyze() async {
        analyzeTask?.cancel()
        aiEnhanceTask?.cancel()
        let task = Task {
            isLoading = true
            isAnalyzing = true
            isAIEnhanced = false
            aiStage = nil
            error = nil
            defer {
                isLoading = false
                isAnalyzing = false
            }

            do {
                try Task.checkCancellation()

                // Fetch transactions
                let analysisRange = selectedFilter.analysisRange
                let transactions = try await transactionService.fetchTransactions(from: analysisRange.start, to: analysisRange.end)
                try Task.checkCancellation()

                // Fast path: algorithmic detection shows results immediately
                let allBuckets = await detector.detect(from: transactions)
                let displayRange = selectedFilter.dateRange
                buckets = allBuckets.filter { bucket in
                    guard let lastOccurrence = bucket.lastOccurrence else { return true }
                    return lastOccurrence >= displayRange.start
                }

                // Slow path: AI enhancement runs in background, updates results when done
                aiEnhanceTask = Task {
                    await enhanceWithAI(transactions: transactions, displayRange: displayRange)
                }
            } catch is CancellationError {
                // Task was cancelled, ignore
            } catch {
                self.error = error
            }
        }
        analyzeTask = task
        await task.value
    }

    /// Background AI enhancement — runs after algorithmic results are already displayed
    private func enhanceWithAI(transactions: [TransactionDTO], displayRange: (start: Date, end: Date)) async {
        do {
            try Task.checkCancellation()

            // Phase 1: AI merchant grouping (use cache if available)
            let uniqueMerchants = Set(transactions.map(\.merchantName))
            let merchantGroups: [String: [String]]?

            if let cached = cachedMerchantGroups,
               Set(cached.values.flatMap { $0 }).isSuperset(of: uniqueMerchants.map { $0.lowercased() }) {
                merchantGroups = cached
            } else {
                aiStage = .groupingMerchants
                merchantGroups = await aiService.groupMerchants(Array(uniqueMerchants))
                if let groups = merchantGroups {
                    cachedMerchantGroups = groups
                }
            }
            try Task.checkCancellation()

            // Phase 2: Re-detect with AI groupings if available
            let aiBuckets: [LeakyBucket]
            if let groups = merchantGroups {
                aiStage = .detectingPatterns
                aiBuckets = await detector.detect(from: transactions, merchantGroups: groups)
            } else {
                // No AI groupings — keep current algorithmic results, still try classification
                aiBuckets = buckets
            }
            try Task.checkCancellation()

            // Phase 3: Classify leaks
            aiStage = .classifyingLeaks
            if let classifications = await aiService.classifyLeaks(aiBuckets) {
                let classified = Self.applyClassifications(aiBuckets, classifications: classifications)
                buckets = classified.filter { bucket in
                    guard let lastOccurrence = bucket.lastOccurrence else { return true }
                    return lastOccurrence >= displayRange.start
                }
                isAIEnhanced = true
            } else if merchantGroups != nil {
                // Got groupings but not classifications — still update with grouped results
                buckets = aiBuckets.filter { bucket in
                    guard let lastOccurrence = bucket.lastOccurrence else { return true }
                    return lastOccurrence >= displayRange.start
                }
                isAIEnhanced = true
            }

            aiStage = nil
        } catch {
            aiStage = nil
        }
    }

    public func refresh() async {
        await analyze()
    }

    // MARK: - Insight Streaming

    /// Returns a streaming insight for the given bucket (called on-demand from detail sheet)
    public func insightStream(for bucket: LeakyBucket) -> AsyncStream<BucketInsightInfo> {
        let fallback = Self.templateInsight(for: bucket)
        return aiService.generateInsight(for: bucket, fallback: fallback)
    }

    // MARK: - Template Insight Fallback

    public static func templateInsight(for bucket: LeakyBucket) -> String {
        let yearly = bucket.formattedYearlyImpact

        switch bucket.category {
        case .food:
            return "Your \(bucket.merchantName.lowercased()) habit adds up to \(yearly) per year. That's equivalent to a nice dinner out every week."
        case .subscriptions:
            return "This subscription costs \(yearly) annually. Are you getting value from it?"
        case .entertainment:
            return "Entertainment at \(bucket.merchantName) totals \(yearly) yearly. Consider if this aligns with your priorities."
        default:
            return "These recurring purchases at \(bucket.merchantName) total \(yearly) per year. Small amounts add up."
        }
    }

    // MARK: - Classification Helpers

    /// Applies AI classifications to buckets: adjusts confidence and filters out non-leaks
    private static func applyClassifications(
        _ buckets: [LeakyBucket],
        classifications: [LeakClassificationInfo]
    ) -> [LeakyBucket] {
        guard buckets.count == classifications.count else { return buckets }

        return zip(buckets, classifications).compactMap { bucket, classification in
            // Filter out items classified as non-leaks with high confidence
            guard classification.isLeak else { return nil }

            let adjustedConfidence = min(1.0, bucket.confidenceScore * classification.confidenceMultiplier)

            return LeakyBucket(
                id: bucket.id,
                merchantName: bucket.merchantName,
                category: bucket.category,
                frequency: bucket.frequency,
                averageAmount: bucket.averageAmount,
                monthlyImpact: bucket.monthlyImpact,
                confidenceScore: adjustedConfidence,
                occurrenceCount: bucket.occurrenceCount,
                firstOccurrence: bucket.firstOccurrence,
                lastOccurrence: bucket.lastOccurrence,
                logoUrl: bucket.logoUrl,
                aiClassification: classification
            )
        }
    }
}
