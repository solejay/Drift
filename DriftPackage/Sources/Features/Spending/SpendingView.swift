import SwiftUI
import UI
import Core

/// Unified spending view with Apple Health-inspired design
/// Consolidates Day, Week, and Month views into a single scrollable page
public struct SpendingView: View {
    @StateObject private var viewModel = SpendingViewModel()
    @State private var showUpdated = false

    public init() {}

    public var body: some View {
        ZStack {
            DriftBackground(animated: false)

            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sectionSpacing) {
                    SpendingHeaderView(period: viewModel.selectedPeriod)
                        .staggeredAppear(index: 0)

                    SpendingControlCard(
                        selectedPeriod: $viewModel.selectedPeriod,
                        periodLabel: viewModel.spendingData?.periodLabel,
                        canGoForward: viewModel.canGoForward,
                        onPrevious: viewModel.selectPrevious,
                        onNext: viewModel.selectNext
                    )
                    .staggeredAppear(index: 1)

                    if let error = viewModel.error {
                        SpendingErrorCard(message: error.localizedDescription) {
                            Task { await viewModel.loadData() }
                        }
                    }

                    if viewModel.spendingData == nil && !viewModel.isLoading && viewModel.error == nil {
                        SpendingEmptyState(period: viewModel.selectedPeriod)
                    }

                    if let data = viewModel.spendingData {
                        SpendingHeroCard(
                            period: viewModel.selectedPeriod,
                            totalSpent: viewModel.formattedTotal,
                            averageAmount: formattedAverage,
                            comparisonPercentage: data.comparisonPercentage,
                            transactionCount: data.transactionCount
                        )
                        .staggeredAppear(index: 2)
                    }

                    if let insight = viewModel.insightText {
                        SpendingInsightCard(
                            insightText: insight,
                            isPositive: !viewModel.comparisonArrowUp
                        )
                        .staggeredAppear(index: 3)
                    }

                    if let data = viewModel.spendingData, !data.chartData.isEmpty {
                        SpendingChart(
                            period: viewModel.selectedPeriod,
                            chartData: data.chartData,
                            selectedIndex: viewModel.selectedChartIndex,
                            onSelect: { index in
                                withAnimation(DesignTokens.Animation.spring) {
                                    if viewModel.selectedChartIndex == index {
                                        viewModel.selectedChartIndex = nil
                                    } else {
                                        viewModel.selectedChartIndex = index
                                    }
                                }
                            }
                        )
                        .staggeredAppear(index: 4)
                    }

                    if let data = viewModel.spendingData, !data.categoryBreakdown.isEmpty {
                        CategoryBreakdownSection(
                            categories: data.categoryBreakdown,
                            maxItems: viewModel.selectedPeriod == .month ? 6 : 5
                        )
                        .staggeredAppear(index: 5)
                    }

                    if let data = viewModel.spendingData, !data.topItems.isEmpty {
                        TopItemsSection(
                            period: viewModel.selectedPeriod,
                            items: data.topItems,
                            maxItems: 5
                        )
                        .staggeredAppear(index: 6)
                    }

                    Spacer()
                        .frame(height: DesignTokens.Spacing.xl)
                }
                .padding(.horizontal)
                .padding(.top, DesignTokens.Spacing.lg)
            }
            .overlay(alignment: .top) {
                if showUpdated {
                    Text("Transactions synced")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(DriftPalette.sage)
                        .padding(.horizontal, DesignTokens.Spacing.md)
                        .padding(.vertical, DesignTokens.Spacing.xs)
                        .background {
                            Capsule().fill(DriftPalette.chip)
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, DesignTokens.Spacing.xs)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            HapticManager.impact(.light)
            await viewModel.loadData()
            HapticManager.notification(.success)
            withAnimation(DesignTokens.Animation.spring) {
                showUpdated = true
            }
            try? await Task.sleep(for: .seconds(1.5))
            withAnimation(DesignTokens.Animation.spring) {
                showUpdated = false
            }
        }
        .task {
            await viewModel.loadData()
        }
        .overlay {
            if viewModel.isLoading && viewModel.spendingData == nil {
                VStack(spacing: DesignTokens.Spacing.lg) {
                    VStack(spacing: DesignTokens.Spacing.md) {
                        SpendingHeroShimmer()
                        ChartShimmer()
                        CategoryListShimmer()
                    }

                    Text("Reflecting on your spending...")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(DriftPalette.muted)
                }
                .padding(.horizontal)
            }
        }
    }

    private var formattedAverage: String? {
        guard let average = viewModel.averageAmount else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: average as NSDecimalNumber)
    }
}

private struct SpendingHeaderView: View {
    let period: SpendingPeriod

    private var mirrorLabel: String {
        switch period {
        case .day: return "TODAY'S MIRROR"
        case .week: return "WEEKLY MIRROR"
        case .month: return "MONTHLY MIRROR"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            MirrorTag(text: mirrorLabel)

            Text("Spending")
                .font(.system(size: 30, weight: .semibold, design: .serif))
                .foregroundStyle(DriftPalette.ink)

            Text("A calm reflection of your \(period.displayName.lowercased()) spending.")
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundStyle(DriftPalette.muted)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct SpendingControlCard: View {
    @Binding var selectedPeriod: SpendingPeriod
    let periodLabel: String?
    let canGoForward: Bool
    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {
        GlassCard {
            VStack(spacing: DesignTokens.Spacing.md) {
                TimePeriodPicker(selectedPeriod: $selectedPeriod, showsBackground: false)

                if let periodLabel {
                    PeriodNavigator(
                        label: periodLabel,
                        canGoForward: canGoForward,
                        onPrevious: onPrevious,
                        onNext: onNext
                    )
                } else {
                    Text("Loading period...")
                        .font(.caption)
                        .foregroundStyle(DriftPalette.muted)
                }
            }
        }
    }
}

private struct MirrorTag: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(DriftPalette.muted)
            .tracking(DesignTokens.Typography.sectionHeaderTracking)
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.xs)
            .background {
                Capsule()
                    .fill(DriftPalette.chip)
            }
    }
}

private struct SpendingEmptyState: View {
    let period: SpendingPeriod

    private var message: String {
        switch period {
        case .day:
            return "No spending in your tracked categories today. We'll let you know when something comes through."
        case .week:
            return "Your weekly summary is building. Check back Sunday!"
        case .month:
            return "Nothing here this month yet. Your monthly mirror will fill in as transactions arrive."
        }
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text("All quiet")
                    .font(.system(size: 18, weight: .semibold, design: .serif))
                    .foregroundStyle(DriftPalette.ink)

                Text(message)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(DriftPalette.muted)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct SpendingErrorCard: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        GlassCard {
            HStack(spacing: DesignTokens.Spacing.md) {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(DriftPalette.sunsetDeep)
                    .accessibilityLabel("Warning")

                VStack(alignment: .leading, spacing: 4) {
                    Text("Something went wrong")
                        .font(.system(size: 16, weight: .semibold, design: .serif))
                        .foregroundStyle(DriftPalette.ink)
                    Text("We couldn't load your spending. Pull down to try again.")
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(DriftPalette.muted)
                        .lineLimit(2)
                }

                Spacer()

                Button("Retry", action: retry)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DriftPalette.accentDeep)
                    .accessibilityHint("Reloads your spending data")
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        SpendingView()
    }
}
