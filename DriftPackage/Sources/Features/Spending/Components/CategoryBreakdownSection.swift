import SwiftUI
import UI
import Core

/// Category breakdown section with progress bars
public struct CategoryBreakdownSection: View {
    let categories: [CategoryBreakdownDTO]
    let maxItems: Int

    public init(categories: [CategoryBreakdownDTO], maxItems: Int = 5) {
        self.categories = categories
        self.maxItems = maxItems
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            SectionHeader("By Category")

            ForEach(Array(categories.prefix(maxItems))) { category in
                CategoryBreakdownRow(category: category)
            }
        }
    }
}

// MARK: - Category Breakdown Row

public struct CategoryBreakdownRow: View {
    let category: CategoryBreakdownDTO

    public init(category: CategoryBreakdownDTO) {
        self.category = category
    }

    public var body: some View {
        GlassCard(padding: DesignTokens.Spacing.sm) {
            HStack(spacing: DesignTokens.Spacing.md) {
                CategoryIconFromString(category: category.category, size: .medium)

                VStack(alignment: .leading, spacing: 4) {
                    Text(SpendingCategory(rawValue: category.category)?.displayName ?? category.category.capitalized)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(DriftPalette.ink)

                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.secondary.opacity(0.2))
                                .frame(height: 4)

                            Capsule()
                                .fill(DesignTokens.Colors.category(category.category))
                                .frame(width: max(0, min(geo.size.width, geo.size.width * category.percentageOfTotal)), height: 4)
                        }
                    }
                    .frame(height: 4)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatCurrency(category.amount))
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(DriftPalette.ink)
                        .contentTransition(.numericText())
                        .minimumScaleFactor(0.8)

                    Text("\(Int(category.percentageOfTotal * 100))%")
                        .font(.caption)
                        .foregroundStyle(DriftPalette.muted)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(SpendingCategory(rawValue: category.category)?.displayName ?? category.category.capitalized): \(formatCurrency(category.amount)), \(Int(category.percentageOfTotal * 100)) percent")
    }

    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.currencySymbol = "$"
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0"
    }
}

#Preview {
    let categories = [
        CategoryBreakdownDTO(category: "food", amount: 245.50, transactionCount: 18, percentageOfTotal: 0.32),
        CategoryBreakdownDTO(category: "transport", amount: 156.00, transactionCount: 12, percentageOfTotal: 0.20),
        CategoryBreakdownDTO(category: "shopping", amount: 189.99, transactionCount: 5, percentageOfTotal: 0.25),
        CategoryBreakdownDTO(category: "subscriptions", amount: 65.97, transactionCount: 3, percentageOfTotal: 0.09),
        CategoryBreakdownDTO(category: "entertainment", amount: 108.50, transactionCount: 6, percentageOfTotal: 0.14),
    ]

    return CategoryBreakdownSection(categories: categories)
        .padding()
        .background(Color(uiColor: .systemGroupedBackground))
}
