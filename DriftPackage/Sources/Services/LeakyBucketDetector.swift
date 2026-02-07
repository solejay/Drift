import Foundation
import Core

/// Detects recurring spending patterns ("leaky buckets")
public actor LeakyBucketDetector {

    public struct Configuration: Sendable {
        public var minimumOccurrences: Int
        public var analysisWindowDays: Int
        public var maxAmountForMicroSpend: Decimal
        public var minConfidenceThreshold: Double

        public init(
            minimumOccurrences: Int = 4,
            analysisWindowDays: Int = 90,
            maxAmountForMicroSpend: Decimal = 50,
            minConfidenceThreshold: Double = 0.6
        ) {
            self.minimumOccurrences = minimumOccurrences
            self.analysisWindowDays = analysisWindowDays
            self.maxAmountForMicroSpend = maxAmountForMicroSpend
            self.minConfidenceThreshold = minConfidenceThreshold
        }

        public static let `default` = Configuration()
    }

    private let config: Configuration

    public init(config: Configuration = .default) {
        self.config = config
    }

    // MARK: - Detection

    /// Detect leaky buckets from transactions
    public func detect(from transactions: [TransactionDTO]) async -> [LeakyBucket] {
        // Return mock leaky buckets only in mock mode
        if AppConfiguration.useMockData {
            return Self.mockLeakyBuckets()
        }

        guard !transactions.isEmpty else { return [] }

        // Filter to expenses only (positive amounts in Plaid convention)
        let expenses = transactions.filter { $0.amount > 0 && !$0.isExcluded && !$0.isPending }

        // Group by normalized merchant name
        let grouped = Dictionary(grouping: expenses) { transaction in
            normalizeMerchant(transaction.merchantName)
        }

        // Filter candidates: 4+ occurrences, average ≤ threshold
        let candidates = grouped.filter { _, txns in
            txns.count >= config.minimumOccurrences &&
            averageAmount(txns) <= config.maxAmountForMicroSpend
        }

        // Analyze patterns
        var buckets: [LeakyBucket] = []
        for (merchant, transactions) in candidates {
            if let pattern = analyzePattern(merchant: merchant, transactions: transactions) {
                buckets.append(pattern)
            }
        }

        // Sort by monthly impact (highest first)
        return buckets.sorted { $0.monthlyImpact > $1.monthlyImpact }
    }

    // MARK: - Pattern Analysis

    private func analyzePattern(merchant: String, transactions: [TransactionDTO]) -> LeakyBucket? {
        let sorted = transactions.sorted { $0.date < $1.date }

        guard sorted.count >= 2 else { return nil }

        // Calculate intervals between transactions (in days)
        var intervals: [Double] = []
        for i in 1..<sorted.count {
            let days = sorted[i].date.timeIntervalSince(sorted[i-1].date) / 86400
            intervals.append(days)
        }

        let meanInterval = intervals.doubleAverage()
        let variance = intervals.variance()
        let cv = meanInterval > 0 ? sqrt(variance) / meanInterval : Double.infinity

        // Determine frequency
        let frequency = determineFrequency(meanInterval: meanInterval)

        // Calculate confidence
        let amountCV = transactions.map { Double(truncating: $0.amount as NSDecimalNumber) }.coefficientOfVariation()
        let confidence = calculateConfidence(
            occurrences: transactions.count,
            intervalCV: cv,
            amountCV: amountCV
        )

        guard confidence >= config.minConfidenceThreshold else { return nil }

        let avgAmount = averageAmount(transactions)
        let monthlyImpact = calculateMonthlyImpact(amount: avgAmount, frequency: frequency)
        let category = SpendingCategory.from(plaidCategory: transactions.first?.category ?? "")

        return LeakyBucket(
            merchantName: transactions.first?.merchantName ?? merchant,
            category: category,
            frequency: frequency,
            averageAmount: avgAmount,
            monthlyImpact: monthlyImpact,
            confidenceScore: confidence,
            occurrenceCount: transactions.count,
            firstOccurrence: sorted.first?.date,
            lastOccurrence: sorted.last?.date
        )
    }

    // MARK: - Helpers

    private func normalizeMerchant(_ name: String) -> String {
        // Remove common suffixes, numbers, locations
        var normalized = name.lowercased()

        // Remove numbers (often store numbers)
        normalized = normalized.replacingOccurrences(
            of: #"#?\d+"#,
            with: "",
            options: .regularExpression
        )

        // Remove common location patterns
        let patterns = [
            #"\s+(store|loc|location|branch)\s*#?\d*"#,
            #"\s+\d+\s*(st|nd|rd|th)?\s*(street|ave|avenue|blvd)?"#,
            #"\s*-\s*[a-z]{2,}"#  // State abbreviations
        ]

        for pattern in patterns {
            normalized = normalized.replacingOccurrences(
                of: pattern,
                with: "",
                options: .regularExpression
            )
        }

        // Trim and collapse whitespace
        normalized = normalized
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        return normalized
    }

    private func averageAmount(_ transactions: [TransactionDTO]) -> Decimal {
        guard !transactions.isEmpty else { return 0 }
        let total = transactions.map(\.amount).reduce(0, +)
        return total / Decimal(transactions.count)
    }

    private func determineFrequency(meanInterval: Double) -> RecurrenceFrequency {
        switch meanInterval {
        case 0..<2: return .daily
        case 2..<5: return .weekdays
        case 5..<10: return .weekly
        case 10..<20: return .biweekly
        case 20..<45: return .monthly
        default: return .irregular
        }
    }

    private func calculateConfidence(
        occurrences: Int,
        intervalCV: Double,
        amountCV: Double
    ) -> Double {
        // More occurrences = higher confidence
        let occurrenceScore = min(1.0, Double(occurrences) / 10.0)

        // Lower interval variation = higher confidence
        let intervalScore = max(0, 1.0 - intervalCV)

        // Lower amount variation = higher confidence
        let amountScore = max(0, 1.0 - amountCV)

        // Weighted average
        return occurrenceScore * 0.4 + intervalScore * 0.35 + amountScore * 0.25
    }

    private func calculateMonthlyImpact(amount: Decimal, frequency: RecurrenceFrequency) -> Decimal {
        return amount * Decimal(frequency.approximateDaysPerMonth)
    }

    // MARK: - Mock Data

    private static func mockLeakyBuckets() -> [LeakyBucket] {
        let now = Date()
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: now)
        let ninetyDaysAgo = Calendar.current.date(byAdding: .day, value: -90, to: now)

        return [
            LeakyBucket(
                merchantName: "Netflix",
                category: .subscriptions,
                frequency: .monthly,
                averageAmount: 15.99,
                monthlyImpact: 15.99,
                confidenceScore: 0.95,
                occurrenceCount: 3,
                firstOccurrence: ninetyDaysAgo,
                lastOccurrence: thirtyDaysAgo
            ),
            LeakyBucket(
                merchantName: "Spotify",
                category: .subscriptions,
                frequency: .monthly,
                averageAmount: 10.99,
                monthlyImpact: 10.99,
                confidenceScore: 0.95,
                occurrenceCount: 3,
                firstOccurrence: ninetyDaysAgo,
                lastOccurrence: thirtyDaysAgo
            ),
            LeakyBucket(
                merchantName: "Starbucks",
                category: .food,
                frequency: .weekdays,
                averageAmount: 6.75,
                monthlyImpact: 148.50,
                confidenceScore: 0.82,
                occurrenceCount: 45,
                firstOccurrence: ninetyDaysAgo,
                lastOccurrence: now
            ),
            LeakyBucket(
                merchantName: "DoorDash",
                category: .food,
                frequency: .weekly,
                averageAmount: 32.50,
                monthlyImpact: 140.73,
                confidenceScore: 0.78,
                occurrenceCount: 12,
                firstOccurrence: ninetyDaysAgo,
                lastOccurrence: now
            ),
            LeakyBucket(
                merchantName: "iCloud Storage",
                category: .subscriptions,
                frequency: .monthly,
                averageAmount: 2.99,
                monthlyImpact: 2.99,
                confidenceScore: 0.98,
                occurrenceCount: 3,
                firstOccurrence: ninetyDaysAgo,
                lastOccurrence: thirtyDaysAgo
            ),
            LeakyBucket(
                merchantName: "ChatGPT Plus",
                category: .subscriptions,
                frequency: .monthly,
                averageAmount: 20.00,
                monthlyImpact: 20.00,
                confidenceScore: 0.95,
                occurrenceCount: 3,
                firstOccurrence: ninetyDaysAgo,
                lastOccurrence: thirtyDaysAgo
            ),
            LeakyBucket(
                merchantName: "Uber",
                category: .transport,
                frequency: .weekly,
                averageAmount: 18.50,
                monthlyImpact: 80.10,
                confidenceScore: 0.72,
                occurrenceCount: 15,
                firstOccurrence: ninetyDaysAgo,
                lastOccurrence: now
            ),
            LeakyBucket(
                merchantName: "Amazon Prime",
                category: .subscriptions,
                frequency: .monthly,
                averageAmount: 14.99,
                monthlyImpact: 14.99,
                confidenceScore: 0.95,
                occurrenceCount: 3,
                firstOccurrence: ninetyDaysAgo,
                lastOccurrence: thirtyDaysAgo
            ),
        ].sorted { $0.monthlyImpact > $1.monthlyImpact }
    }
}

// MARK: - Array Extension

private extension Array where Element == Double {
    func doubleAverage() -> Double {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Double(count)
    }

    func variance() -> Double {
        guard count > 1 else { return 0 }
        let avg = doubleAverage()
        let sumOfSquares = map { pow($0 - avg, 2) }.reduce(0, +)
        return sumOfSquares / Double(count - 1)
    }

    func coefficientOfVariation() -> Double {
        let avg = doubleAverage()
        guard avg != 0 else { return 0 }
        return sqrt(variance()) / avg
    }
}
