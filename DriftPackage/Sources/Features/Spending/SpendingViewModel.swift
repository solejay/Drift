import Foundation
import SwiftUI
import Core
import Services

// MARK: - Spending Period

/// The time period for spending analysis
public enum SpendingPeriod: String, CaseIterable, Identifiable {
    case day = "Today"
    case week = "Weekly"
    case month = "Monthly"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .day: return "Day"
        case .week: return "Week"
        case .month: return "Month"
        }
    }
}

// MARK: - Chart Data Point

/// A single data point for the spending chart
public struct ChartDataPoint: Identifiable, Hashable {
    public let id: UUID
    public let label: String
    public let date: Date
    public let amount: Decimal
    public let isCurrentPeriod: Bool

    public init(
        id: UUID = UUID(),
        label: String,
        date: Date,
        amount: Decimal,
        isCurrentPeriod: Bool = false
    ) {
        self.id = id
        self.label = label
        self.date = date
        self.amount = amount
        self.isCurrentPeriod = isCurrentPeriod
    }
}

// MARK: - Top Spending Item

/// Represents either a transaction (for day view) or merchant (for week/month view)
public enum TopSpendingItem: Identifiable, Hashable {
    case transaction(TransactionDTO)
    case merchant(MerchantBreakdownDTO)

    public var id: UUID {
        switch self {
        case .transaction(let t): return t.id
        case .merchant(let m): return m.id
        }
    }

    public var name: String {
        switch self {
        case .transaction(let t): return t.merchantName
        case .merchant(let m): return m.merchantName
        }
    }

    public var amount: Decimal {
        switch self {
        case .transaction(let t): return t.amount
        case .merchant(let m): return m.amount
        }
    }

    public var category: String {
        switch self {
        case .transaction(let t): return t.category
        case .merchant(let m): return m.category
        }
    }

    public var subtitle: String {
        switch self {
        case .transaction(let t):
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: t.date)
        case .merchant(let m):
            return "\(m.transactionCount) visit\(m.transactionCount == 1 ? "" : "s")"
        }
    }
}

// MARK: - Spending Data

/// Unified data model for all spending periods
public struct SpendingData {
    public let period: SpendingPeriod
    public let totalSpent: Decimal
    public let totalIncome: Decimal
    public let periodLabel: String
    public let comparisonPercentage: Double?
    public let comparisonLabel: String
    public let transactionCount: Int
    public let chartData: [ChartDataPoint]
    public let categoryBreakdown: [CategoryBreakdownDTO]
    public let topItems: [TopSpendingItem]

    // For month view additional data
    public let weeklySpending: [WeeklySpendingDTO]?
    public let dailyHeatmap: [DailySpendingDTO]?

    public init(
        period: SpendingPeriod,
        totalSpent: Decimal,
        totalIncome: Decimal = 0,
        periodLabel: String,
        comparisonPercentage: Double?,
        comparisonLabel: String,
        transactionCount: Int,
        chartData: [ChartDataPoint],
        categoryBreakdown: [CategoryBreakdownDTO],
        topItems: [TopSpendingItem],
        weeklySpending: [WeeklySpendingDTO]? = nil,
        dailyHeatmap: [DailySpendingDTO]? = nil
    ) {
        self.period = period
        self.totalSpent = totalSpent
        self.totalIncome = totalIncome
        self.periodLabel = periodLabel
        self.comparisonPercentage = comparisonPercentage
        self.comparisonLabel = comparisonLabel
        self.transactionCount = transactionCount
        self.chartData = chartData
        self.categoryBreakdown = categoryBreakdown
        self.topItems = topItems
        self.weeklySpending = weeklySpending
        self.dailyHeatmap = dailyHeatmap
    }
}

// MARK: - Spending ViewModel

@MainActor
public final class SpendingViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published public var selectedPeriod: SpendingPeriod = .day {
        didSet {
            if oldValue != selectedPeriod {
                Task { await loadData() }
            }
        }
    }

    @Published public private(set) var spendingData: SpendingData?
    @Published public private(set) var isLoading = false
    @Published public var error: Error?

    // Date navigation
    @Published public var selectedDate: Date = Date()
    @Published public var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    @Published public var selectedYear: Int = Calendar.current.component(.year, from: Date())

    // Chart interaction
    @Published public var selectedChartIndex: Int?

    // MARK: - Private Properties

    private let summaryService: SummaryService
    private let calendar = Calendar.current

    // MARK: - Initialization

    public init(summaryService: SummaryService = .shared) {
        self.summaryService = summaryService
    }

    // MARK: - Computed Properties

    public var formattedTotal: String {
        guard let data = spendingData else { return "$0" }
        return formatCurrency(data.totalSpent)
    }

    public var insightText: String? {
        guard let data = spendingData, let comparison = data.comparisonPercentage else { return nil }

        let percentage = Int(abs(comparison) * 100)
        guard percentage > 5 else { return nil } // Only show insight if significant

        let periodText: String
        switch selectedPeriod {
        case .day: periodText = "today"
        case .week: periodText = "this week"
        case .month: periodText = "this month"
        }

        if comparison > 0 {
            return "You're spending \(percentage)% more than you usually do \(periodText)"
        } else {
            return "You're spending \(percentage)% less than you usually do \(periodText)"
        }
    }

    public var averageAmount: Decimal? {
        guard let data = spendingData, let comparison = data.comparisonPercentage else { return nil }
        // Calculate what the average would be based on comparison percentage
        // If current is X% more than average, then average = current / (1 + X)
        let current = data.totalSpent
        let multiplier = Decimal(1 + comparison)
        guard multiplier != 0 else { return nil }
        return current / multiplier
    }

    public var comparisonArrowUp: Bool {
        guard let comparison = spendingData?.comparisonPercentage else { return false }
        return comparison > 0
    }

    public var canGoForward: Bool {
        switch selectedPeriod {
        case .day:
            return !calendar.isDateInToday(selectedDate)
        case .week:
            let currentWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
            let selectedWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate))!
            return selectedWeekStart < currentWeekStart
        case .month:
            let now = Date()
            let currentMonth = calendar.component(.month, from: now)
            let currentYear = calendar.component(.year, from: now)
            return selectedYear < currentYear || (selectedYear == currentYear && selectedMonth < currentMonth)
        }
    }

    public var maxChartAmount: Decimal {
        guard let data = spendingData else { return 1 }
        return data.chartData.map(\.amount).max() ?? 1
    }

    // MARK: - Actions

    public func loadData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            switch selectedPeriod {
            case .day:
                let response = try await summaryService.fetchDailySummary(for: selectedDate)
                spendingData = transformDailyResponse(response)
            case .week:
                let response = try await summaryService.fetchWeeklySummary(for: selectedDate)
                spendingData = transformWeeklyResponse(response)
            case .month:
                let response = try await summaryService.fetchMonthlySummary(month: selectedMonth, year: selectedYear)
                spendingData = transformMonthlyResponse(response)
            }
            error = nil
        } catch {
            self.error = error
        }
    }

    public func selectPrevious() {
        switch selectedPeriod {
        case .day:
            if let newDate = calendar.date(byAdding: .day, value: -1, to: selectedDate) {
                selectedDate = newDate
            }
        case .week:
            if let newDate = calendar.date(byAdding: .weekOfYear, value: -1, to: selectedDate) {
                selectedDate = newDate
            }
        case .month:
            if selectedMonth == 1 {
                selectedMonth = 12
                selectedYear -= 1
            } else {
                selectedMonth -= 1
            }
        }
        Task { await loadData() }
    }

    public func selectNext() {
        guard canGoForward else { return }

        switch selectedPeriod {
        case .day:
            if let newDate = calendar.date(byAdding: .day, value: 1, to: selectedDate) {
                selectedDate = newDate
            }
        case .week:
            if let newDate = calendar.date(byAdding: .weekOfYear, value: 1, to: selectedDate) {
                selectedDate = newDate
            }
        case .month:
            if selectedMonth == 12 {
                selectedMonth = 1
                selectedYear += 1
            } else {
                selectedMonth += 1
            }
        }
        Task { await loadData() }
    }

    // MARK: - Data Transformation

    private func transformDailyResponse(_ response: DailySummaryResponse) -> SpendingData {
        // Create hourly chart data points (simplified - showing cumulative spending)
        // For a real implementation, you'd need hourly transaction data
        let chartData = createDayChartData(transactions: response.topTransactions, date: response.date)

        let periodLabel = formatDayLabel(response.date)
        let topItems = response.topTransactions.map { TopSpendingItem.transaction($0) }

        return SpendingData(
            period: .day,
            totalSpent: response.totalSpent,
            totalIncome: response.totalIncome,
            periodLabel: periodLabel,
            comparisonPercentage: response.comparisonToYesterday,
            comparisonLabel: "yesterday",
            transactionCount: response.transactionCount,
            chartData: chartData,
            categoryBreakdown: response.categoryBreakdown,
            topItems: topItems
        )
    }

    private func transformWeeklyResponse(_ response: WeeklySummaryResponse) -> SpendingData {
        let chartData = response.dailySpending.enumerated().map { index, day in
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"
            let isToday = calendar.isDateInToday(day.date)
            return ChartDataPoint(
                label: formatter.string(from: day.date),
                date: day.date,
                amount: day.amount,
                isCurrentPeriod: isToday
            )
        }

        let periodLabel = formatWeekLabel(start: response.weekStartDate, end: response.weekEndDate)
        let topItems = response.topMerchants.map { TopSpendingItem.merchant($0) }

        return SpendingData(
            period: .week,
            totalSpent: response.totalSpent,
            totalIncome: response.totalIncome,
            periodLabel: periodLabel,
            comparisonPercentage: response.comparisonToLastWeek,
            comparisonLabel: "last week",
            transactionCount: response.transactionCount,
            chartData: chartData,
            categoryBreakdown: response.categoryBreakdown,
            topItems: topItems
        )
    }

    private func transformMonthlyResponse(_ response: MonthlySummaryResponse) -> SpendingData {
        // Create weekly chart data for month view
        let chartData = response.weeklySpending.map { week in
            ChartDataPoint(
                label: "W\(week.weekNumber)",
                date: week.startDate,
                amount: week.amount,
                isCurrentPeriod: isCurrentWeek(week.startDate)
            )
        }

        let periodLabel = formatMonthLabel(month: response.month, year: response.year)
        let topItems = response.topMerchants.map { TopSpendingItem.merchant($0) }

        return SpendingData(
            period: .month,
            totalSpent: response.totalSpent,
            totalIncome: response.totalIncome,
            periodLabel: periodLabel,
            comparisonPercentage: response.comparisonToLastMonth,
            comparisonLabel: "last month",
            transactionCount: response.transactionCount,
            chartData: chartData,
            categoryBreakdown: response.categoryBreakdown,
            topItems: topItems,
            weeklySpending: response.weeklySpending,
            dailyHeatmap: response.dailyHeatmap
        )
    }

    // MARK: - Helper Methods

    private func createDayChartData(transactions: [TransactionDTO], date: Date) -> [ChartDataPoint] {
        // Create hourly data points showing cumulative spending
        // Since we don't have real hourly data, we'll create sample points
        var points: [ChartDataPoint] = []
        let hourFormatter = DateFormatter()
        hourFormatter.dateFormat = "ha"

        // Create data points at key times (simplified)
        let hours = [0, 6, 9, 12, 15, 18, 21, 23]
        var cumulative: Decimal = 0
        let total = transactions.reduce(Decimal.zero) { $0 + $1.amount }
        let perHourAverage = total / Decimal(hours.count)

        let now = Date()
        let isToday = calendar.isDateInToday(date)
        let currentHour = calendar.component(.hour, from: now)

        for (index, hour) in hours.enumerated() {
            var components = calendar.dateComponents([.year, .month, .day], from: date)
            components.hour = hour
            let pointDate = calendar.date(from: components) ?? date

            // Simulate cumulative spending
            cumulative += perHourAverage * Decimal(Double.random(in: 0.5...1.5))
            if index == hours.count - 1 {
                cumulative = total // Ensure last point matches total
            }

            let isCurrent = isToday && hour <= currentHour && (index == hours.count - 1 || hours[index + 1] > currentHour)

            points.append(ChartDataPoint(
                label: hourFormatter.string(from: pointDate),
                date: pointDate,
                amount: cumulative,
                isCurrentPeriod: isCurrent
            ))
        }

        return points
    }

    private func formatDayLabel(_ date: Date) -> String {
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: date)
        }
    }

    private func formatWeekLabel(start: Date, end: Date) -> String {
        let formatter = DateFormatter()

        // Check if same month
        let startMonth = calendar.component(.month, from: start)
        let endMonth = calendar.component(.month, from: end)

        if startMonth == endMonth {
            formatter.dateFormat = "MMM d"
            let startStr = formatter.string(from: start)
            formatter.dateFormat = "d"
            let endStr = formatter.string(from: end)
            return "\(startStr)-\(endStr)"
        } else {
            formatter.dateFormat = "MMM d"
            return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
        }
    }

    private func formatMonthLabel(month: Int, year: Int) -> String {
        var components = DateComponents()
        components.month = month
        components.year = year
        guard let date = calendar.date(from: components) else { return "" }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    private func isCurrentWeek(_ date: Date) -> Bool {
        let now = Date()
        let currentWeek = calendar.component(.weekOfYear, from: now)
        let currentYear = calendar.component(.yearForWeekOfYear, from: now)
        let dateWeek = calendar.component(.weekOfYear, from: date)
        let dateYear = calendar.component(.yearForWeekOfYear, from: date)
        return currentWeek == dateWeek && currentYear == dateYear
    }

    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.currencySymbol = "$"
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0"
    }
}
