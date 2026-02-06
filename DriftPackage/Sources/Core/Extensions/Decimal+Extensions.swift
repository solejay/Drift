import Foundation

public extension Decimal {
    /// Format as currency with USD symbol
    var asCurrency: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.currencySymbol = "$"
        return formatter.string(from: self as NSDecimalNumber) ?? "$0.00"
    }

    /// Format as compact currency (e.g., $1.2K, $5.3M)
    var asCompactCurrency: String {
        let absValue = abs(self)
        let sign = self < 0 ? "-" : ""

        if absValue >= 1_000_000 {
            let millions = (absValue / 1_000_000).rounded(toPlaces: 1)
            return "\(sign)$\(millions)M"
        } else if absValue >= 1_000 {
            let thousands = (absValue / 1_000).rounded(toPlaces: 1)
            return "\(sign)$\(thousands)K"
        } else {
            return asCurrency
        }
    }

    /// Round to specified decimal places
    func rounded(toPlaces places: Int) -> Decimal {
        var result = self
        var rounded = Decimal()
        NSDecimalRound(&rounded, &result, places, .plain)
        return rounded
    }

    /// Absolute value
    var absoluteValue: Decimal {
        self < 0 ? -self : self
    }
}

public extension Array where Element == Decimal {
    /// Sum of all elements
    var sum: Decimal {
        reduce(0, +)
    }

    /// Average of all elements
    var average: Decimal {
        guard !isEmpty else { return 0 }
        return sum / Decimal(count)
    }
}

public extension Array where Element == Double {
    /// Sum of all elements
    var doubleSum: Double {
        reduce(0, +)
    }

    /// Average of all elements
    func doubleAverage() -> Double {
        guard !isEmpty else { return 0 }
        return doubleSum / Double(count)
    }

    /// Variance of all elements
    func variance() -> Double {
        guard count > 1 else { return 0 }
        let avg = doubleAverage()
        let sumOfSquares = map { pow($0 - avg, 2) }.reduce(0, +)
        return sumOfSquares / Double(count - 1)
    }

    /// Standard deviation
    func standardDeviation() -> Double {
        sqrt(variance())
    }

    /// Coefficient of variation
    func coefficientOfVariation() -> Double {
        let avg = doubleAverage()
        guard avg != 0 else { return 0 }
        return standardDeviation() / avg
    }
}

public extension Sequence {
    /// Calculate average of a decimal property
    func average<T: BinaryFloatingPoint>(_ keyPath: KeyPath<Element, T>) -> T {
        var count: T = 0
        var sum: T = 0
        for element in self {
            sum += element[keyPath: keyPath]
            count += 1
        }
        return count > 0 ? sum / count : 0
    }

    /// Calculate average of a Decimal property
    func averageDecimal(_ keyPath: KeyPath<Element, Decimal>) -> Decimal {
        var count = 0
        var sum: Decimal = 0
        for element in self {
            sum += element[keyPath: keyPath]
            count += 1
        }
        return count > 0 ? sum / Decimal(count) : 0
    }
}
