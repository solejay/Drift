import Vapor
import Fluent

struct SummaryController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let summary = routes.grouped("summary")
        summary.get("daily", use: daily)
        summary.get("weekly", use: weekly)
        summary.get("monthly", use: monthly)
    }

    // MARK: - Daily Summary

    struct DailySummaryResponse: Content {
        let date: Date
        let totalSpent: Decimal
        let totalIncome: Decimal
        let transactionCount: Int
        let categoryBreakdown: [CategoryBreakdownDTO]
        let topTransactions: [TransactionDTO]
        let comparisonToYesterday: Double?
    }

    struct CategoryBreakdownDTO: Content {
        let id: UUID
        let category: String
        let amount: Decimal
        let transactionCount: Int
        let percentageOfTotal: Double
    }

    func daily(req: Request) async throws -> DailySummaryResponse {
        let userId = try req.userId
        let date = (try? req.query.get(Date.self, at: "date")) ?? Date()

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        // Get transactions for the day (capped at 1,000 to prevent memory exhaustion)
        let transactions = try await Transaction.query(on: req.db)
            .filter(\.$user.$id == userId)
            .filter(\.$date >= startOfDay)
            .filter(\.$date < endOfDay)
            .filter(\.$isExcluded == false)
            .limit(1_000)
            .all()

        // Calculate totals
        let expenses = transactions.filter { $0.amount > 0 }
        let income = transactions.filter { $0.amount < 0 }

        let totalSpent = expenses.map(\.amount).reduce(0, +)
        let totalIncome = income.map(\.amount).reduce(0, +).magnitude

        // Category breakdown
        let grouped = Dictionary(grouping: expenses, by: \.category)
        let categoryBreakdown = grouped.map { category, txns -> CategoryBreakdownDTO in
            let amount = txns.map(\.amount).reduce(0, +)
            return CategoryBreakdownDTO(
                id: UUID(),
                category: category,
                amount: amount,
                transactionCount: txns.count,
                percentageOfTotal: totalSpent > 0 ? Double(truncating: amount as NSDecimalNumber) / Double(truncating: totalSpent as NSDecimalNumber) : 0
            )
        }.sorted { $0.amount > $1.amount }

        // Top transactions
        let topTransactions = expenses
            .sorted { $0.amount > $1.amount }
            .prefix(5)
            .map { $0.toDTO() }

        // Comparison to yesterday
        let yesterdayStart = calendar.date(byAdding: .day, value: -1, to: startOfDay)!
        let yesterdaySpent = try await Transaction.query(on: req.db)
            .filter(\.$user.$id == userId)
            .filter(\.$date >= yesterdayStart)
            .filter(\.$date < startOfDay)
            .filter(\.$amount > 0)
            .filter(\.$isExcluded == false)
            .all()
            .map(\.amount)
            .reduce(0, +)

        var comparison: Double? = nil
        if yesterdaySpent > 0 {
            comparison = (Double(truncating: totalSpent as NSDecimalNumber) - Double(truncating: yesterdaySpent as NSDecimalNumber)) / Double(truncating: yesterdaySpent as NSDecimalNumber)
        }

        return DailySummaryResponse(
            date: startOfDay,
            totalSpent: totalSpent,
            totalIncome: totalIncome,
            transactionCount: transactions.count,
            categoryBreakdown: categoryBreakdown,
            topTransactions: Array(topTransactions),
            comparisonToYesterday: comparison
        )
    }

    // MARK: - Weekly Summary

    struct WeeklySummaryResponse: Content {
        let weekStartDate: Date
        let weekEndDate: Date
        let totalSpent: Decimal
        let totalIncome: Decimal
        let transactionCount: Int
        let categoryBreakdown: [CategoryBreakdownDTO]
        let dailySpending: [DailySpendingDTO]
        let topMerchants: [MerchantBreakdownDTO]
        let comparisonToLastWeek: Double?
    }

    struct DailySpendingDTO: Content {
        let id: UUID
        let date: Date
        let amount: Decimal
        let transactionCount: Int
    }

    struct MerchantBreakdownDTO: Content {
        let id: UUID
        let merchantName: String
        let amount: Decimal
        let transactionCount: Int
        let category: String
    }

    func weekly(req: Request) async throws -> WeeklySummaryResponse {
        let userId = try req.userId
        let date = (try? req.query.get(Date.self, at: "date")) ?? Date()

        let calendar = Calendar.current
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))!
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!

        // Get transactions for the week (capped at 5,000 to prevent memory exhaustion)
        let transactions = try await Transaction.query(on: req.db)
            .filter(\.$user.$id == userId)
            .filter(\.$date >= weekStart)
            .filter(\.$date < weekEnd)
            .filter(\.$isExcluded == false)
            .limit(5_000)
            .all()

        let expenses = transactions.filter { $0.amount > 0 }
        let income = transactions.filter { $0.amount < 0 }

        let totalSpent = expenses.map(\.amount).reduce(0, +)
        let totalIncome = income.map(\.amount).reduce(0, +).magnitude

        // Category breakdown
        let grouped = Dictionary(grouping: expenses, by: \.category)
        let categoryBreakdown = grouped.map { category, txns -> CategoryBreakdownDTO in
            let amount = txns.map(\.amount).reduce(0, +)
            return CategoryBreakdownDTO(
                id: UUID(),
                category: category,
                amount: amount,
                transactionCount: txns.count,
                percentageOfTotal: totalSpent > 0 ? Double(truncating: amount as NSDecimalNumber) / Double(truncating: totalSpent as NSDecimalNumber) : 0
            )
        }.sorted { $0.amount > $1.amount }

        // Daily spending
        var dailySpending: [DailySpendingDTO] = []
        for dayOffset in 0..<7 {
            let dayStart = calendar.date(byAdding: .day, value: dayOffset, to: weekStart)!
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            let dayExpenses = expenses.filter { $0.date >= dayStart && $0.date < dayEnd }

            dailySpending.append(DailySpendingDTO(
                id: UUID(),
                date: dayStart,
                amount: dayExpenses.map(\.amount).reduce(0, +),
                transactionCount: dayExpenses.count
            ))
        }

        // Top merchants
        let merchantGrouped = Dictionary(grouping: expenses, by: \.merchantName)
        let topMerchants = merchantGrouped.map { merchant, txns -> MerchantBreakdownDTO in
            MerchantBreakdownDTO(
                id: UUID(),
                merchantName: merchant,
                amount: txns.map(\.amount).reduce(0, +),
                transactionCount: txns.count,
                category: txns.first?.category ?? "other"
            )
        }
        .sorted { $0.amount > $1.amount }
        .prefix(5)

        // Comparison to last week
        let lastWeekStart = calendar.date(byAdding: .day, value: -7, to: weekStart)!
        let lastWeekSpent = try await Transaction.query(on: req.db)
            .filter(\.$user.$id == userId)
            .filter(\.$date >= lastWeekStart)
            .filter(\.$date < weekStart)
            .filter(\.$amount > 0)
            .filter(\.$isExcluded == false)
            .all()
            .map(\.amount)
            .reduce(0, +)

        var comparison: Double? = nil
        if lastWeekSpent > 0 {
            comparison = (Double(truncating: totalSpent as NSDecimalNumber) - Double(truncating: lastWeekSpent as NSDecimalNumber)) / Double(truncating: lastWeekSpent as NSDecimalNumber)
        }

        return WeeklySummaryResponse(
            weekStartDate: weekStart,
            weekEndDate: calendar.date(byAdding: .day, value: -1, to: weekEnd)!,
            totalSpent: totalSpent,
            totalIncome: totalIncome,
            transactionCount: transactions.count,
            categoryBreakdown: categoryBreakdown,
            dailySpending: dailySpending,
            topMerchants: Array(topMerchants),
            comparisonToLastWeek: comparison
        )
    }

    // MARK: - Monthly Summary

    struct MonthlySummaryResponse: Content {
        let month: Int
        let year: Int
        let totalSpent: Decimal
        let totalIncome: Decimal
        let transactionCount: Int
        let categoryBreakdown: [CategoryBreakdownDTO]
        let weeklySpending: [WeeklySpendingDTO]
        let dailyHeatmap: [DailySpendingDTO]
        let topMerchants: [MerchantBreakdownDTO]
        let comparisonToLastMonth: Double?
    }

    struct WeeklySpendingDTO: Content {
        let id: UUID
        let weekNumber: Int
        let startDate: Date
        let endDate: Date
        let amount: Decimal
        let transactionCount: Int
    }

    func monthly(req: Request) async throws -> MonthlySummaryResponse {
        let userId = try req.userId
        let calendar = Calendar.current
        let now = Date()

        let month = (try? req.query.get(Int.self, at: "month")) ?? calendar.component(.month, from: now)
        let year = (try? req.query.get(Int.self, at: "year")) ?? calendar.component(.year, from: now)

        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        let monthStart = calendar.date(from: components)!
        let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart)!

        // Get transactions for the month (capped at 10,000 to prevent memory exhaustion)
        let transactions = try await Transaction.query(on: req.db)
            .filter(\.$user.$id == userId)
            .filter(\.$date >= monthStart)
            .filter(\.$date < monthEnd)
            .filter(\.$isExcluded == false)
            .limit(10_000)
            .all()

        let expenses = transactions.filter { $0.amount > 0 }
        let income = transactions.filter { $0.amount < 0 }

        let totalSpent = expenses.map(\.amount).reduce(0, +)
        let totalIncome = income.map(\.amount).reduce(0, +).magnitude

        // Category breakdown
        let grouped = Dictionary(grouping: expenses, by: \.category)
        let categoryBreakdown = grouped.map { category, txns -> CategoryBreakdownDTO in
            let amount = txns.map(\.amount).reduce(0, +)
            return CategoryBreakdownDTO(
                id: UUID(),
                category: category,
                amount: amount,
                transactionCount: txns.count,
                percentageOfTotal: totalSpent > 0 ? Double(truncating: amount as NSDecimalNumber) / Double(truncating: totalSpent as NSDecimalNumber) : 0
            )
        }.sorted { $0.amount > $1.amount }

        // Daily heatmap
        var dailyHeatmap: [DailySpendingDTO] = []
        let daysInMonth = calendar.range(of: .day, in: .month, for: monthStart)?.count ?? 30
        for dayOffset in 0..<daysInMonth {
            let dayStart = calendar.date(byAdding: .day, value: dayOffset, to: monthStart)!
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            let dayExpenses = expenses.filter { $0.date >= dayStart && $0.date < dayEnd }

            dailyHeatmap.append(DailySpendingDTO(
                id: UUID(),
                date: dayStart,
                amount: dayExpenses.map(\.amount).reduce(0, +),
                transactionCount: dayExpenses.count
            ))
        }

        // Weekly spending
        var weeklySpending: [WeeklySpendingDTO] = []
        var weekNum = 1
        var weekStart = monthStart
        while weekStart < monthEnd {
            var weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
            if weekEnd > monthEnd { weekEnd = monthEnd }

            let weekExpenses = expenses.filter { $0.date >= weekStart && $0.date < weekEnd }
            weeklySpending.append(WeeklySpendingDTO(
                id: UUID(),
                weekNumber: weekNum,
                startDate: weekStart,
                endDate: calendar.date(byAdding: .day, value: -1, to: weekEnd)!,
                amount: weekExpenses.map(\.amount).reduce(0, +),
                transactionCount: weekExpenses.count
            ))

            weekStart = weekEnd
            weekNum += 1
        }

        // Top merchants
        let merchantGrouped = Dictionary(grouping: expenses, by: \.merchantName)
        let topMerchants = merchantGrouped.map { merchant, txns -> MerchantBreakdownDTO in
            MerchantBreakdownDTO(
                id: UUID(),
                merchantName: merchant,
                amount: txns.map(\.amount).reduce(0, +),
                transactionCount: txns.count,
                category: txns.first?.category ?? "other"
            )
        }
        .sorted { $0.amount > $1.amount }
        .prefix(10)

        // Comparison to last month
        let lastMonthStart = calendar.date(byAdding: .month, value: -1, to: monthStart)!
        let lastMonthSpent = try await Transaction.query(on: req.db)
            .filter(\.$user.$id == userId)
            .filter(\.$date >= lastMonthStart)
            .filter(\.$date < monthStart)
            .filter(\.$amount > 0)
            .filter(\.$isExcluded == false)
            .all()
            .map(\.amount)
            .reduce(0, +)

        var comparison: Double? = nil
        if lastMonthSpent > 0 {
            comparison = (Double(truncating: totalSpent as NSDecimalNumber) - Double(truncating: lastMonthSpent as NSDecimalNumber)) / Double(truncating: lastMonthSpent as NSDecimalNumber)
        }

        return MonthlySummaryResponse(
            month: month,
            year: year,
            totalSpent: totalSpent,
            totalIncome: totalIncome,
            transactionCount: transactions.count,
            categoryBreakdown: categoryBreakdown,
            weeklySpending: weeklySpending,
            dailyHeatmap: dailyHeatmap,
            topMerchants: Array(topMerchants),
            comparisonToLastMonth: comparison
        )
    }
}
