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
    @Published public var error: Error?
    @Published public var selectedFilter: LeakyBucketFilter = .lastMonth {
        didSet {
            Task { await analyze() }
        }
    }

    private let transactionService: TransactionService
    private let detector: LeakyBucketDetector
    private var analyzeTask: Task<Void, Never>?

    public init(
        transactionService: TransactionService = .shared,
        detector: LeakyBucketDetector = LeakyBucketDetector()
    ) {
        self.transactionService = transactionService
        self.detector = detector
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
        let task = Task {
            isLoading = true
            isAnalyzing = true
            error = nil
            defer {
                isLoading = false
                isAnalyzing = false
            }

            do {
                try Task.checkCancellation()

                // Fetch a wide window (90+ days) for pattern detection
                let analysisRange = selectedFilter.analysisRange
                let transactions = try await transactionService.fetchTransactions(from: analysisRange.start, to: analysisRange.end)
                try Task.checkCancellation()

                // Run detection on the full window
                let allBuckets = await detector.detect(from: transactions)

                // Filter to buckets with activity in the selected display period
                let displayRange = selectedFilter.dateRange
                buckets = allBuckets.filter { bucket in
                    // Keep bucket if its last occurrence falls within the display window
                    guard let lastOccurrence = bucket.lastOccurrence else { return true }
                    return lastOccurrence >= displayRange.start
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

    public func refresh() async {
        await analyze()
    }
}
