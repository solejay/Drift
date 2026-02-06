import SwiftUI
import Core
import UI
import Services

/// Detail sheet shown when tapping a transaction in TopItemsSection
public struct TransactionDetailSheet: View {
    let item: TopSpendingItem
    @State private var isExcluded: Bool
    @State private var selectedCategory: String
    @State private var isSaving = false
    @Environment(\.dismiss) private var dismiss

    private let transactionService = TransactionService.shared

    public init(item: TopSpendingItem) {
        self.item = item
        switch item {
        case .transaction(let t):
            _isExcluded = State(initialValue: t.isExcluded)
            _selectedCategory = State(initialValue: t.category)
        case .merchant(let m):
            _isExcluded = State(initialValue: false)
            _selectedCategory = State(initialValue: m.category)
        }
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                DriftBackground(animated: false)

                ScrollView {
                    VStack(spacing: DesignTokens.Spacing.lg) {
                        headerSection
                        amountSection
                        detailsCard
                        actionsCard
                    }
                    .padding(.horizontal, DesignTokens.Spacing.md)
                    .padding(.top, DesignTokens.Spacing.lg)
                }
            }
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(DriftPalette.accent)
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            CategoryIconFromString(category: item.category, size: .large)

            Text(item.name)
                .font(.system(size: 24, weight: .semibold, design: .serif))
                .foregroundStyle(DriftPalette.ink)

            if case .transaction(let t) = item, t.isPending {
                Text("PENDING")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, DesignTokens.Spacing.sm)
                    .padding(.vertical, DesignTokens.Spacing.xxs)
                    .background {
                        Capsule().fill(DriftPalette.sunset)
                    }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Amount

    private var amountSection: some View {
        Text(formattedAmount)
            .font(.system(size: 48, weight: .bold, design: .rounded))
            .foregroundStyle(DriftPalette.ink)
            .monospacedDigit()
    }

    // MARK: - Details Card

    private var detailsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                Text("Details")
                    .sectionHeaderStyle()

                if case .transaction(let t) = item {
                    detailRow(label: "Date", value: formattedDate(t.date))
                    detailRow(label: "Time", value: formattedTime(t.date))
                }

                if case .merchant(let m) = item {
                    detailRow(label: "Visits", value: "\(m.transactionCount)")
                }

                HStack {
                    Text("Category")
                        .font(.subheadline)
                        .foregroundStyle(DriftPalette.muted)
                    Spacer()
                    categoryPill
                }
            }
        }
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(DriftPalette.muted)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(DriftPalette.ink)
        }
    }

    private var categoryPill: some View {
        Text(displayCategory)
            .font(.caption.weight(.medium))
            .foregroundStyle(DesignTokens.Colors.category(selectedCategory))
            .padding(.horizontal, DesignTokens.Spacing.sm)
            .padding(.vertical, DesignTokens.Spacing.xxs)
            .background {
                Capsule().fill(DesignTokens.Colors.category(selectedCategory).opacity(0.15))
            }
    }

    // MARK: - Actions Card

    private var actionsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                Text("Actions")
                    .sectionHeaderStyle()

                if case .transaction = item {
                    Toggle(isOn: $isExcluded) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Exclude from summaries")
                                .font(.subheadline)
                                .foregroundStyle(DriftPalette.ink)
                            Text("This transaction won't count in your totals")
                                .font(.caption)
                                .foregroundStyle(DriftPalette.muted)
                        }
                    }
                    .tint(DriftPalette.accent)
                    .onChange(of: isExcluded) { _, newValue in
                        saveExclusion(newValue)
                    }
                }

                if case .transaction = item {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text("Change category")
                            .font(.subheadline)
                            .foregroundStyle(DriftPalette.ink)

                        categoryPicker
                    }
                }
            }
        }
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.Spacing.xs) {
                ForEach(SpendingCategory.allCases, id: \.self) { category in
                    Button {
                        HapticManager.selection()
                        selectedCategory = category.rawValue
                        saveCategory(category.rawValue)
                    } label: {
                        Text(category.displayName)
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, DesignTokens.Spacing.sm)
                            .padding(.vertical, DesignTokens.Spacing.xs)
                            .foregroundStyle(selectedCategory == category.rawValue ? DriftPalette.chipText : DriftPalette.ink)
                            .background {
                                Capsule().fill(selectedCategory == category.rawValue ? DriftPalette.accentDeep : DriftPalette.chip)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Helpers

    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.currencySymbol = "$"
        return formatter.string(from: item.amount as NSDecimalNumber) ?? "$0"
    }

    private var displayCategory: String {
        SpendingCategory(rawValue: selectedCategory.lowercased())?.displayName ?? selectedCategory.capitalized
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func saveExclusion(_ excluded: Bool) {
        guard case .transaction(let t) = item else { return }
        guard !AppConfiguration.useMockData else { return }
        Task {
            try? await transactionService.updateTransaction(t.id, isExcluded: excluded)
        }
    }

    private func saveCategory(_ category: String) {
        guard case .transaction(let t) = item else { return }
        guard !AppConfiguration.useMockData else { return }
        Task {
            try? await transactionService.updateTransaction(t.id, category: category)
        }
    }
}
