import Foundation

/// Frequency pattern for recurring expenses
public enum RecurrenceFrequency: String, Codable, Sendable, CaseIterable {
    case daily
    case weekdays
    case weekly
    case biweekly
    case monthly
    case irregular

    public var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekdays: return "Weekdays"
        case .weekly: return "Weekly"
        case .biweekly: return "Every 2 weeks"
        case .monthly: return "Monthly"
        case .irregular: return "Irregular"
        }
    }

    public var approximateDaysPerMonth: Double {
        switch self {
        case .daily: return 30
        case .weekdays: return 22
        case .weekly: return 4.33
        case .biweekly: return 2.17
        case .monthly: return 1
        case .irregular: return 2 // Conservative estimate
        }
    }
}

/// A detected recurring spending pattern ("leaky bucket")
public struct LeakyBucket: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public let merchantName: String
    public let category: SpendingCategory
    public let frequency: RecurrenceFrequency
    public let averageAmount: Decimal
    public let monthlyImpact: Decimal
    public let yearlyImpact: Decimal
    public let confidenceScore: Double
    public let occurrenceCount: Int
    public let firstOccurrence: Date?
    public let lastOccurrence: Date?
    public let logoUrl: String?

    public init(
        id: UUID = UUID(),
        merchantName: String,
        category: SpendingCategory,
        frequency: RecurrenceFrequency,
        averageAmount: Decimal,
        monthlyImpact: Decimal,
        confidenceScore: Double,
        occurrenceCount: Int,
        firstOccurrence: Date? = nil,
        lastOccurrence: Date? = nil,
        logoUrl: String? = nil
    ) {
        self.id = id
        self.merchantName = merchantName
        self.category = category
        self.frequency = frequency
        self.averageAmount = averageAmount
        self.monthlyImpact = monthlyImpact
        self.yearlyImpact = monthlyImpact * 12
        self.confidenceScore = confidenceScore
        self.occurrenceCount = occurrenceCount
        self.firstOccurrence = firstOccurrence
        self.lastOccurrence = lastOccurrence
        self.logoUrl = logoUrl
    }

    /// Formatted monthly impact
    public var formattedMonthlyImpact: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.currencySymbol = "$"
        return formatter.string(from: monthlyImpact as NSDecimalNumber) ?? "$0"
    }

    /// Formatted yearly impact
    public var formattedYearlyImpact: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.currencySymbol = "$"
        return formatter.string(from: yearlyImpact as NSDecimalNumber) ?? "$0"
    }

    /// Formatted average amount
    public var formattedAverageAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.currencySymbol = "$"
        return formatter.string(from: averageAmount as NSDecimalNumber) ?? "$0"
    }

    /// Confidence as percentage string
    public var confidencePercentage: String {
        "\(Int(confidenceScore * 100))%"
    }

    /// Impact severity for UI coloring
    public var impactSeverity: ImpactSeverity {
        switch monthlyImpact {
        case ..<25: return .low
        case 25..<75: return .medium
        case 75..<150: return .high
        default: return .critical
        }
    }

    public enum ImpactSeverity: String, Sendable {
        case low
        case medium
        case high
        case critical

        public var color: String {
            switch self {
            case .low: return "green"
            case .medium: return "yellow"
            case .high: return "orange"
            case .critical: return "red"
            }
        }
    }
}
