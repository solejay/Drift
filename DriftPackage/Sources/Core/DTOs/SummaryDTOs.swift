import Foundation

// MARK: - Summary Request

public struct SummaryRequest: Codable, Sendable {
    public let date: Date?
    public let accountIds: [UUID]?

    public init(date: Date? = nil, accountIds: [UUID]? = nil) {
        self.date = date
        self.accountIds = accountIds
    }
}

// MARK: - Summary Response

public struct DailySummaryResponse: Codable, Sendable {
    public let date: Date
    public let totalSpent: Decimal
    public let totalIncome: Decimal
    public let transactionCount: Int
    public let categoryBreakdown: [CategoryBreakdownDTO]
    public let topTransactions: [TransactionDTO]
    public let comparisonToYesterday: Double?

    public init(
        date: Date,
        totalSpent: Decimal,
        totalIncome: Decimal,
        transactionCount: Int,
        categoryBreakdown: [CategoryBreakdownDTO],
        topTransactions: [TransactionDTO],
        comparisonToYesterday: Double? = nil
    ) {
        self.date = date
        self.totalSpent = totalSpent
        self.totalIncome = totalIncome
        self.transactionCount = transactionCount
        self.categoryBreakdown = categoryBreakdown
        self.topTransactions = topTransactions
        self.comparisonToYesterday = comparisonToYesterday
    }
}

public struct WeeklySummaryResponse: Codable, Sendable {
    public let weekStartDate: Date
    public let weekEndDate: Date
    public let totalSpent: Decimal
    public let totalIncome: Decimal
    public let transactionCount: Int
    public let categoryBreakdown: [CategoryBreakdownDTO]
    public let dailySpending: [DailySpendingDTO]
    public let topMerchants: [MerchantBreakdownDTO]
    public let comparisonToLastWeek: Double?

    public init(
        weekStartDate: Date,
        weekEndDate: Date,
        totalSpent: Decimal,
        totalIncome: Decimal,
        transactionCount: Int,
        categoryBreakdown: [CategoryBreakdownDTO],
        dailySpending: [DailySpendingDTO],
        topMerchants: [MerchantBreakdownDTO],
        comparisonToLastWeek: Double? = nil
    ) {
        self.weekStartDate = weekStartDate
        self.weekEndDate = weekEndDate
        self.totalSpent = totalSpent
        self.totalIncome = totalIncome
        self.transactionCount = transactionCount
        self.categoryBreakdown = categoryBreakdown
        self.dailySpending = dailySpending
        self.topMerchants = topMerchants
        self.comparisonToLastWeek = comparisonToLastWeek
    }
}

public struct MonthlySummaryResponse: Codable, Sendable {
    public let month: Int
    public let year: Int
    public let totalSpent: Decimal
    public let totalIncome: Decimal
    public let transactionCount: Int
    public let categoryBreakdown: [CategoryBreakdownDTO]
    public let weeklySpending: [WeeklySpendingDTO]
    public let dailyHeatmap: [DailySpendingDTO]
    public let topMerchants: [MerchantBreakdownDTO]
    public let comparisonToLastMonth: Double?

    public init(
        month: Int,
        year: Int,
        totalSpent: Decimal,
        totalIncome: Decimal,
        transactionCount: Int,
        categoryBreakdown: [CategoryBreakdownDTO],
        weeklySpending: [WeeklySpendingDTO],
        dailyHeatmap: [DailySpendingDTO],
        topMerchants: [MerchantBreakdownDTO],
        comparisonToLastMonth: Double? = nil
    ) {
        self.month = month
        self.year = year
        self.totalSpent = totalSpent
        self.totalIncome = totalIncome
        self.transactionCount = transactionCount
        self.categoryBreakdown = categoryBreakdown
        self.weeklySpending = weeklySpending
        self.dailyHeatmap = dailyHeatmap
        self.topMerchants = topMerchants
        self.comparisonToLastMonth = comparisonToLastMonth
    }
}

// MARK: - Breakdown DTOs

public struct CategoryBreakdownDTO: Codable, Sendable, Identifiable, Hashable {
    public let id: UUID
    public let category: String
    public let amount: Decimal
    public let transactionCount: Int
    public let percentageOfTotal: Double

    public init(
        id: UUID = UUID(),
        category: String,
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
}

public struct DailySpendingDTO: Codable, Sendable, Identifiable, Hashable {
    public let id: UUID
    public let date: Date
    public let amount: Decimal
    public let transactionCount: Int

    public init(
        id: UUID = UUID(),
        date: Date,
        amount: Decimal,
        transactionCount: Int
    ) {
        self.id = id
        self.date = date
        self.amount = amount
        self.transactionCount = transactionCount
    }
}

public struct WeeklySpendingDTO: Codable, Sendable, Identifiable, Hashable {
    public let id: UUID
    public let weekNumber: Int
    public let startDate: Date
    public let endDate: Date
    public let amount: Decimal
    public let transactionCount: Int

    public init(
        id: UUID = UUID(),
        weekNumber: Int,
        startDate: Date,
        endDate: Date,
        amount: Decimal,
        transactionCount: Int
    ) {
        self.id = id
        self.weekNumber = weekNumber
        self.startDate = startDate
        self.endDate = endDate
        self.amount = amount
        self.transactionCount = transactionCount
    }
}

public struct MerchantBreakdownDTO: Codable, Sendable, Identifiable, Hashable {
    public let id: UUID
    public let merchantName: String
    public let amount: Decimal
    public let transactionCount: Int
    public let category: String

    public init(
        id: UUID = UUID(),
        merchantName: String,
        amount: Decimal,
        transactionCount: Int,
        category: String
    ) {
        self.id = id
        self.merchantName = merchantName
        self.amount = amount
        self.transactionCount = transactionCount
        self.category = category
    }
}

// MARK: - Leaky Bucket DTOs

public struct LeakyBucketDTO: Codable, Sendable, Identifiable, Hashable {
    public let id: UUID
    public let merchantName: String
    public let category: String
    public let frequency: String
    public let averageAmount: Decimal
    public let monthlyImpact: Decimal
    public let yearlyImpact: Decimal
    public let confidenceScore: Double
    public let occurrenceCount: Int
    public let firstOccurrence: Date?
    public let lastOccurrence: Date?

    public init(
        id: UUID = UUID(),
        merchantName: String,
        category: String,
        frequency: String,
        averageAmount: Decimal,
        monthlyImpact: Decimal,
        yearlyImpact: Decimal,
        confidenceScore: Double,
        occurrenceCount: Int,
        firstOccurrence: Date? = nil,
        lastOccurrence: Date? = nil
    ) {
        self.id = id
        self.merchantName = merchantName
        self.category = category
        self.frequency = frequency
        self.averageAmount = averageAmount
        self.monthlyImpact = monthlyImpact
        self.yearlyImpact = yearlyImpact
        self.confidenceScore = confidenceScore
        self.occurrenceCount = occurrenceCount
        self.firstOccurrence = firstOccurrence
        self.lastOccurrence = lastOccurrence
    }
}

public struct LeakyBucketsResponse: Codable, Sendable {
    public let buckets: [LeakyBucketDTO]
    public let totalMonthlyImpact: Decimal
    public let totalYearlyImpact: Decimal

    public init(
        buckets: [LeakyBucketDTO],
        totalMonthlyImpact: Decimal,
        totalYearlyImpact: Decimal
    ) {
        self.buckets = buckets
        self.totalMonthlyImpact = totalMonthlyImpact
        self.totalYearlyImpact = totalYearlyImpact
    }
}
