import SwiftUI
import UI
import Core

/// View showing detected leaky buckets (recurring spending patterns)
public struct LeakyBucketsView: View {
    @StateObject private var viewModel = LeakyBucketsViewModel()
    @State private var selectedBucket: LeakyBucket?
    @State private var showUpdated = false
    @State private var showDateRangePicker = false

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

                    LeakyFilterCard(
                        selectedFilter: $viewModel.selectedFilter,
                        showDateRangePicker: $showDateRangePicker
                    )
                    .staggeredAppear(index: 1)

                    if let error = viewModel.error {
                        LeakyErrorCard(message: error.localizedDescription) {
                            Task { await viewModel.analyze() }
                        }
                    }

                    if viewModel.buckets.isEmpty && !viewModel.isLoading {
                        emptyState
                    } else if !viewModel.buckets.isEmpty {
                        summaryCard
                            .staggeredAppear(index: 2)
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
            if viewModel.error == nil {
                HapticManager.notification(.success)
                withAnimation(DesignTokens.Animation.spring) {
                    showUpdated = true
                }
                try? await Task.sleep(for: .seconds(1.5))
                withAnimation(DesignTokens.Animation.spring) {
                    showUpdated = false
                }
            } else {
                HapticManager.notification(.error)
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
            BucketDetailSheet(bucket: bucket, viewModel: viewModel)
        }
        .sheet(isPresented: $showDateRangePicker) {
            DateRangePickerSheet(selectedFilter: $viewModel.selectedFilter)
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
        ZStack {
            DriftBackground(animated: false)

            VStack(spacing: DesignTokens.Spacing.md) {
                LeakySummaryShimmer()
                BucketListShimmer()

                if let stage = viewModel.aiStage {
                    Text(stage.displayText)
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundStyle(DriftPalette.muted)
                        .contentTransition(.opacity)
                        .animation(DesignTokens.Animation.spring, value: stage)
                } else {
                    Text("Analyzing your spending patterns...")
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundStyle(DriftPalette.muted)
                }

                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, DesignTokens.Spacing.lg)
        }
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
                        .staggeredAppear(index: categoryIndex * 3 + bucketIndex + 3)
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
    let viewModel: LeakyBucketsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                DriftBackground(animated: false)

                ScrollView {
                    VStack(spacing: DesignTokens.Spacing.lg) {
                        VStack(spacing: DesignTokens.Spacing.md) {
                            MerchantLogoCategoryView(logoUrl: bucket.logoUrl, category: bucket.category, size: .large)

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

                                if let classification = bucket.aiClassification {
                                    StatRow(title: "AI assessment", value: classification.reasoning)
                                }
                            }
                        }

                        BucketInsightView(
                            bucket: bucket,
                            insightStream: viewModel.insightStream(for: bucket)
                        )
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

// MARK: - Filter Card

private struct LeakyFilterCard: View {
    @Binding var selectedFilter: LeakyBucketFilter
    @Binding var showDateRangePicker: Bool

    private var isCustomRange: Bool {
        if case .dateRange = selectedFilter { return true }
        return false
    }

    var body: some View {
        HStack {
            Image(systemName: "calendar")
                .font(.subheadline)
                .foregroundStyle(DriftPalette.muted)

            Menu {
                ForEach(LeakyBucketFilter.fixedCases, id: \.label) { filter in
                    Button {
                        HapticManager.selection()
                        withAnimation(DesignTokens.Animation.spring) {
                            selectedFilter = filter
                        }
                    } label: {
                        if selectedFilter == filter {
                            Label(filter.label, systemImage: "checkmark")
                        } else {
                            Text(filter.label)
                        }
                    }
                }

                Divider()

                Button {
                    HapticManager.selection()
                    showDateRangePicker = true
                } label: {
                    if isCustomRange {
                        Label("Custom Range", systemImage: "checkmark")
                    } else {
                        Text("Custom Range")
                    }
                }
            } label: {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    Text(displayLabel)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(DriftPalette.ink)

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(DriftPalette.muted)
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, DesignTokens.Spacing.sm)
                .background {
                    Capsule().fill(DriftPalette.chip)
                }
            }

            Spacer()
        }
    }

    private var displayLabel: String {
        if isCustomRange, case .dateRange(let from, let to) = selectedFilter {
            return formatRange(from: from, to: to)
        }
        return selectedFilter.label
    }

    private func formatRange(from: Date, to: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: from)) – \(formatter.string(from: to))"
    }
}

// MARK: - Date Range Picker Sheet

private struct DateRangePickerSheet: View {
    @Binding var selectedFilter: LeakyBucketFilter
    @Environment(\.dismiss) private var dismiss
    @State private var fromDate: Date
    @State private var toDate: Date

    init(selectedFilter: Binding<LeakyBucketFilter>) {
        self._selectedFilter = selectedFilter
        if case .dateRange(let from, let to) = selectedFilter.wrappedValue {
            self._fromDate = State(initialValue: from)
            self._toDate = State(initialValue: to)
        } else {
            let now = Date()
            let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: now)!
            self._fromDate = State(initialValue: monthAgo)
            self._toDate = State(initialValue: now)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DriftBackground(animated: false)

                ScrollView {
                    VStack(spacing: DesignTokens.Spacing.lg) {
                        GlassCard {
                            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                                Text("From")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(DriftPalette.muted)
                                    .textCase(.uppercase)
                                    .tracking(DesignTokens.Typography.sectionHeaderTracking)

                                DatePicker(
                                    "From",
                                    selection: $fromDate,
                                    in: ...Date(),
                                    displayedComponents: .date
                                )
                                .datePickerStyle(.graphical)
                                .tint(DriftPalette.accentDeep)
                                .labelsHidden()
                            }
                        }

                        GlassCard {
                            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                                Text("To")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(DriftPalette.muted)
                                    .textCase(.uppercase)
                                    .tracking(DesignTokens.Typography.sectionHeaderTracking)

                                DatePicker(
                                    "To",
                                    selection: $toDate,
                                    in: ...Date(),
                                    displayedComponents: .date
                                )
                                .datePickerStyle(.graphical)
                                .tint(DriftPalette.accentDeep)
                                .labelsHidden()
                            }
                        }

                        Button {
                            HapticManager.impact(.medium)
                            withAnimation(DesignTokens.Animation.spring) {
                                selectedFilter = .dateRange(fromDate, toDate)
                            }
                            dismiss()
                        } label: {
                            Text("Apply")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.glassProminentPill)
                    }
                    .padding()
                }
            }
            .navigationTitle("Date Range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        LeakyBucketsView()
    }
}
