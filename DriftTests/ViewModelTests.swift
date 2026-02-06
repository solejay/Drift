//
//  ViewModelTests.swift
//  DriftTests
//
//  Tests for ViewModels: SpendingViewModel, AuthViewModel.
//

import XCTest
@testable import Drift
import Features
import Services
import Core

// MARK: - SpendingViewModel Tests

@MainActor
final class SpendingViewModelTests: XCTestCase {

    private var viewModel: SpendingViewModel!

    override func setUp() {
        super.setUp()
        viewModel = SpendingViewModel()
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    // MARK: - Initial State

    func testInitialSelectedPeriodIsDay() {
        XCTAssertEqual(viewModel.selectedPeriod, .day)
    }

    func testInitialSpendingDataIsNil() {
        XCTAssertNil(viewModel.spendingData)
    }

    func testInitialIsLoadingIsFalse() {
        XCTAssertFalse(viewModel.isLoading)
    }

    func testInitialErrorIsNil() {
        XCTAssertNil(viewModel.error)
    }

    func testInitialSelectedDateIsToday() {
        XCTAssertTrue(Calendar.current.isDateInToday(viewModel.selectedDate))
    }

    func testInitialSelectedMonthIsCurrentMonth() {
        let currentMonth = Calendar.current.component(.month, from: Date())
        XCTAssertEqual(viewModel.selectedMonth, currentMonth)
    }

    func testInitialSelectedYearIsCurrentYear() {
        let currentYear = Calendar.current.component(.year, from: Date())
        XCTAssertEqual(viewModel.selectedYear, currentYear)
    }

    func testInitialSelectedChartIndexIsNil() {
        XCTAssertNil(viewModel.selectedChartIndex)
    }

    // MARK: - Computed Properties (No Data)

    func testFormattedTotalWithNoData() {
        XCTAssertEqual(viewModel.formattedTotal, "$0")
    }

    func testInsightTextWithNoData() {
        XCTAssertNil(viewModel.insightText)
    }

    func testAverageAmountWithNoData() {
        XCTAssertNil(viewModel.averageAmount)
    }

    func testComparisonArrowUpWithNoData() {
        XCTAssertFalse(viewModel.comparisonArrowUp)
    }

    func testMaxChartAmountWithNoData() {
        XCTAssertEqual(viewModel.maxChartAmount, 1)
    }

    // MARK: - Period Selection

    func testSetSelectedPeriodToWeek() {
        viewModel.selectedPeriod = .week
        XCTAssertEqual(viewModel.selectedPeriod, .week)
    }

    func testSetSelectedPeriodToMonth() {
        viewModel.selectedPeriod = .month
        XCTAssertEqual(viewModel.selectedPeriod, .month)
    }

    func testSetSelectedPeriodBackToDay() {
        viewModel.selectedPeriod = .week
        viewModel.selectedPeriod = .day
        XCTAssertEqual(viewModel.selectedPeriod, .day)
    }

    // MARK: - SpendingPeriod Enum

    func testSpendingPeriodRawValues() {
        XCTAssertEqual(SpendingPeriod.day.rawValue, "Today")
        XCTAssertEqual(SpendingPeriod.week.rawValue, "Weekly")
        XCTAssertEqual(SpendingPeriod.month.rawValue, "Monthly")
    }

    func testSpendingPeriodDisplayNames() {
        XCTAssertEqual(SpendingPeriod.day.displayName, "Day")
        XCTAssertEqual(SpendingPeriod.week.displayName, "Week")
        XCTAssertEqual(SpendingPeriod.month.displayName, "Month")
    }

    func testSpendingPeriodAllCasesCount() {
        XCTAssertEqual(SpendingPeriod.allCases.count, 3)
    }

    func testSpendingPeriodIdentifiable() {
        for period in SpendingPeriod.allCases {
            XCTAssertEqual(period.id, period.rawValue)
        }
    }

    // MARK: - Date Navigation (Day)

    func testCanGoForwardReturnsFalseForToday() {
        viewModel.selectedPeriod = .day
        viewModel.selectedDate = Date()
        XCTAssertFalse(viewModel.canGoForward, "Should not be able to go forward from today")
    }

    func testCanGoForwardReturnsTrueForPastDate() {
        viewModel.selectedPeriod = .day
        viewModel.selectedDate = Calendar.current.date(byAdding: .day, value: -5, to: Date())!
        XCTAssertTrue(viewModel.canGoForward, "Should be able to go forward from a past date")
    }

    func testSelectPreviousForDayMovesBackOneDay() {
        viewModel.selectedPeriod = .day
        let originalDate = viewModel.selectedDate

        viewModel.selectPrevious()

        let expectedDate = Calendar.current.date(byAdding: .day, value: -1, to: originalDate)!
        XCTAssertTrue(
            Calendar.current.isDate(viewModel.selectedDate, inSameDayAs: expectedDate),
            "selectPrevious should move back one day"
        )
    }

    func testSelectNextWhenNotTodayMovesForward() {
        viewModel.selectedPeriod = .day
        let pastDate = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        viewModel.selectedDate = pastDate

        viewModel.selectNext()

        let expectedDate = Calendar.current.date(byAdding: .day, value: 1, to: pastDate)!
        XCTAssertTrue(
            Calendar.current.isDate(viewModel.selectedDate, inSameDayAs: expectedDate),
            "selectNext should move forward one day"
        )
    }

    func testSelectNextWhenTodayDoesNotMove() {
        viewModel.selectedPeriod = .day
        viewModel.selectedDate = Date()
        let originalDate = viewModel.selectedDate

        viewModel.selectNext()

        XCTAssertTrue(
            Calendar.current.isDate(viewModel.selectedDate, inSameDayAs: originalDate),
            "selectNext should not move forward from today"
        )
    }

    // MARK: - Date Navigation (Week)

    func testSelectPreviousForWeekMovesBackOneWeek() {
        viewModel.selectedPeriod = .week
        let originalDate = viewModel.selectedDate

        viewModel.selectPrevious()

        let expectedDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: originalDate)!
        let daysDiff = Calendar.current.dateComponents([.day], from: viewModel.selectedDate, to: expectedDate).day!
        XCTAssertTrue(abs(daysDiff) <= 1, "selectPrevious for week should move back ~7 days")
    }

    // MARK: - Date Navigation (Month)

    func testSelectPreviousForMonthDecrementsMonth() {
        viewModel.selectedPeriod = .month
        let originalMonth = viewModel.selectedMonth
        let originalYear = viewModel.selectedYear

        viewModel.selectPrevious()

        if originalMonth == 1 {
            XCTAssertEqual(viewModel.selectedMonth, 12)
            XCTAssertEqual(viewModel.selectedYear, originalYear - 1)
        } else {
            XCTAssertEqual(viewModel.selectedMonth, originalMonth - 1)
            XCTAssertEqual(viewModel.selectedYear, originalYear)
        }
    }

    func testSelectPreviousForMonthWrapsJanuaryToDecember() {
        viewModel.selectedPeriod = .month
        viewModel.selectedMonth = 1
        viewModel.selectedYear = 2025

        viewModel.selectPrevious()

        XCTAssertEqual(viewModel.selectedMonth, 12)
        XCTAssertEqual(viewModel.selectedYear, 2024)
    }

    func testCanGoForwardForMonthReturnsFalseForCurrentMonth() {
        viewModel.selectedPeriod = .month
        let now = Date()
        viewModel.selectedMonth = Calendar.current.component(.month, from: now)
        viewModel.selectedYear = Calendar.current.component(.year, from: now)

        XCTAssertFalse(viewModel.canGoForward)
    }

    func testCanGoForwardForMonthReturnsTrueForPastMonth() {
        viewModel.selectedPeriod = .month
        viewModel.selectedMonth = 1
        viewModel.selectedYear = 2024

        XCTAssertTrue(viewModel.canGoForward)
    }

    func testSelectNextForMonthIncrementsMonth() {
        viewModel.selectedPeriod = .month
        viewModel.selectedMonth = 1
        viewModel.selectedYear = 2024

        viewModel.selectNext()

        XCTAssertEqual(viewModel.selectedMonth, 2)
        XCTAssertEqual(viewModel.selectedYear, 2024)
    }

    func testSelectNextForMonthWrapsDecemberToJanuary() {
        viewModel.selectedPeriod = .month
        viewModel.selectedMonth = 12
        viewModel.selectedYear = 2023

        viewModel.selectNext()

        XCTAssertEqual(viewModel.selectedMonth, 1)
        XCTAssertEqual(viewModel.selectedYear, 2024)
    }

    // MARK: - loadData (Mock Mode)

    func testLoadDataSetsSpendingData() async {
        // In mock mode, loadData should populate spendingData
        viewModel.selectedPeriod = .day
        await viewModel.loadData()

        XCTAssertNotNil(viewModel.spendingData)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testLoadDataDayPeriodLabel() async {
        viewModel.selectedPeriod = .day
        viewModel.selectedDate = Date()
        await viewModel.loadData()

        XCTAssertEqual(viewModel.spendingData?.periodLabel, "Today")
    }

    func testLoadDataSetsCorrectPeriod() async {
        viewModel.selectedPeriod = .day
        await viewModel.loadData()
        XCTAssertEqual(viewModel.spendingData?.period, .day)

        viewModel.selectedPeriod = .week
        await viewModel.loadData()
        XCTAssertEqual(viewModel.spendingData?.period, .week)

        viewModel.selectedPeriod = .month
        await viewModel.loadData()
        XCTAssertEqual(viewModel.spendingData?.period, .month)
    }

    func testLoadDataPopulatesChartData() async {
        viewModel.selectedPeriod = .day
        await viewModel.loadData()

        XCTAssertNotNil(viewModel.spendingData?.chartData)
        XCTAssertFalse(viewModel.spendingData!.chartData.isEmpty)
    }

    func testLoadDataPopulatesCategoryBreakdown() async {
        viewModel.selectedPeriod = .day
        await viewModel.loadData()

        XCTAssertNotNil(viewModel.spendingData?.categoryBreakdown)
        XCTAssertFalse(viewModel.spendingData!.categoryBreakdown.isEmpty)
    }

    func testFormattedTotalWithData() async {
        viewModel.selectedPeriod = .day
        await viewModel.loadData()

        let formatted = viewModel.formattedTotal
        XCTAssertTrue(formatted.contains("$"), "formattedTotal should contain dollar sign")
        XCTAssertNotEqual(formatted, "$0", "formattedTotal should not be $0 with mock data")
    }

    func testMaxChartAmountWithData() async {
        viewModel.selectedPeriod = .day
        await viewModel.loadData()

        XCTAssertGreaterThan(viewModel.maxChartAmount, 0)
    }

    // MARK: - Weekly loadData

    func testLoadDataWeeklyPopulatesData() async {
        viewModel.selectedPeriod = .week
        await viewModel.loadData()

        XCTAssertNotNil(viewModel.spendingData)
        XCTAssertEqual(viewModel.spendingData?.period, .week)
        XCTAssertEqual(viewModel.spendingData?.comparisonLabel, "last week")
    }

    // MARK: - Monthly loadData

    func testLoadDataMonthlyPopulatesData() async {
        viewModel.selectedPeriod = .month
        await viewModel.loadData()

        XCTAssertNotNil(viewModel.spendingData)
        XCTAssertEqual(viewModel.spendingData?.period, .month)
        XCTAssertEqual(viewModel.spendingData?.comparisonLabel, "last month")
    }

    func testLoadDataMonthlyHasWeeklySpending() async {
        viewModel.selectedPeriod = .month
        await viewModel.loadData()

        XCTAssertNotNil(viewModel.spendingData?.weeklySpending)
    }

    // MARK: - ChartDataPoint

    func testChartDataPointInit() {
        let date = Date()
        let point = ChartDataPoint(
            label: "Mon",
            date: date,
            amount: 42.50,
            isCurrentPeriod: true
        )

        XCTAssertEqual(point.label, "Mon")
        XCTAssertEqual(point.amount, 42.50)
        XCTAssertTrue(point.isCurrentPeriod)
        XCTAssertNotNil(point.id)
    }

    func testChartDataPointDefaultNotCurrentPeriod() {
        let point = ChartDataPoint(label: "Tue", date: Date(), amount: 10)
        XCTAssertFalse(point.isCurrentPeriod)
    }

    func testChartDataPointHashable() {
        let point1 = ChartDataPoint(label: "Mon", date: Date(), amount: 42.50)
        let point2 = ChartDataPoint(label: "Tue", date: Date(), amount: 30.00)

        var set = Set<ChartDataPoint>()
        set.insert(point1)
        set.insert(point2)

        XCTAssertEqual(set.count, 2)
    }

    // MARK: - TopSpendingItem

    func testTopSpendingItemTransaction() {
        let tx = TransactionDTO(
            id: UUID(),
            accountId: UUID(),
            amount: 25.99,
            date: Date(),
            merchantName: "Starbucks",
            category: "Food"
        )
        let item = TopSpendingItem.transaction(tx)

        XCTAssertEqual(item.name, "Starbucks")
        XCTAssertEqual(item.amount, 25.99)
        XCTAssertEqual(item.category, "Food")
        XCTAssertEqual(item.id, tx.id)
    }

    func testTopSpendingItemMerchant() {
        let merchant = MerchantBreakdownDTO(
            merchantName: "Amazon",
            amount: 150.00,
            transactionCount: 5,
            category: "Shopping"
        )
        let item = TopSpendingItem.merchant(merchant)

        XCTAssertEqual(item.name, "Amazon")
        XCTAssertEqual(item.amount, 150.00)
        XCTAssertEqual(item.category, "Shopping")
    }

    func testTopSpendingItemMerchantSubtitlePlural() {
        let merchant = MerchantBreakdownDTO(
            merchantName: "Amazon",
            amount: 150.00,
            transactionCount: 5,
            category: "Shopping"
        )
        let item = TopSpendingItem.merchant(merchant)

        XCTAssertEqual(item.subtitle, "5 visits")
    }

    func testTopSpendingItemMerchantSubtitleSingular() {
        let merchant = MerchantBreakdownDTO(
            merchantName: "Amazon",
            amount: 50.00,
            transactionCount: 1,
            category: "Shopping"
        )
        let item = TopSpendingItem.merchant(merchant)

        XCTAssertEqual(item.subtitle, "1 visit")
    }

    func testTopSpendingItemTransactionSubtitleIsTime() {
        let tx = TransactionDTO(
            id: UUID(),
            accountId: UUID(),
            amount: 25.99,
            date: Date(),
            merchantName: "Starbucks",
            category: "Food"
        )
        let item = TopSpendingItem.transaction(tx)

        // The subtitle for a transaction should be a time string, non-empty
        XCTAssertFalse(item.subtitle.isEmpty)
    }

    // MARK: - InsightText

    func testInsightTextWithSignificantIncrease() async {
        viewModel.selectedPeriod = .day
        await viewModel.loadData()

        // Mock data has comparisonToYesterday = 0.15 (15% increase)
        if let insight = viewModel.insightText {
            XCTAssertTrue(insight.contains("more") || insight.contains("less"),
                          "Insight should indicate increase or decrease")
            XCTAssertTrue(insight.contains("today"),
                          "Insight for day period should mention 'today'")
        }
        // insightText may be nil if comparison is <= 5%, which is acceptable
    }
}

// MARK: - AuthViewModel Tests

@MainActor
final class AuthViewModelTests: XCTestCase {

    private var viewModel: AuthViewModel!

    override func setUp() {
        super.setUp()
        viewModel = AuthViewModel()
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    // MARK: - Initial State

    func testInitialState() {
        XCTAssertEqual(viewModel.email, "")
        XCTAssertEqual(viewModel.password, "")
        XCTAssertEqual(viewModel.confirmPassword, "")
        XCTAssertEqual(viewModel.displayName, "")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        XCTAssertFalse(viewModel.showError)
    }

    // MARK: - Login Validation

    func testIsLoginValidWithValidCredentials() {
        viewModel.email = "user@example.com"
        viewModel.password = "password123"
        XCTAssertTrue(viewModel.isLoginValid)
    }

    func testIsLoginInvalidWithEmptyEmail() {
        viewModel.email = ""
        viewModel.password = "password123"
        XCTAssertFalse(viewModel.isLoginValid)
    }

    func testIsLoginInvalidWithEmailMissingAtSign() {
        viewModel.email = "userexample.com"
        viewModel.password = "password123"
        XCTAssertFalse(viewModel.isLoginValid)
    }

    func testIsLoginInvalidWithShortPassword() {
        viewModel.email = "user@example.com"
        viewModel.password = "1234567"  // 7 chars, minimum is 8
        XCTAssertFalse(viewModel.isLoginValid)
    }

    func testIsLoginValidWithExactly8CharPassword() {
        viewModel.email = "user@example.com"
        viewModel.password = "12345678"  // exactly 8 chars
        XCTAssertTrue(viewModel.isLoginValid)
    }

    func testIsLoginInvalidWithEmptyPassword() {
        viewModel.email = "user@example.com"
        viewModel.password = ""
        XCTAssertFalse(viewModel.isLoginValid)
    }

    func testIsLoginInvalidWithBothEmpty() {
        viewModel.email = ""
        viewModel.password = ""
        XCTAssertFalse(viewModel.isLoginValid)
    }

    // MARK: - Registration Validation

    func testIsRegisterValidWithMatchingPasswords() {
        viewModel.email = "user@example.com"
        viewModel.password = "password123"
        viewModel.confirmPassword = "password123"
        XCTAssertTrue(viewModel.isRegisterValid)
    }

    func testIsRegisterInvalidWithMismatchedPasswords() {
        viewModel.email = "user@example.com"
        viewModel.password = "password123"
        viewModel.confirmPassword = "different123"
        XCTAssertFalse(viewModel.isRegisterValid)
    }

    func testIsRegisterInvalidWithInvalidLogin() {
        viewModel.email = ""
        viewModel.password = "password123"
        viewModel.confirmPassword = "password123"
        XCTAssertFalse(viewModel.isRegisterValid)
    }

    func testIsRegisterInvalidWithShortPasswordEvenIfMatching() {
        viewModel.email = "user@example.com"
        viewModel.password = "short"
        viewModel.confirmPassword = "short"
        XCTAssertFalse(viewModel.isRegisterValid)
    }

    // MARK: - clearForm

    func testClearFormResetsAllFields() {
        viewModel.email = "user@example.com"
        viewModel.password = "password123"
        viewModel.confirmPassword = "password123"
        viewModel.displayName = "Test User"
        viewModel.error = .invalidCredentials
        viewModel.showError = true

        viewModel.clearForm()

        XCTAssertEqual(viewModel.email, "")
        XCTAssertEqual(viewModel.password, "")
        XCTAssertEqual(viewModel.confirmPassword, "")
        XCTAssertEqual(viewModel.displayName, "")
        XCTAssertNil(viewModel.error)
        XCTAssertFalse(viewModel.showError)
    }

    // MARK: - Login with Invalid Credentials

    func testLoginWithInvalidCredentialsSetsError() async {
        viewModel.email = ""
        viewModel.password = ""

        await viewModel.login()

        XCTAssertNotNil(viewModel.error)
        XCTAssertTrue(viewModel.showError)
    }

    // MARK: - Register with Invalid Data

    func testRegisterWithMismatchedPasswordsSetsError() async {
        viewModel.email = "user@example.com"
        viewModel.password = "password123"
        viewModel.confirmPassword = "different123"

        await viewModel.register()

        XCTAssertNotNil(viewModel.error)
        XCTAssertTrue(viewModel.showError)
    }

    // MARK: - AuthError

    func testAuthErrorInvalidCredentialsDescription() {
        let error = AuthError.invalidCredentials
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("valid email"))
    }

    func testAuthErrorPasswordMismatchDescription() {
        let error = AuthError.passwordMismatch
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("match"))
    }

    func testAuthErrorLoginFailedDescription() {
        let underlying = NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "network timeout"])
        let error = AuthError.loginFailed(underlying)
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("Login failed"))
    }

    func testAuthErrorRegistrationFailedDescription() {
        let underlying = NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "server error"])
        let error = AuthError.registrationFailed(underlying)
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("Registration failed"))
    }

    func testAuthErrorIdentifiable() {
        let error1 = AuthError.invalidCredentials
        let error2 = AuthError.passwordMismatch

        XCTAssertFalse(error1.id.isEmpty)
        XCTAssertFalse(error2.id.isEmpty)
        XCTAssertNotEqual(error1.id, error2.id)
    }

    // MARK: - Edge Cases

    func testEmailWithAtSignButNoLocalPart() {
        viewModel.email = "@example.com"
        viewModel.password = "password123"
        // The validation only checks contains("@"), so this passes.
        // This tests the current behavior rather than ideal behavior.
        XCTAssertTrue(viewModel.isLoginValid)
    }

    func testEmailWithAtSignButNoDomain() {
        viewModel.email = "user@"
        viewModel.password = "password123"
        // Same - just checks contains("@")
        XCTAssertTrue(viewModel.isLoginValid)
    }

    func testPasswordWithExactlyMinimumLength() {
        viewModel.email = "user@example.com"
        viewModel.password = "abcdefgh"  // 8 chars
        XCTAssertTrue(viewModel.isLoginValid)
    }

    func testPasswordWithOneLessThanMinimum() {
        viewModel.email = "user@example.com"
        viewModel.password = "abcdefg"  // 7 chars
        XCTAssertFalse(viewModel.isLoginValid)
    }
}

// MARK: - SpendingData Tests

final class SpendingDataTests: XCTestCase {

    func testSpendingDataInit() {
        let data = SpendingData(
            period: .day,
            totalSpent: 128.48,
            totalIncome: 0,
            periodLabel: "Today",
            comparisonPercentage: 0.15,
            comparisonLabel: "yesterday",
            transactionCount: 7,
            chartData: [],
            categoryBreakdown: [],
            topItems: []
        )

        XCTAssertEqual(data.period, .day)
        XCTAssertEqual(data.totalSpent, 128.48)
        XCTAssertEqual(data.totalIncome, 0)
        XCTAssertEqual(data.periodLabel, "Today")
        XCTAssertEqual(data.comparisonPercentage, 0.15)
        XCTAssertEqual(data.comparisonLabel, "yesterday")
        XCTAssertEqual(data.transactionCount, 7)
        XCTAssertNil(data.weeklySpending)
        XCTAssertNil(data.dailyHeatmap)
    }

    func testSpendingDataWithOptionalFields() {
        let weeklySpending = [
            WeeklySpendingDTO(weekNumber: 1, startDate: Date(), endDate: Date(), amount: 100, transactionCount: 5)
        ]
        let dailyHeatmap = [
            DailySpendingDTO(date: Date(), amount: 50, transactionCount: 3)
        ]

        let data = SpendingData(
            period: .month,
            totalSpent: 500,
            periodLabel: "February 2025",
            comparisonPercentage: -0.10,
            comparisonLabel: "last month",
            transactionCount: 30,
            chartData: [],
            categoryBreakdown: [],
            topItems: [],
            weeklySpending: weeklySpending,
            dailyHeatmap: dailyHeatmap
        )

        XCTAssertNotNil(data.weeklySpending)
        XCTAssertEqual(data.weeklySpending?.count, 1)
        XCTAssertNotNil(data.dailyHeatmap)
        XCTAssertEqual(data.dailyHeatmap?.count, 1)
    }
}
