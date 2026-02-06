//
//  CoreTests.swift
//  DriftTests
//
//  Tests for Core models, extensions, and logic.
//

import XCTest
@testable import Drift
import Core

// MARK: - SpendingCategory Tests

final class SpendingCategoryTests: XCTestCase {

    // MARK: - displayName

    func testDisplayNameForAllCases() {
        let expected: [SpendingCategory: String] = [
            .food: "Food & Dining",
            .transport: "Transportation",
            .shopping: "Shopping",
            .entertainment: "Entertainment",
            .subscriptions: "Subscriptions",
            .utilities: "Utilities",
            .health: "Health",
            .income: "Income",
            .transfer: "Transfer",
            .other: "Other",
        ]

        for (category, name) in expected {
            XCTAssertEqual(category.displayName, name, "displayName mismatch for \(category)")
        }
    }

    // MARK: - iconName

    func testIconNameForAllCases() {
        let expected: [SpendingCategory: String] = [
            .food: "fork.knife",
            .transport: "car",
            .shopping: "bag",
            .entertainment: "tv",
            .subscriptions: "repeat",
            .utilities: "bolt",
            .health: "heart",
            .income: "arrow.down.circle",
            .transfer: "arrow.left.arrow.right",
            .other: "ellipsis.circle",
        ]

        for (category, icon) in expected {
            XCTAssertEqual(category.iconName, icon, "iconName mismatch for \(category)")
        }
    }

    // MARK: - color

    func testColorForAllCases() {
        let expected: [SpendingCategory: String] = [
            .food: "orange",
            .transport: "blue",
            .shopping: "pink",
            .entertainment: "purple",
            .subscriptions: "red",
            .utilities: "yellow",
            .health: "green",
            .income: "mint",
            .transfer: "gray",
            .other: "secondary",
        ]

        for (category, color) in expected {
            XCTAssertEqual(category.color, color, "color mismatch for \(category)")
        }
    }

    // MARK: - allCases

    func testAllCasesContainsExpectedCount() {
        XCTAssertEqual(SpendingCategory.allCases.count, 10)
    }

    func testRawValueRoundTrip() {
        for category in SpendingCategory.allCases {
            let rawValue = category.rawValue
            let restored = SpendingCategory(rawValue: rawValue)
            XCTAssertEqual(restored, category, "Round-trip failed for \(category)")
        }
    }

    // MARK: - from(plaidCategory:)

    func testFromPlaidCategoryFood() {
        XCTAssertEqual(SpendingCategory.from(plaidCategory: "Food and Drink"), .food)
        XCTAssertEqual(SpendingCategory.from(plaidCategory: "Restaurant"), .food)
        XCTAssertEqual(SpendingCategory.from(plaidCategory: "Coffee Shop"), .food)
        XCTAssertEqual(SpendingCategory.from(plaidCategory: "Fine Dining"), .food)
    }

    func testFromPlaidCategoryTransport() {
        XCTAssertEqual(SpendingCategory.from(plaidCategory: "Travel"), .transport)
        XCTAssertEqual(SpendingCategory.from(plaidCategory: "Transportation"), .transport)
        XCTAssertEqual(SpendingCategory.from(plaidCategory: "Uber ride"), .transport)
        XCTAssertEqual(SpendingCategory.from(plaidCategory: "Lyft ride"), .transport)
        XCTAssertEqual(SpendingCategory.from(plaidCategory: "Gas Station"), .transport)
    }

    func testFromPlaidCategoryShopping() {
        XCTAssertEqual(SpendingCategory.from(plaidCategory: "Shopping"), .shopping)
        XCTAssertEqual(SpendingCategory.from(plaidCategory: "Retail Store"), .shopping)
        XCTAssertEqual(SpendingCategory.from(plaidCategory: "Amazon Purchase"), .shopping)
        XCTAssertEqual(SpendingCategory.from(plaidCategory: "Department Store"), .shopping)
    }

    func testFromPlaidCategoryEntertainment() {
        XCTAssertEqual(SpendingCategory.from(plaidCategory: "Entertainment"), .entertainment)
        XCTAssertEqual(SpendingCategory.from(plaidCategory: "Recreation Center"), .entertainment)
        XCTAssertEqual(SpendingCategory.from(plaidCategory: "Movie Theater"), .entertainment)
        XCTAssertEqual(SpendingCategory.from(plaidCategory: "Video Game"), .entertainment)
    }

    func testFromPlaidCategorySubscriptions() {
        XCTAssertEqual(SpendingCategory.from(plaidCategory: "Subscription Service"), .subscriptions)
        XCTAssertEqual(SpendingCategory.from(plaidCategory: "Netflix"), .subscriptions)
        XCTAssertEqual(SpendingCategory.from(plaidCategory: "Spotify"), .subscriptions)
        XCTAssertEqual(SpendingCategory.from(plaidCategory: "Recurring Charge"), .subscriptions)
    }

    func testFromPlaidCategoryUtilities() {
        XCTAssertEqual(SpendingCategory.from(plaidCategory: "Utility Bill"), .utilities)
        XCTAssertEqual(SpendingCategory.from(plaidCategory: "Electric Company"), .utilities)
        XCTAssertEqual(SpendingCategory.from(plaidCategory: "Water Service"), .utilities)
        XCTAssertEqual(SpendingCategory.from(plaidCategory: "Internet Provider"), .utilities)
        XCTAssertEqual(SpendingCategory.from(plaidCategory: "Phone Bill"), .utilities)
    }

    func testFromPlaidCategoryHealth() {
        XCTAssertEqual(SpendingCategory.from(plaidCategory: "Health Insurance"), .health)
        XCTAssertEqual(SpendingCategory.from(plaidCategory: "Medical Office"), .health)
        XCTAssertEqual(SpendingCategory.from(plaidCategory: "Pharmacy"), .health)
        XCTAssertEqual(SpendingCategory.from(plaidCategory: "Doctor Visit"), .health)
    }

    func testFromPlaidCategoryIncome() {
        XCTAssertEqual(SpendingCategory.from(plaidCategory: "Income"), .income)
        XCTAssertEqual(SpendingCategory.from(plaidCategory: "Payroll"), .income)
        XCTAssertEqual(SpendingCategory.from(plaidCategory: "Direct Deposit"), .income)
    }

    func testFromPlaidCategoryTransfer() {
        XCTAssertEqual(SpendingCategory.from(plaidCategory: "Transfer"), .transfer)
        XCTAssertEqual(SpendingCategory.from(plaidCategory: "Payment"), .transfer)
    }

    func testFromPlaidCategoryOther() {
        XCTAssertEqual(SpendingCategory.from(plaidCategory: "Unknown"), .other)
        XCTAssertEqual(SpendingCategory.from(plaidCategory: "Miscellaneous"), .other)
        XCTAssertEqual(SpendingCategory.from(plaidCategory: ""), .other)
    }

    func testFromPlaidCategoryIsCaseInsensitive() {
        XCTAssertEqual(SpendingCategory.from(plaidCategory: "FOOD AND DRINK"), .food)
        XCTAssertEqual(SpendingCategory.from(plaidCategory: "UBER"), .transport)
        XCTAssertEqual(SpendingCategory.from(plaidCategory: "NETFLIX"), .subscriptions)
    }

    // MARK: - Codable

    func testCodableRoundTrip() throws {
        for category in SpendingCategory.allCases {
            let encoded = try JSONEncoder().encode(category)
            let decoded = try JSONDecoder().decode(SpendingCategory.self, from: encoded)
            XCTAssertEqual(decoded, category, "Codable round-trip failed for \(category)")
        }
    }
}

// MARK: - CategoryOption Tests

final class CategoryOptionTests: XCTestCase {

    // MARK: - allCases

    func testAllCasesCount() {
        XCTAssertEqual(CategoryOption.allCases.count, 9)
    }

    func testAllCasesContainsExpectedValues() {
        let expectedCases: [CategoryOption] = [
            .foodDelivery, .coffee, .amazon, .dining, .rideshare,
            .subscriptions, .fastFood, .alcohol, .shopping,
        ]
        XCTAssertEqual(Set(CategoryOption.allCases), Set(expectedCases))
    }

    // MARK: - title (displayName equivalent)

    func testTitleForAllCases() {
        let expected: [CategoryOption: String] = [
            .foodDelivery: "Food Delivery",
            .coffee: "Coffee",
            .amazon: "Amazon",
            .dining: "Dining",
            .rideshare: "Rideshare",
            .subscriptions: "Subscriptions",
            .fastFood: "Fast Food",
            .alcohol: "Alcohol",
            .shopping: "Shopping",
        ]

        for (option, title) in expected {
            XCTAssertEqual(option.title, title, "title mismatch for \(option)")
        }
    }

    // MARK: - icon (iconName equivalent)

    func testIconForAllCases() {
        let expected: [CategoryOption: String] = [
            .foodDelivery: "fork.knife",
            .coffee: "cup.and.saucer",
            .amazon: "cart",
            .dining: "wineglass",
            .rideshare: "car",
            .subscriptions: "play.rectangle",
            .fastFood: "takeoutbag.and.cup.and.straw",
            .alcohol: "wineglass.fill",
            .shopping: "bag",
        ]

        for (option, icon) in expected {
            XCTAssertEqual(option.icon, icon, "icon mismatch for \(option)")
        }
    }

    // MARK: - exampleMerchants

    func testExampleMerchantsAreNonEmpty() {
        for option in CategoryOption.allCases {
            XCTAssertFalse(option.exampleMerchants.isEmpty, "exampleMerchants is empty for \(option)")
        }
    }

    func testExampleMerchantsForFoodDelivery() {
        let merchants = CategoryOption.foodDelivery.exampleMerchants
        XCTAssertTrue(merchants.contains("Uber Eats"))
        XCTAssertTrue(merchants.contains("DoorDash"))
        XCTAssertTrue(merchants.contains("Grubhub"))
    }

    func testExampleMerchantsForCoffee() {
        let merchants = CategoryOption.coffee.exampleMerchants
        XCTAssertTrue(merchants.contains("Starbucks"))
        XCTAssertTrue(merchants.contains("Dunkin'"))
    }

    func testExampleMerchantsForSubscriptions() {
        let merchants = CategoryOption.subscriptions.exampleMerchants
        XCTAssertTrue(merchants.contains("Netflix"))
        XCTAssertTrue(merchants.contains("Spotify"))
    }

    func testExampleMerchantsForShopping() {
        let merchants = CategoryOption.shopping.exampleMerchants
        XCTAssertTrue(merchants.contains("Target"))
        XCTAssertTrue(merchants.contains("Walmart"))
        XCTAssertTrue(merchants.contains("Best Buy"))
    }

    // MARK: - Identifiable

    func testIdMatchesRawValue() {
        for option in CategoryOption.allCases {
            XCTAssertEqual(option.id, option.rawValue)
        }
    }

    // MARK: - Codable

    func testCodableRoundTrip() throws {
        for option in CategoryOption.allCases {
            let encoded = try JSONEncoder().encode(option)
            let decoded = try JSONDecoder().decode(CategoryOption.self, from: encoded)
            XCTAssertEqual(decoded, option, "Codable round-trip failed for \(option)")
        }
    }

    // MARK: - Persistence

    func testSaveAndLoadSelectedCategories() {
        let testCategories: [CategoryOption] = [.coffee, .subscriptions, .shopping]

        // Save
        CategoryOption.saveSelected(testCategories)

        // Load
        let loaded = CategoryOption.loadSelected()
        XCTAssertEqual(loaded, testCategories)

        // Clean up
        UserDefaults.standard.removeObject(forKey: "selectedLeakyBucketCategories")
    }

    func testLoadSelectedDefaultsWhenNoneStored() {
        // Clear any stored value
        UserDefaults.standard.removeObject(forKey: "selectedLeakyBucketCategories")

        let loaded = CategoryOption.loadSelected()
        XCTAssertEqual(loaded, [.foodDelivery, .coffee])
    }
}

// MARK: - Date+Extensions Tests

final class DateExtensionsTests: XCTestCase {

    private var calendar: Calendar {
        Calendar.current
    }

    // MARK: - startOfDay / endOfDay

    func testStartOfDay() {
        let date = Date()
        let start = date.startOfDay

        let components = calendar.dateComponents([.hour, .minute, .second], from: start)
        XCTAssertEqual(components.hour, 0)
        XCTAssertEqual(components.minute, 0)
        XCTAssertEqual(components.second, 0)
    }

    func testEndOfDay() {
        let date = Date()
        let end = date.endOfDay

        let components = calendar.dateComponents([.hour, .minute, .second], from: end)
        XCTAssertEqual(components.hour, 23)
        XCTAssertEqual(components.minute, 59)
        XCTAssertEqual(components.second, 59)
    }

    func testStartOfDayAndEndOfDaySameDay() {
        let date = Date()
        let start = date.startOfDay
        let end = date.endOfDay

        XCTAssertTrue(calendar.isDate(start, inSameDayAs: end))
    }

    // MARK: - startOfWeek / endOfWeek

    func testStartOfWeekIsSunday() {
        let date = Date()
        let weekStart = date.startOfWeek

        let weekday = calendar.component(.weekday, from: weekStart)
        // Sunday = 1 in the Gregorian calendar (default for Calendar.current)
        XCTAssertEqual(weekday, 1, "startOfWeek should be Sunday")
    }

    func testEndOfWeekIsAfterStartOfWeek() {
        let date = Date()
        XCTAssertTrue(date.endOfWeek > date.startOfWeek)
    }

    func testStartOfWeekAndEndOfWeekSpanSixDays() {
        let date = Date()
        let start = date.startOfWeek
        let end = date.endOfWeek

        let daysBetween = calendar.dateComponents([.day], from: start, to: end).day!
        XCTAssertEqual(daysBetween, 6)
    }

    // MARK: - startOfMonth / endOfMonth

    func testStartOfMonthIsFirstDay() {
        let date = Date()
        let monthStart = date.startOfMonth

        let day = calendar.component(.day, from: monthStart)
        XCTAssertEqual(day, 1)
    }

    func testEndOfMonthIsLastDay() {
        // Test with a known month (January 2025 has 31 days)
        var components = DateComponents()
        components.year = 2025
        components.month = 1
        components.day = 15
        let date = calendar.date(from: components)!

        let endOfMonth = date.endOfMonth
        let day = calendar.component(.day, from: endOfMonth)
        XCTAssertEqual(day, 31)
    }

    func testEndOfMonthFebruary2024() {
        // 2024 is a leap year
        var components = DateComponents()
        components.year = 2024
        components.month = 2
        components.day = 10
        let date = calendar.date(from: components)!

        let endOfMonth = date.endOfMonth
        let day = calendar.component(.day, from: endOfMonth)
        XCTAssertEqual(day, 29)
    }

    // MARK: - isToday / isYesterday

    func testIsTodayForCurrentDate() {
        XCTAssertTrue(Date().isToday)
    }

    func testIsTodayForYesterdayReturnsFalse() {
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        XCTAssertFalse(yesterday.isToday)
    }

    func testIsYesterdayForYesterday() {
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        XCTAssertTrue(yesterday.isYesterday)
    }

    func testIsYesterdayForTodayReturnsFalse() {
        XCTAssertFalse(Date().isYesterday)
    }

    // MARK: - isThisWeek / isThisMonth

    func testIsThisWeekForToday() {
        XCTAssertTrue(Date().isThisWeek)
    }

    func testIsThisMonthForToday() {
        XCTAssertTrue(Date().isThisMonth)
    }

    func testIsThisMonthForLastYear() {
        let lastYear = calendar.date(byAdding: .year, value: -1, to: Date())!
        XCTAssertFalse(lastYear.isThisMonth)
    }

    // MARK: - daysSince

    func testDaysSincePositive() {
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: Date())!
        let days = Date().daysSince(threeDaysAgo)
        XCTAssertEqual(days, 3)
    }

    func testDaysSinceSameDay() {
        let today = Date()
        let days = today.daysSince(today)
        XCTAssertEqual(days, 0)
    }

    // MARK: - shortFormatted

    func testShortFormattedToday() {
        XCTAssertEqual(Date().shortFormatted, "Today")
    }

    func testShortFormattedYesterday() {
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        XCTAssertEqual(yesterday.shortFormatted, "Yesterday")
    }

    func testShortFormattedOldDate() {
        // A date clearly in the past (different year)
        var components = DateComponents()
        components.year = 2020
        components.month = 6
        components.day = 15
        let date = calendar.date(from: components)!

        let formatted = date.shortFormatted
        XCTAssertTrue(formatted.contains("2020"), "Old date should include year: got '\(formatted)'")
        XCTAssertTrue(formatted.contains("Jun"), "Old date should include abbreviated month: got '\(formatted)'")
    }

    // MARK: - fullFormatted

    func testFullFormattedIsNonEmpty() {
        let formatted = Date().fullFormatted
        XCTAssertFalse(formatted.isEmpty)
    }

    // MARK: - monthYearFormatted

    func testMonthYearFormatted() {
        var components = DateComponents()
        components.year = 2025
        components.month = 3
        components.day = 15
        let date = calendar.date(from: components)!

        let formatted = date.monthYearFormatted
        XCTAssertEqual(formatted, "March 2025")
    }

    // MARK: - dayOfWeekName / shortDayOfWeekName

    func testDayOfWeekNameIsNonEmpty() {
        let name = Date().dayOfWeekName
        XCTAssertFalse(name.isEmpty)
    }

    func testShortDayOfWeekNameIsThreeCharacters() {
        let name = Date().shortDayOfWeekName
        XCTAssertEqual(name.count, 3, "Short day name should be 3 characters: got '\(name)'")
    }

    // MARK: - weekRangeFormatted

    func testWeekRangeFormattedContainsDash() {
        let formatted = Date().weekRangeFormatted
        XCTAssertTrue(formatted.contains("-"), "weekRangeFormatted should contain a dash: got '\(formatted)'")
    }
}

// MARK: - Decimal+Extensions Tests

final class DecimalExtensionsTests: XCTestCase {

    // MARK: - asCurrency

    func testAsCurrencyPositive() {
        let value: Decimal = 42.50
        let formatted = value.asCurrency
        XCTAssertTrue(formatted.contains("42.50"), "Expected '42.50' in '\(formatted)'")
        XCTAssertTrue(formatted.contains("$"), "Expected '$' in '\(formatted)'")
    }

    func testAsCurrencyZero() {
        let value: Decimal = 0
        let formatted = value.asCurrency
        XCTAssertTrue(formatted.contains("0.00"), "Expected '0.00' in '\(formatted)'")
    }

    func testAsCurrencyNegative() {
        let value: Decimal = -15.99
        let formatted = value.asCurrency
        XCTAssertTrue(formatted.contains("15.99"), "Expected '15.99' in '\(formatted)'")
    }

    // MARK: - asCompactCurrency

    func testCompactCurrencySmallAmount() {
        let value: Decimal = 42.50
        let formatted = value.asCompactCurrency
        // Should use regular formatting for amounts < 1000
        XCTAssertTrue(formatted.contains("42.50"), "Expected '42.50' in '\(formatted)'")
    }

    func testCompactCurrencyThousands() {
        let value: Decimal = 1500
        let formatted = value.asCompactCurrency
        XCTAssertTrue(formatted.contains("K"), "Expected 'K' in '\(formatted)'")
        XCTAssertTrue(formatted.contains("$"), "Expected '$' in '\(formatted)'")
        XCTAssertTrue(formatted.contains("1.5"), "Expected '1.5' in '\(formatted)'")
    }

    func testCompactCurrencyMillions() {
        let value: Decimal = 2_500_000
        let formatted = value.asCompactCurrency
        XCTAssertTrue(formatted.contains("M"), "Expected 'M' in '\(formatted)'")
        XCTAssertTrue(formatted.contains("$"), "Expected '$' in '\(formatted)'")
        XCTAssertTrue(formatted.contains("2.5"), "Expected '2.5' in '\(formatted)'")
    }

    func testCompactCurrencyNegativeThousands() {
        let value: Decimal = -3200
        let formatted = value.asCompactCurrency
        XCTAssertTrue(formatted.hasPrefix("-"), "Expected leading '-' in '\(formatted)'")
        XCTAssertTrue(formatted.contains("K"), "Expected 'K' in '\(formatted)'")
    }

    // MARK: - rounded(toPlaces:)

    func testRoundedToZeroPlaces() {
        let value: Decimal = 3.567
        let rounded = value.rounded(toPlaces: 0)
        XCTAssertEqual(rounded, 4)
    }

    func testRoundedToOnePlaces() {
        let value: Decimal = 3.567
        let rounded = value.rounded(toPlaces: 1)
        XCTAssertEqual(rounded, Decimal(string: "3.6"))
    }

    func testRoundedToTwoPlaces() {
        let value: Decimal = 3.567
        let rounded = value.rounded(toPlaces: 2)
        XCTAssertEqual(rounded, Decimal(string: "3.57"))
    }

    // MARK: - absoluteValue

    func testAbsoluteValuePositive() {
        let value: Decimal = 42
        XCTAssertEqual(value.absoluteValue, 42)
    }

    func testAbsoluteValueNegative() {
        let value: Decimal = -42
        XCTAssertEqual(value.absoluteValue, 42)
    }

    func testAbsoluteValueZero() {
        let value: Decimal = 0
        XCTAssertEqual(value.absoluteValue, 0)
    }

    // MARK: - Array<Decimal> sum / average

    func testArraySum() {
        let values: [Decimal] = [10, 20, 30]
        XCTAssertEqual(values.sum, 60)
    }

    func testArraySumEmpty() {
        let values: [Decimal] = []
        XCTAssertEqual(values.sum, 0)
    }

    func testArrayAverage() {
        let values: [Decimal] = [10, 20, 30]
        XCTAssertEqual(values.average, 20)
    }

    func testArrayAverageEmpty() {
        let values: [Decimal] = []
        XCTAssertEqual(values.average, 0)
    }

    func testArrayAverageSingleElement() {
        let values: [Decimal] = [42]
        XCTAssertEqual(values.average, 42)
    }

    // MARK: - Array<Double> extensions

    func testDoubleSumBasic() {
        let values: [Double] = [1.5, 2.5, 3.0]
        XCTAssertEqual(values.doubleSum, 7.0, accuracy: 0.001)
    }

    func testDoubleAverageBasic() {
        let values: [Double] = [2.0, 4.0, 6.0]
        XCTAssertEqual(values.doubleAverage(), 4.0, accuracy: 0.001)
    }

    func testDoubleAverageEmpty() {
        let values: [Double] = []
        XCTAssertEqual(values.doubleAverage(), 0.0)
    }

    func testVarianceBasic() {
        let values: [Double] = [2.0, 4.0, 4.0, 4.0, 5.0, 5.0, 7.0, 9.0]
        let variance = values.variance()
        XCTAssertGreaterThan(variance, 0)
    }

    func testVarianceSingleElement() {
        let values: [Double] = [5.0]
        XCTAssertEqual(values.variance(), 0.0)
    }

    func testStandardDeviationNonNegative() {
        let values: [Double] = [10, 20, 30, 40, 50]
        XCTAssertGreaterThanOrEqual(values.standardDeviation(), 0)
    }

    func testCoefficientOfVariationZeroAverage() {
        let values: [Double] = [-1.0, 1.0]
        // Average is 0, so CV should return 0 to avoid division by zero
        XCTAssertEqual(values.coefficientOfVariation(), 0.0)
    }

    func testCoefficientOfVariationNormal() {
        let values: [Double] = [10.0, 10.0, 10.0]
        // All same values => stddev = 0 => CV = 0
        XCTAssertEqual(values.coefficientOfVariation(), 0.0, accuracy: 0.001)
    }

    // MARK: - Sequence average extensions

    func testSequenceAverageDecimal() {
        struct Item {
            let amount: Decimal
        }
        let items = [Item(amount: 10), Item(amount: 20), Item(amount: 30)]
        let avg = items.averageDecimal(\.amount)
        XCTAssertEqual(avg, 20)
    }

    func testSequenceAverageDecimalEmpty() {
        struct Item {
            let amount: Decimal
        }
        let items: [Item] = []
        let avg = items.averageDecimal(\.amount)
        XCTAssertEqual(avg, 0)
    }

    func testSequenceAverageFloat() {
        struct Item {
            let value: Double
        }
        let items = [Item(value: 2.0), Item(value: 4.0), Item(value: 6.0)]
        let avg: Double = items.average(\.value)
        XCTAssertEqual(avg, 4.0, accuracy: 0.001)
    }
}
