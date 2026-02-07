import SwiftUI
import UI
import Core

/// View showing detected leaky buckets (recurring spending patterns)
public struct LeakyBucketsView: View {
    @StateObject private var viewModel = LeakyBucketsViewModel()
    @State private var selectedBucket: LeakyBucket?
    @State private var showUpdated = false

    public init() {}

    public var body: some View {
        ZStack {
            DriftBackground(animated: false)

            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sectionSpacing) {
                    LeakyHeaderView(
                        bucketCount: viewModel.buckets.count,
                        monthlyTotal: viewModel.formattedMonthlyImpact,
                        yearlyTotal: viewModel.formattedYearlyImpact
                    )
                    .staggeredAppear(index: 0)

                    if let error = viewModel.error {
                        LeakyErrorCard(message: error.localizedDescription) {
                            Task { await viewModel.analyze() }
                        }
                    }

                    if viewModel.buckets.isEmpty && !viewModel.isLoading {
                        emptyState
                    } else if !viewModel.buckets.isEmpty {
                        summaryCard
                            .staggeredAppear(index: 1)
                        bucketList
                    }

                    Spacer()
                        .frame(height: DesignTokens.Spacing.xl)
                }
                .padding(.horizontal)
                .padding(.top, DesignTokens.Spacing.lg)
            }
            .overlay(alignment: .top) {
                if showUpdated {
                    Text("Updated")
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
            await viewModel.refresh()
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
            await viewModel.analyze()
        }
        .overlay {
            if viewModel.isLoading && viewModel.buckets.isEmpty {
                loadingView
            }
        }
        .sheet(item: $selectedBucket) { bucket in
            BucketDetailSheet(bucket: bucket)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Spacer()
                .frame(height: 40)

            Image(systemName: "checkmark.seal")
                .font(.system(size: 64))
                .foregroundStyle(DriftPalette.sage)
                .accessibilityLabel("Checkmark")

            VStack(spacing: DesignTokens.Spacing.sm) {
                Text("Looking steady")
                    .font(.system(size: 24, weight: .semibold, design: .serif))
                    .foregroundStyle(DriftPalette.ink)

                Text("No leaky buckets detected \u{2014} your spending looks steady.")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundStyle(DriftPalette.muted)
                    .multilineTextAlignment(.center)
            }

            Button(action: {
                Task { await viewModel.analyze() }
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Scan again")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminentPill)
            .accessibilityHint("Re-analyzes your recent transactions for recurring patterns")
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            LeakySummaryShimmer()
            BucketListShimmer()

            Text("Analyzing your spending patterns...")
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundStyle(DriftPalette.muted)
        }
        .padding(.horizontal)
    }

    // MARK: - Summary

    private var summaryCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Leaky bucket total")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(DriftPalette.muted)
                            .textCase(.uppercase)
                            .tracking(DesignTokens.Typography.sectionHeaderTracking)

                        Text(viewModel.formattedMonthlyImpact)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(DriftPalette.ink)
                            .contentTransition(.numericText())
                            .animation(DesignTokens.Animation.spring, value: viewModel.formattedMonthlyImpact)
                        Text("Monthly impact")
                            .font(.caption)
                            .foregroundStyle(DriftPalette.muted)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 6) {
                        Text(viewModel.formattedYearlyImpact)
                            .font(.headline)
                            .foregroundStyle(DriftPalette.ink)
                            .contentTransition(.numericText())
                            .animation(DesignTokens.Animation.spring, value: viewModel.formattedYearlyImpact)
                        Text("Yearly impact")
                            .font(.caption)
                            .foregroundStyle(DriftPalette.muted)
                    }
                }

                HStack {
                    MirrorTag(text: "\(viewModel.buckets.count) patterns")
                    Spacer()
                    Button(action: { Task { await viewModel.analyze() } }) {
                        Text("Analyze again")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(DriftPalette.accentDeep)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Re-runs the leaky bucket analysis")
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Leaky bucket total: \(viewModel.formattedMonthlyImpact) monthly, \(viewModel.formattedYearlyImpact) yearly, \(viewModel.buckets.count) patterns detected")
    }

    // MARK: - Bucket List

    private var bucketList: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sectionSpacing) {
            ForEach(Array(viewModel.bucketsByCategory.enumerated()), id: \.element.0) { categoryIndex, pair in
                let (category, buckets) = pair
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    Text(category.displayName)
                        .sectionHeaderStyle()

                    ForEach(Array(buckets.enumerated()), id: \.element.id) { bucketIndex, bucket in
                        LeakyBucketCard(bucket: bucket) {
                            selectedBucket = bucket
                        }
                        .staggeredAppear(index: categoryIndex * 3 + bucketIndex + 2)
                    }
                }
            }
        }
    }
}

private struct LeakyHeaderView: View {
    let bucketCount: Int
    let monthlyTotal: String
    let yearlyTotal: String

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            MirrorTag(text: "Leaky buckets")

            Text(bucketCount > 0 ? "Hidden leaks" : "Leaky Buckets")
                .font(.system(size: 30, weight: .semibold, design: .serif))
                .foregroundStyle(DriftPalette.ink)

            Text(bucketCount > 0
                 ? "Small patterns that quietly add up over time."
                 : "We'll look for recurring patterns in your spending.")
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundStyle(DriftPalette.muted)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Bucket Detail Sheet

private struct BucketDetailSheet: View {
    let bucket: LeakyBucket
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                DriftBackground(animated: false)

                ScrollView {
                    VStack(spacing: DesignTokens.Spacing.lg) {
                        VStack(spacing: DesignTokens.Spacing.md) {
                            CategoryIcon(category: bucket.category, size: .large)

                            Text(bucket.merchantName)
                                .font(.system(size: 26, weight: .semibold, design: .serif))
                                .foregroundStyle(DriftPalette.ink)

                            Text(bucket.frequency.displayName)
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundStyle(DriftPalette.muted)
                        }
                        .padding(.top)

                        GlassCard {
                            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                                Text("Monthly impact")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(DriftPalette.muted)
                                    .textCase(.uppercase)
                                    .tracking(DesignTokens.Typography.sectionHeaderTracking)

                                Text(bucket.formattedMonthlyImpact)
                                    .font(.system(size: 30, weight: .bold, design: .rounded))
                                    .foregroundStyle(DriftPalette.ink)

                                HStack {
                                    Text("Yearly: \(bucket.formattedYearlyImpact)")
                                        .font(.caption)
                                        .foregroundStyle(DriftPalette.muted)
                                    Spacer()
                                    Text("Avg: \(bucket.formattedAverageAmount)")
                                        .font(.caption)
                                        .foregroundStyle(DriftPalette.muted)
                                }
                            }
                        }

                        GlassCard {
                            VStack(spacing: DesignTokens.Spacing.md) {
                                StatRow(title: "Times detected", value: "\(bucket.occurrenceCount)")

                                if let first = bucket.firstOccurrence {
                                    StatRow(title: "First seen", value: formatDate(first))
                                }

                                if let last = bucket.lastOccurrence {
                                    StatRow(title: "Last seen", value: formatDate(last))
                                }

                                StatRow(title: "Confidence", value: bucket.confidencePercentage)
                            }
                        }

                        GlassCard {
                            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                                HStack {
                                    Image(systemName: "lightbulb")
                                        .foregroundStyle(DriftPalette.sunset)
                                    Text("Insight")
                                        .font(.system(size: 16, weight: .semibold, design: .serif))
                                        .foregroundStyle(DriftPalette.ink)
                                }

                                Text(generateInsight())
                                    .font(.system(size: 15, weight: .regular, design: .rounded))
                                    .foregroundStyle(DriftPalette.muted)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func generateInsight() -> String {
        let yearly = bucket.formattedYearlyImpact

        switch bucket.category {
        case .food:
            return "Your \(bucket.merchantName.lowercased()) habit adds up to \(yearly) per year. That's equivalent to a nice dinner out every week."

        case .subscriptions:
            return "This subscription costs \(yearly) annually. Are you getting value from it?"

        case .entertainment:
            return "Entertainment at \(bucket.merchantName) totals \(yearly) yearly. Consider if this aligns with your priorities."

        default:
            return "These recurring purchases at \(bucket.merchantName) total \(yearly) per year. Small amounts add up."
        }
    }
}

// MARK: - Impact / Stat Rows

private struct StatRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(DriftPalette.muted)

            Spacer()

            Text(value)
                .font(.body.weight(.medium))
                .foregroundStyle(DriftPalette.ink)
        }
    }
}

private struct MirrorTag: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
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

private struct LeakyErrorCard: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        GlassCard {
            HStack(spacing: DesignTokens.Spacing.md) {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(DriftPalette.sunsetDeep)
                    .accessibilityLabel("Warning")

                VStack(alignment: .leading, spacing: 4) {
                    Text("Couldn't analyze")
                        .font(.system(size: 16, weight: .semibold, design: .serif))
                        .foregroundStyle(DriftPalette.ink)
                    Text("Something went wrong. Pull down to try again.")
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(DriftPalette.muted)
                        .lineLimit(2)
                }

                Spacer()

                Button("Retry", action: retry)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DriftPalette.accentDeep)
                    .accessibilityHint("Re-runs the analysis")
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        LeakyBucketsView()
    }
}
