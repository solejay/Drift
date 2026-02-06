import SwiftUI
import UI
import Core

/// Section displaying top spending items (transactions for day, merchants for week/month)
public struct TopItemsSection: View {
    let period: SpendingPeriod
    let items: [TopSpendingItem]
    let maxItems: Int
    @State private var selectedItem: TopSpendingItem?

    public init(period: SpendingPeriod, items: [TopSpendingItem], maxItems: Int = 5) {
        self.period = period
        self.items = items
        self.maxItems = maxItems
    }

    private var sectionTitle: String {
        switch period {
        case .day: return "Transactions"
        case .week, .month: return "Top Merchants"
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            SectionHeader(sectionTitle)

            ForEach(Array(items.prefix(maxItems))) { item in
                Button {
                    HapticManager.selection()
                    selectedItem = item
                } label: {
                    TopSpendingItemRow(item: item)
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(item: $selectedItem) { item in
            TransactionDetailSheet(item: item)
                .presentationDetents([.medium, .large])
        }
    }
}

// MARK: - Top Spending Item Row

public struct TopSpendingItemRow: View {
    let item: TopSpendingItem

    public init(item: TopSpendingItem) {
        self.item = item
    }

    public var body: some View {
        GlassCard(padding: DesignTokens.Spacing.sm) {
            HStack(spacing: DesignTokens.Spacing.md) {
                CategoryIconFromString(category: item.category, size: .small)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.subheadline)
                        .lineLimit(1)
                        .foregroundStyle(DriftPalette.ink)

                    Text(item.subtitle)
                        .font(.caption)
                        .foregroundStyle(DriftPalette.muted)
                }

                Spacer()

                Text(formatCurrency(item.amount))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(DriftPalette.ink)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .minimumScaleFactor(0.8)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.name), \(item.subtitle), \(formatCurrency(item.amount))")
    }

    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0"
    }
}

#Preview("Transactions (Day)") {
    let transactions = [
        TopSpendingItem.transaction(TransactionDTO(
            id: UUID(),
            accountId: UUID(),
            plaidTransactionId: "1",
            amount: 35.99,
            date: Date(),
            merchantName: "Amazon",
            category: "shopping",
            isExcluded: false
        )),
        TopSpendingItem.transaction(TransactionDTO(
            id: UUID(),
            accountId: UUID(),
            plaidTransactionId: "2",
            amount: 18.99,
            date: Date(),
            merchantName: "Netflix",
            category: "entertainment",
            isExcluded: false
        )),
    ]

    return TopItemsSection(period: .day, items: transactions)
        .padding()
        .background(Color(uiColor: .systemGroupedBackground))
}

#Preview("Merchants (Week)") {
    let merchants = [
        TopSpendingItem.merchant(MerchantBreakdownDTO(
            merchantName: "Whole Foods",
            amount: 125.40,
            transactionCount: 4,
            category: "food"
        )),
        TopSpendingItem.merchant(MerchantBreakdownDTO(
            merchantName: "Uber",
            amount: 89.50,
            transactionCount: 8,
            category: "transport"
        )),
    ]

    return TopItemsSection(period: .week, items: merchants)
        .padding()
        .background(Color(uiColor: .systemGroupedBackground))
}
