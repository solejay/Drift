import SwiftUI
import UI
import Core
import Services

/// Detail view showing all transactions for a specific spending category
public struct CategoryDetailView: View {
    let category: CategoryBreakdownDTO
    let period: SpendingPeriod
    let selectedDate: Date
    let selectedMonth: Int
    let selectedYear: Int

    @State private var transactions: [TransactionDTO] = []
    @State private var isLoading = true
    @State private var error: Error?
    @Environment(\.dismiss) private var dismiss

    private let transactionService = TransactionService.shared

    public init(
        category: CategoryBreakdownDTO,
        period: SpendingPeriod,
        selectedDate: Date,
        selectedMonth: Int,
        selectedYear: Int
    ) {
        self.category = category
        self.period = period
        self.selectedDate = selectedDate
        self.selectedMonth = selectedMonth
        self.selectedYear = selectedYear
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                DriftBackground(animated: false)

                ScrollView {
                    VStack(spacing: DesignTokens.Spacing.lg) {
                        headerSection
                        summaryCard

                        if isLoading {
                            loadingSection
                        } else if let error {
                            errorSection(error)
                        } else if transactions.isEmpty {
                            emptySection
                        } else {
                            transactionListSection
                        }
                    }
                    .padding(.horizontal, DesignTokens.Spacing.md)
                    .padding(.top, DesignTokens.Spacing.lg)
                    .padding(.bottom, DesignTokens.Spacing.xl)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(DriftPalette.accent)
                }
            }
        }
        .task {
            await loadTransactions()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            CategoryIconFromString(category: category.category, size: .large)

            Text(displayName)
                .font(.system(size: 24, weight: .semibold, design: .serif))
                .foregroundStyle(DriftPalette.ink)

            Text(periodDescription)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(DriftPalette.muted)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        GlassCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Spent")
                        .font(.caption)
                        .foregroundStyle(DriftPalette.muted)

                    Text(formatCurrency(category.amount))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(DriftPalette.ink)
                        .monospacedDigit()
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(category.percentageOfTotal * 100))%")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(DesignTokens.Colors.category(category.category))

                    Text("of total")
                        .font(.caption)
                        .foregroundStyle(DriftPalette.muted)
                }
            }
        }
    }

    // MARK: - Transaction List

    private var transactionListSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            SectionHeader("\(category.transactionCount) Transaction\(category.transactionCount == 1 ? "" : "s")")

            ForEach(transactions) { transaction in
                transactionRow(transaction)
            }
        }
    }

    private func transactionRow(_ transaction: TransactionDTO) -> some View {
        GlassCard(padding: DesignTokens.Spacing.sm) {
            HStack(spacing: DesignTokens.Spacing.md) {
                MerchantLogoView(
                    logoUrl: transaction.logoUrl ?? transaction.counterpartyLogoUrl,
                    category: transaction.category,
                    size: .small
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(transaction.merchantName)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)
                        .foregroundStyle(DriftPalette.ink)

                    Text(formattedDate(transaction.date))
                        .font(.caption)
                        .foregroundStyle(DriftPalette.muted)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatCurrency(transaction.amount))
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(DriftPalette.ink)

                    if transaction.isPending {
                        Text("Pending")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(DriftPalette.sunset)
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(transaction.merchantName), \(formatCurrency(transaction.amount)), \(formattedDate(transaction.date))")
    }

    // MARK: - States

    private var loadingSection: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            ProgressView()
                .tint(DriftPalette.accent)

            Text("Loading transactions...")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundStyle(DriftPalette.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignTokens.Spacing.xl)
    }

    private func errorSection(_ error: Error) -> some View {
        GlassCard {
            VStack(spacing: DesignTokens.Spacing.md) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.title2)
                    .foregroundStyle(DriftPalette.sunsetDeep)

                Text("Couldn't load transactions")
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .foregroundStyle(DriftPalette.ink)

                Button("Try Again") {
                    Task { await loadTransactions() }
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(DriftPalette.accentDeep)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignTokens.Spacing.md)
        }
    }

    private var emptySection: some View {
        GlassCard {
            VStack(spacing: DesignTokens.Spacing.md) {
                Image(systemName: "tray")
                    .font(.title2)
                    .foregroundStyle(DriftPalette.muted.opacity(0.6))

                Text("No transactions found")
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .foregroundStyle(DriftPalette.ink)

                Text("There are no transactions in this category for the selected period.")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(DriftPalette.muted)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignTokens.Spacing.md)
        }
    }

    // MARK: - Data Loading

    private func loadTransactions() async {
        isLoading = true
        error = nil

        do {
            let (start, end) = dateRange
            transactions = try await transactionService.fetchTransactions(
                from: start,
                to: end,
                category: category.category
            )
        } catch {
            self.error = error
        }

        isLoading = false
    }

    // MARK: - Helpers

    private var dateRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        switch period {
        case .day:
            let startOfDay = calendar.startOfDay(for: selectedDate)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            return (startOfDay, endOfDay)
        case .week:
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate))!
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
            return (weekStart, weekEnd)
        case .month:
            var components = DateComponents()
            components.year = selectedYear
            components.month = selectedMonth
            components.day = 1
            let monthStart = calendar.date(from: components)!
            let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart)!
            return (monthStart, monthEnd)
        }
    }

    private var displayName: String {
        SpendingCategory(rawValue: category.category.lowercased())?.displayName ?? category.category.capitalized
    }

    private var periodDescription: String {
        switch period {
        case .day:
            if Calendar.current.isDateInToday(selectedDate) {
                return "Today"
            }
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: selectedDate)
        case .week:
            return "This Week"
        case .month:
            var components = DateComponents()
            components.month = selectedMonth
            components.year = selectedYear
            guard let date = Calendar.current.date(from: components) else { return "" }
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: date)
        }
    }

    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.currencySymbol = "$"
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0"
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    CategoryDetailView(
        category: CategoryBreakdownDTO(
            category: "food",
            amount: 245.50,
            transactionCount: 8,
            percentageOfTotal: 0.32
        ),
        period: .week,
        selectedDate: Date(),
        selectedMonth: Calendar.current.component(.month, from: Date()),
        selectedYear: Calendar.current.component(.year, from: Date())
    )
}
