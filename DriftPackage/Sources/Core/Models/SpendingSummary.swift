import Foundation

/// A spending item within a summary, grouped by category
public struct CategorySpending: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public let category: SpendingCategory
    public let amount: Decimal
    public let transactionCount: Int
    public let percentageOfTotal: Double

    public init(
        id: UUID = UUID(),
        category: SpendingCategory,
        amount: Decimal,
        transactionCount: Int,
        percentageOfTotal: Double
    ) {
        self.id = id
        self.category = category
        self.amount = amount
        self.transactionCount = transactionCount
        self.percentageOfTotal = percentageOfTotal
    }

    public var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.currencySymbol = "$"
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0"
    }

    public var formattedPercentage: String {
        "\(Int(percentageOfTotal * 100))%"
    }
}

/// Summary period type
public enum SummaryPeriod: String, Codable, Sendable {
    case daily
    case weekly
    case monthly

    public var displayName: String {
        switch self {
        case .daily: return "Today"
        case .weekly: return "This Week"
        case .monthly: return "This Month"
        }
    }
}

/// Spending summary for a time period
public struct SpendingSummary: Identifiable, Codable, Sendable {
    public let id: UUID
    public let period: SummaryPeriod
    public let startDate: Date
    public let endDate: Date
    public let totalSpent: Decimal
    public let totalIncome: Decimal
    public let transactionCount: Int
    public let categoryBreakdown: [CategorySpending]
    public let comparisonToPreviousPeriod: Double?
    public let topMerchants: [MerchantSpending]

    public init(
        id: UUID = UUID(),
        period: SummaryPeriod,
        startDate: Date,
        endDate: Date,
        totalSpent: Decimal,
        totalIncome: Decimal = 0,
        transactionCount: Int,
        categoryBreakdown: [CategorySpending],
        comparisonToPreviousPeriod: Double? = nil,
        topMerchants: [MerchantSpending] = []
    ) {
        self.id = id
        self.period = period
        self.startDate = startDate
        self.endDate = endDate
        self.totalSpent = totalSpent
        self.totalIncome = totalIncome
        self.transactionCount = transactionCount
        self.categoryBreakdown = categoryBreakdown
        self.comparisonToPreviousPeriod = comparisonToPreviousPeriod
        self.topMerchants = topMerchants
    }

    public var formattedTotalSpent: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.currencySymbol = "$"
        return formatter.string(from: totalSpent as NSDecimalNumber) ?? "$0"
    }

    public var formattedTotalIncome: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.currencySymbol = "$"
        return formatter.string(from: totalIncome as NSDecimalNumber) ?? "$0"
    }

    public var netAmount: Decimal {
        totalIncome - totalSpent
    }

    public var formattedNetAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.currencySymbol = "$"
        return formatter.string(from: netAmount as NSDecimalNumber) ?? "$0"
    }

    public var comparisonText: String? {
        guard let comparison = comparisonToPreviousPeriod else { return nil }
        let percentage = Int(abs(comparison) * 100)
        if comparison > 0 {
            return "\(percentage)% more than last \(period.rawValue)"
        } else if comparison < 0 {
            return "\(percentage)% less than last \(period.rawValue)"
        } else {
            return "Same as last \(period.rawValue)"
        }
    }
}

/// Spending by merchant
public struct MerchantSpending: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public let merchantName: String
    public let amount: Decimal
    public let transactionCount: Int
    public let category: SpendingCategory

    public init(
        id: UUID = UUID(),
        merchantName: String,
        amount: Decimal,
        transactionCount: Int,
        category: SpendingCategory
    ) {
        self.id = id
        self.merchantName = merchantName
        self.amount = amount
        self.transactionCount = transactionCount
        self.category = category
    }

    public var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.currencySymbol = "$"
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0"
    }
}
