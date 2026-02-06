import SwiftUI

/// Styled text for displaying monetary amounts
public struct AmountText: View {
    private let amount: Decimal
    private let style: Style
    private let showSign: Bool
    private let compact: Bool

    public enum Style {
        case primary
        case secondary
        case hero
        case income
        case expense

        var font: Font {
            switch self {
            case .primary: return .title3.weight(.semibold)
            case .secondary: return .subheadline
            case .hero: return .system(size: 48, weight: .bold, design: .rounded)
            case .income, .expense: return .title3.weight(.semibold)
            }
        }

        func color(for amount: Decimal) -> Color {
            switch self {
            case .primary: return .primary
            case .secondary: return .secondary
            case .hero: return .primary
            case .income: return DesignTokens.Colors.income
            case .expense: return DesignTokens.Colors.expense
            }
        }
    }

    public init(
        amount: Decimal,
        style: Style = .primary,
        showSign: Bool = false,
        compact: Bool = false
    ) {
        self.amount = amount
        self.style = style
        self.showSign = showSign
        self.compact = compact
    }

    public var body: some View {
        Text(formattedAmount)
            .font(style.font)
            .foregroundStyle(style.color(for: amount))
            .monospacedDigit()
    }

    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.currencySymbol = "$"

        if compact {
            return compactFormat
        }

        var result = formatter.string(from: amount as NSDecimalNumber) ?? "$0.00"

        if showSign && amount > 0 {
            result = "+\(result)"
        }

        return result
    }

    private var compactFormat: String {
        let absValue = abs(amount)
        let sign = showSign && amount > 0 ? "+" : (amount < 0 ? "-" : "")

        if absValue >= 1_000_000 {
            let millions = (absValue / 1_000_000)
            return "\(sign)$\(formatDecimal(millions))M"
        } else if absValue >= 1_000 {
            let thousands = (absValue / 1_000)
            return "\(sign)$\(formatDecimal(thousands))K"
        } else {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = "USD"
            formatter.currencySymbol = "$"
            let base = formatter.string(from: absValue as NSDecimalNumber) ?? "$0"
            return amount < 0 ? "-\(base)" : (showSign && amount > 0 ? "+\(base)" : base)
        }
    }

    private func formatDecimal(_ value: Decimal) -> String {
        let doubleValue = NSDecimalNumber(decimal: value).doubleValue
        if doubleValue == floor(doubleValue) {
            return String(format: "%.0f", doubleValue)
        } else {
            return String(format: "%.1f", doubleValue)
        }
    }
}

/// Simple amount label with title
public struct AmountLabel: View {
    private let title: String
    private let amount: Decimal
    private let style: AmountText.Style

    public init(title: String, amount: Decimal, style: AmountText.Style = .primary) {
        self.title = title
        self.amount = amount
        self.style = style
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            AmountText(amount: amount, style: style)
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        AmountText(amount: 1234.56, style: .hero)
        AmountText(amount: 89.99, style: .primary)
        AmountText(amount: 12.50, style: .secondary)
        AmountText(amount: 500, style: .income, showSign: true)
        AmountText(amount: -250, style: .expense, showSign: true)

        Divider()

        AmountText(amount: 1500000, style: .primary, compact: true)
        AmountText(amount: 75000, style: .primary, compact: true)

        Divider()

        AmountLabel(title: "Total Spent", amount: 1234.56)
        AmountLabel(title: "Income", amount: 5000, style: .income)
    }
    .padding()
}
