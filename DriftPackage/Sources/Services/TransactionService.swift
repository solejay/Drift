import Foundation
import Core

/// Service for transaction operations
@MainActor
public final class TransactionService: ObservableObject {
    public static let shared = TransactionService()

    @Published public private(set) var transactions: [TransactionDTO] = []
    @Published public private(set) var isLoading = false
    @Published public private(set) var hasMore = true

    private let api: APIClient
    private var currentPage = 1
    private let perPage = 50

    public init(api: APIClient = .shared) {
        self.api = api
    }

    // MARK: - Fetch Transactions

    /// Fetch transactions with pagination
    public func fetchTransactions(
        startDate: Date? = nil,
        endDate: Date? = nil,
        accountIds: [UUID]? = nil,
        categories: [String]? = nil,
        reset: Bool = true
    ) async throws {
        if reset {
            currentPage = 1
            transactions = []
            hasMore = true
        }

        guard hasMore else { return }

        isLoading = true
        defer { isLoading = false }

        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "page", value: String(currentPage)),
            URLQueryItem(name: "perPage", value: String(perPage))
        ]

        if let startDate {
            queryItems.append(URLQueryItem(name: "startDate", value: ISO8601DateFormatter().string(from: startDate)))
        }

        if let endDate {
            queryItems.append(URLQueryItem(name: "endDate", value: ISO8601DateFormatter().string(from: endDate)))
        }

        if let accountIds {
            queryItems.append(URLQueryItem(name: "accountIds", value: accountIds.map(\.uuidString).joined(separator: ",")))
        }

        if let categories {
            queryItems.append(URLQueryItem(name: "categories", value: categories.joined(separator: ",")))
        }

        let response: TransactionListResponse = try await api.get("/api/v1/transactions", queryItems: queryItems)

        transactions.append(contentsOf: response.transactions)
        hasMore = response.hasMore
        currentPage += 1
    }

    /// Load more transactions (pagination)
    public func loadMore() async throws {
        try await fetchTransactions(reset: false)
    }

    // MARK: - Update Transaction

    public func updateTransaction(
        _ transactionId: UUID,
        category: String? = nil,
        isExcluded: Bool? = nil
    ) async throws {
        let request = UpdateTransactionRequest(category: category, isExcluded: isExcluded)
        let updated: TransactionDTO = try await api.put("/api/v1/transactions/\(transactionId.uuidString)", body: request)

        if let index = transactions.firstIndex(where: { $0.id == transactionId }) {
            transactions[index] = updated
        }
    }

    // MARK: - Transactions by Date

    /// Get transactions for today
    public func fetchTodayTransactions() async throws -> [TransactionDTO] {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        let response: TransactionListResponse = try await api.get("/api/v1/transactions", queryItems: [
            URLQueryItem(name: "startDate", value: ISO8601DateFormatter().string(from: today)),
            URLQueryItem(name: "endDate", value: ISO8601DateFormatter().string(from: tomorrow)),
            URLQueryItem(name: "perPage", value: "100")
        ])

        return response.transactions
    }

    /// Get transactions for a specific date range
    public func fetchTransactions(from startDate: Date, to endDate: Date) async throws -> [TransactionDTO] {
        // Return empty array when using mock data, the LeakyBucketDetector will return mock data
        if AppConfiguration.useMockData {
            return []
        }

        let response: TransactionListResponse = try await api.get("/api/v1/transactions", queryItems: [
            URLQueryItem(name: "startDate", value: ISO8601DateFormatter().string(from: startDate)),
            URLQueryItem(name: "endDate", value: ISO8601DateFormatter().string(from: endDate)),
            URLQueryItem(name: "perPage", value: "500")
        ])

        return response.transactions
    }
}

// MARK: - Summary Service

@MainActor
public final class SummaryService: ObservableObject {
    public static let shared = SummaryService()

    private let api: APIClient

    public init(api: APIClient = .shared) {
        self.api = api
    }

    // MARK: - Daily Summary

    public func fetchDailySummary(for date: Date = Date()) async throws -> DailySummaryResponse {
        if AppConfiguration.useMockData {
            return Self.mockDailySummary(for: date)
        }
        let queryItems = [
            URLQueryItem(name: "date", value: ISO8601DateFormatter().string(from: date))
        ]
        return try await api.get("/api/v1/summary/daily", queryItems: queryItems)
    }

    // MARK: - Weekly Summary

    public func fetchWeeklySummary(for date: Date = Date()) async throws -> WeeklySummaryResponse {
        if AppConfiguration.useMockData {
            return Self.mockWeeklySummary(for: date)
        }
        let queryItems = [
            URLQueryItem(name: "date", value: ISO8601DateFormatter().string(from: date))
        ]
        return try await api.get("/api/v1/summary/weekly", queryItems: queryItems)
    }

    // MARK: - Monthly Summary

    public func fetchMonthlySummary(month: Int? = nil, year: Int? = nil) async throws -> MonthlySummaryResponse {
        if AppConfiguration.useMockData {
            return Self.mockMonthlySummary(month: month, year: year)
        }
        let calendar = Calendar.current
        let now = Date()

        var queryItems: [URLQueryItem] = []

        if let month {
            queryItems.append(URLQueryItem(name: "month", value: String(month)))
        } else {
            queryItems.append(URLQueryItem(name: "month", value: String(calendar.component(.month, from: now))))
        }

        if let year {
            queryItems.append(URLQueryItem(name: "year", value: String(year)))
        } else {
            queryItems.append(URLQueryItem(name: "year", value: String(calendar.component(.year, from: now))))
        }

        return try await api.get("/api/v1/summary/monthly", queryItems: queryItems)
    }

    // MARK: - Mock Data

    private static func mockDailySummary(for date: Date) -> DailySummaryResponse {
        let categories = [
            CategoryBreakdownDTO(category: "Food", amount: 45.50, transactionCount: 3, percentageOfTotal: 35),
            CategoryBreakdownDTO(category: "Transport", amount: 28.00, transactionCount: 2, percentageOfTotal: 22),
            CategoryBreakdownDTO(category: "Shopping", amount: 35.99, transactionCount: 1, percentageOfTotal: 28),
            CategoryBreakdownDTO(category: "Entertainment", amount: 18.99, transactionCount: 1, percentageOfTotal: 15),
        ]

        let transactions = [
            TransactionDTO(id: UUID(), accountId: UUID(), plaidTransactionId: "1", amount: 35.99, date: date, merchantName: "Amazon", category: "Shopping", isExcluded: false),
            TransactionDTO(id: UUID(), accountId: UUID(), plaidTransactionId: "2", amount: 18.99, date: date, merchantName: "Netflix", category: "Entertainment", isExcluded: false),
            TransactionDTO(id: UUID(), accountId: UUID(), plaidTransactionId: "3", amount: 22.50, date: date, merchantName: "Chipotle", category: "Food", isExcluded: false),
            TransactionDTO(id: UUID(), accountId: UUID(), plaidTransactionId: "4", amount: 15.00, date: date, merchantName: "Uber", category: "Transport", isExcluded: false),
        ]

        return DailySummaryResponse(
            date: date,
            totalSpent: 128.48,
            totalIncome: 0,
            transactionCount: 7,
            categoryBreakdown: categories,
            topTransactions: transactions,
            comparisonToYesterday: 0.15
        )
    }

    private static func mockWeeklySummary(for date: Date) -> WeeklySummaryResponse {
        let calendar = Calendar.current
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))!
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!

        let categories = [
            CategoryBreakdownDTO(category: "Food", amount: 245.50, transactionCount: 18, percentageOfTotal: 32),
            CategoryBreakdownDTO(category: "Transport", amount: 156.00, transactionCount: 12, percentageOfTotal: 20),
            CategoryBreakdownDTO(category: "Shopping", amount: 189.99, transactionCount: 5, percentageOfTotal: 25),
            CategoryBreakdownDTO(category: "Subscriptions", amount: 65.97, transactionCount: 3, percentageOfTotal: 9),
            CategoryBreakdownDTO(category: "Entertainment", amount: 108.50, transactionCount: 6, percentageOfTotal: 14),
        ]

        let dailySpending = (0..<7).map { dayOffset in
            let dayDate = calendar.date(byAdding: .day, value: dayOffset, to: weekStart)!
            let amounts: [Decimal] = [85.50, 142.30, 56.20, 198.75, 112.40, 167.80, 128.48]
            return DailySpendingDTO(date: dayDate, amount: amounts[dayOffset], transactionCount: 3 + dayOffset)
        }

        let merchants = [
            MerchantBreakdownDTO(merchantName: "Whole Foods", amount: 125.40, transactionCount: 4, category: "Food"),
            MerchantBreakdownDTO(merchantName: "Uber", amount: 89.50, transactionCount: 8, category: "Transport"),
            MerchantBreakdownDTO(merchantName: "Amazon", amount: 156.99, transactionCount: 3, category: "Shopping"),
            MerchantBreakdownDTO(merchantName: "Starbucks", amount: 42.50, transactionCount: 6, category: "Food"),
        ]

        return WeeklySummaryResponse(
            weekStartDate: weekStart,
            weekEndDate: weekEnd,
            totalSpent: 765.96,
            totalIncome: 2500.00,
            transactionCount: 44,
            categoryBreakdown: categories,
            dailySpending: dailySpending,
            topMerchants: merchants,
            comparisonToLastWeek: -0.08
        )
    }

    private static func mockMonthlySummary(month: Int?, year: Int?) -> MonthlySummaryResponse {
        let calendar = Calendar.current
        let now = Date()
        let m = month ?? calendar.component(.month, from: now)
        let y = year ?? calendar.component(.year, from: now)

        let categories = [
            CategoryBreakdownDTO(category: "Food", amount: 892.50, transactionCount: 65, percentageOfTotal: 28),
            CategoryBreakdownDTO(category: "Transport", amount: 445.00, transactionCount: 38, percentageOfTotal: 14),
            CategoryBreakdownDTO(category: "Shopping", amount: 678.99, transactionCount: 12, percentageOfTotal: 21),
            CategoryBreakdownDTO(category: "Subscriptions", amount: 189.97, transactionCount: 8, percentageOfTotal: 6),
            CategoryBreakdownDTO(category: "Entertainment", amount: 356.50, transactionCount: 15, percentageOfTotal: 11),
            CategoryBreakdownDTO(category: "Utilities", amount: 385.00, transactionCount: 4, percentageOfTotal: 12),
            CategoryBreakdownDTO(category: "Health", amount: 245.00, transactionCount: 3, percentageOfTotal: 8),
        ]

        var components = DateComponents()
        components.year = y
        components.month = m
        components.day = 1
        let monthStart = calendar.date(from: components)!

        let weeklySpending = (0..<4).map { weekOffset in
            let weekStart = calendar.date(byAdding: .weekOfMonth, value: weekOffset, to: monthStart)!
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!
            let amounts: [Decimal] = [765.96, 812.45, 698.30, 916.25]
            return WeeklySpendingDTO(weekNumber: weekOffset + 1, startDate: weekStart, endDate: weekEnd, amount: amounts[weekOffset], transactionCount: 35 + weekOffset * 5)
        }

        let dailyHeatmap = (0..<28).map { dayOffset in
            let dayDate = calendar.date(byAdding: .day, value: dayOffset, to: monthStart)!
            let baseAmount: Decimal = 75.0
            let variation = Decimal(((dayOffset * 17) % 100))
            return DailySpendingDTO(date: dayDate, amount: baseAmount + variation, transactionCount: 2 + (dayOffset % 5))
        }

        let merchants = [
            MerchantBreakdownDTO(merchantName: "Whole Foods", amount: 425.40, transactionCount: 12, category: "Food"),
            MerchantBreakdownDTO(merchantName: "Uber", amount: 289.50, transactionCount: 28, category: "Transport"),
            MerchantBreakdownDTO(merchantName: "Amazon", amount: 456.99, transactionCount: 8, category: "Shopping"),
            MerchantBreakdownDTO(merchantName: "Netflix", amount: 15.99, transactionCount: 1, category: "Subscriptions"),
            MerchantBreakdownDTO(merchantName: "Spotify", amount: 10.99, transactionCount: 1, category: "Subscriptions"),
        ]

        return MonthlySummaryResponse(
            month: m,
            year: y,
            totalSpent: 3192.96,
            totalIncome: 8500.00,
            transactionCount: 145,
            categoryBreakdown: categories,
            weeklySpending: weeklySpending,
            dailyHeatmap: dailyHeatmap,
            topMerchants: merchants,
            comparisonToLastMonth: 0.12
        )
    }
}
