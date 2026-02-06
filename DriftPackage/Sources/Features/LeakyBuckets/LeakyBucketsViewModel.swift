import Foundation
import SwiftUI
import Core
import Services

/// View model for leaky buckets detection
@MainActor
public final class LeakyBucketsViewModel: ObservableObject {
    @Published public private(set) var buckets: [LeakyBucket] = []
    @Published public private(set) var isLoading = false
    @Published public private(set) var isAnalyzing = false
    @Published public var error: Error?

    private let transactionService: TransactionService
    private let detector: LeakyBucketDetector

    public init(
        transactionService: TransactionService = .shared,
        detector: LeakyBucketDetector = LeakyBucketDetector()
    ) {
        self.transactionService = transactionService
        self.detector = detector
    }

    // MARK: - Computed Properties

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
        formatter.maximumFractionDigits = 0
        return formatter.string(from: totalMonthlyImpact as NSDecimalNumber) ?? "$0"
    }

    public var formattedYearlyImpact: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
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
        isLoading = true
        isAnalyzing = true
        defer {
            isLoading = false
            isAnalyzing = false
        }

        do {
            // Fetch 90 days of transactions
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .day, value: -90, to: endDate)!

            let transactions = try await transactionService.fetchTransactions(from: startDate, to: endDate)

            // Run detection
            buckets = await detector.detect(from: transactions)
        } catch {
            self.error = error
        }
    }

    public func refresh() async {
        await analyze()
    }
}
