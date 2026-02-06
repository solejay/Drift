import SwiftUI
import UI

/// Onboarding flow for new users
public struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var selectedBuckets: [BucketOption] = [.foodDelivery, .coffee]
    @State private var notificationTime: NotificationTimeOption = .eightPM
    @Binding var isComplete: Bool

    private let steps: [OnboardingStep] = OnboardingStep.allCases

    public init(isComplete: Binding<Bool>) {
        self._isComplete = isComplete
    }

    public var body: some View {
        ZStack {
            DriftBackground()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        PageView(
                            step: step,
                            selectedBuckets: $selectedBuckets,
                            notificationTime: $notificationTime
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(DesignTokens.Animation.spring, value: currentPage)

                VStack(spacing: DesignTokens.Spacing.lg) {
                    ProgressDots(count: steps.count, currentIndex: currentPage)

                    Button(action: handleAction) {
                        Text(primaryButtonTitle)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminentPill)
                    .padding(.horizontal, DesignTokens.Spacing.xl)

                    if showsSkip {
                        Button("Skip for now") {
                            withAnimation {
                                isComplete = true
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(DriftPalette.muted)
                    }
                }
                .padding(.bottom, DesignTokens.Spacing.xl)
            }
        }
    }

    private var primaryButtonTitle: String {
        guard let step = steps[safe: currentPage] else { return "Continue" }
        switch step {
        case .welcome:
            return "Start your mirror"
        case .done:
            return "Go to Today"
        default:
            return "Continue"
        }
    }

    private var showsSkip: Bool {
        currentPage < steps.count - 1
    }

    private func handleAction() {
        if currentPage < steps.count - 1 {
            withAnimation {
                currentPage += 1
            }
        } else {
            withAnimation {
                isComplete = true
            }
        }
    }
}

// MARK: - Step Model

private enum OnboardingStep: Int, CaseIterable {
    case welcome
    case mirrorPreview
    case connectBank
    case buckets
    case notificationTime
    case done
}

// MARK: - Page View

private struct PageView: View {
    let step: OnboardingStep
    @Binding var selectedBuckets: [BucketOption]
    @Binding var notificationTime: NotificationTimeOption

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Spacer(minLength: DesignTokens.Spacing.xl)

            switch step {
            case .welcome:
                WelcomeView()
            case .mirrorPreview:
                MirrorPreviewView()
            case .connectBank:
                ConnectBankView()
            case .buckets:
                BucketSelectionView(selectedBuckets: $selectedBuckets)
            case .notificationTime:
                NotificationTimeView(notificationTime: $notificationTime)
            case .done:
                DoneView(notificationTime: notificationTime)
            }

            Spacer(minLength: DesignTokens.Spacing.lg)
        }
        .padding(.horizontal, DesignTokens.Spacing.xl)
        .padding(.top, DesignTokens.Spacing.lg)
    }
}

// MARK: - Welcome

private struct WelcomeView: View {
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            PillLabel(text: "Daily mirror")

            RippleMark()
                .frame(height: 160)
                .accessibilityLabel("Drift water ripple")

            VStack(spacing: DesignTokens.Spacing.md) {
                Text("See where your money quietly drifts")
                    .font(.system(size: 32, weight: .semibold, design: .serif))
                    .foregroundStyle(DriftPalette.ink)
                    .multilineTextAlignment(.center)

                Text("No budgets. No guilt. Just daily awareness.")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundStyle(DriftPalette.muted)
                    .multilineTextAlignment(.center)
            }

            MiniMirrorCard()
        }
    }
}

// MARK: - Mirror Preview

private struct MirrorPreviewView: View {
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            VStack(spacing: DesignTokens.Spacing.sm) {
                Text("Your daily mirror")
                    .font(.system(size: 24, weight: .semibold, design: .serif))
                    .foregroundStyle(DriftPalette.ink)

                Text("A 10-second reflection, once per day.")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundStyle(DriftPalette.muted)
            }

            MirrorHeroCard()

            WeeklyPatternRow()

            GlassCard {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("This week")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(DriftPalette.muted)
                        .textCase(.uppercase)
                        .tracking(DesignTokens.Typography.sectionHeaderTracking)

                    HStack {
                        Text("$156")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(DriftPalette.ink)
                        Spacer()
                        Text("+12% vs last week")
                            .font(.caption)
                            .foregroundStyle(DriftPalette.muted)
                    }

                    MiniCategoryBreakdownRow()
                }
            }
        }
    }
}

// MARK: - Connect Bank

private struct ConnectBankView: View {
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            VStack(spacing: DesignTokens.Spacing.sm) {
                Text("Connect securely")
                    .font(.system(size: 24, weight: .semibold, design: .serif))
                    .foregroundStyle(DriftPalette.ink)

                Text("Read-only access with Plaid. We never see your credentials.")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundStyle(DriftPalette.muted)
                    .multilineTextAlignment(.center)
            }

            GlassCard {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    TrustRow(icon: "lock.shield", title: "Read-only access", subtitle: "We never move your money.")
                    TrustRow(icon: "checkmark.seal", title: "Secured by Plaid", subtitle: "Bank-grade encryption.")
                    TrustRow(icon: "hand.raised", title: "Privacy first", subtitle: "We do not sell your data.")
                }
            }
        }
    }
}

// MARK: - Buckets

private struct BucketSelectionView: View {
    @Binding var selectedBuckets: [BucketOption]

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            VStack(spacing: DesignTokens.Spacing.sm) {
                Text("Pick your leaky buckets")
                    .font(.system(size: 24, weight: .semibold, design: .serif))
                    .foregroundStyle(DriftPalette.ink)

                Text("Choose 2 to 4 categories to track.")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundStyle(DriftPalette.muted)
            }

            HStack {
                CountPill(text: "\(selectedBuckets.count) of 4 selected")
                Spacer()
            }

            FlexibleGrid(columns: 2, spacing: DesignTokens.Spacing.sm) {
                ForEach(BucketOption.allCases) { option in
                    BucketChip(
                        option: option,
                        isSelected: selectedBuckets.contains(option)
                    ) {
                        toggleBucket(option)
                    }
                }
            }
        }
    }

    private func toggleBucket(_ option: BucketOption) {
        HapticManager.selection()

        if let index = selectedBuckets.firstIndex(of: option) {
            selectedBuckets.remove(at: index)
            return
        }

        if selectedBuckets.count < 4 {
            selectedBuckets.append(option)
        } else if let first = selectedBuckets.first {
            selectedBuckets.removeAll { $0 == first }
            selectedBuckets.append(option)
        }
    }
}

// MARK: - Notification Time

private struct NotificationTimeView: View {
    @Binding var notificationTime: NotificationTimeOption

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            VStack(spacing: DesignTokens.Spacing.sm) {
                Text("Pick a daily time")
                    .font(.system(size: 24, weight: .semibold, design: .serif))
                    .foregroundStyle(DriftPalette.ink)

                Text("One notification per day. Never more.")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundStyle(DriftPalette.muted)
            }

            HStack(spacing: DesignTokens.Spacing.sm) {
                ForEach(NotificationTimeOption.allCases, id: \.self) { option in
                    TimeChip(
                        title: option.title,
                        isSelected: notificationTime == option
                    ) {
                        HapticManager.selection()
                        notificationTime = option
                    }
                }
            }

            GlassCard {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("Notification preview")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(DriftPalette.muted)
                        .textCase(.uppercase)
                        .tracking(DesignTokens.Typography.sectionHeaderTracking)

                    Text("Today: $47 - Uber Eats $32, Amazon $15.")
                        .font(.body)
                        .foregroundStyle(DriftPalette.ink)

                    Text("Delivered at \(notificationTime.title)")
                        .font(.caption)
                        .foregroundStyle(DriftPalette.muted)
                }
            }
        }
    }
}

// MARK: - Done

private struct DoneView: View {
    let notificationTime: NotificationTimeOption

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Circle()
                .fill(DriftPalette.accent.opacity(0.12))
                .frame(width: 110, height: 110)
                .overlay(
                    Image(systemName: "drop.fill")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(DriftPalette.accent)
                )
                .accessibilityLabel("Drift drop icon")

            VStack(spacing: DesignTokens.Spacing.sm) {
                Text("Your mirror is set")
                    .font(.system(size: 24, weight: .semibold, design: .serif))
                    .foregroundStyle(DriftPalette.ink)

                Text("See you tonight at \(notificationTime.title).")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundStyle(DriftPalette.muted)
            }

            GlassCard {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Weekly reflection")
                            .font(.caption)
                            .foregroundStyle(DriftPalette.muted)
                        Text("Every Sunday")
                            .font(.headline)
                            .foregroundStyle(DriftPalette.ink)
                    }
                    Spacer()
                    Image(systemName: "calendar")
                        .foregroundStyle(DriftPalette.muted)
                }
            }
        }
    }
}

// MARK: - Supporting Views

private struct ProgressDots: View {
    let count: Int
    let currentIndex: Int

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            ForEach(0 ..< count, id: \.self) { index in
                Capsule()
                    .fill(index == currentIndex ? DriftPalette.accent : DriftPalette.track)
                    .frame(width: index == currentIndex ? 18 : 8, height: 8)
                    .animation(.easeInOut(duration: DesignTokens.Animation.normal), value: currentIndex)
            }
        }
    }
}

private struct PillLabel: View {
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

private struct CountPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(DriftPalette.muted)
            .padding(.horizontal, DesignTokens.Spacing.sm)
            .padding(.vertical, DesignTokens.Spacing.xs)
            .background {
                Capsule()
                    .fill(DriftPalette.chip)
            }
    }
}

private struct RippleMark: View {
    @State private var pulse = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(DriftPalette.accent.opacity(0.18), lineWidth: 2)
                .frame(width: 150, height: 150)
                .scaleEffect(pulse ? 1.05 : 0.95)
                .opacity(pulse ? 0.4 : 0.8)

            Circle()
                .stroke(DriftPalette.accent.opacity(0.35), lineWidth: 3)
                .frame(width: 110, height: 110)
                .scaleEffect(pulse ? 1.02 : 0.98)

            Circle()
                .fill(DriftPalette.accent.opacity(0.12))
                .frame(width: 70, height: 70)
            Image(systemName: "drop.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(DriftPalette.accent)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

private struct MiniMirrorCard: View {
    var body: some View {
        GlassCard {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today")
                        .font(.caption)
                        .foregroundStyle(DriftPalette.muted)
                    Text("$34")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(DriftPalette.ink)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Coffee $12")
                        .font(.caption)
                    Text("Amazon $22")
                        .font(.caption)
                }
                .foregroundStyle(DriftPalette.muted)
            }
        }
    }
}

private struct MirrorHeroCard: View {
    var body: some View {
        HeroCard(gradient: LinearGradient(
            colors: [
                DriftPalette.accent,
                DriftPalette.accentDeep
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )) {
            VStack(spacing: DesignTokens.Spacing.sm) {
                Text("Today")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                    .textCase(.uppercase)
                    .tracking(DesignTokens.Typography.sectionHeaderTracking)

                Text("$47")
                    .font(.system(size: 46, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()

                HStack(spacing: DesignTokens.Spacing.md) {
                    TagView(text: "Uber Eats $32")
                    TagView(text: "Amazon $15")
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

private struct WeeklyPatternRow: View {
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            ForEach(0 ..< 7, id: \.self) { index in
                Circle()
                    .fill(index == 4 ? DriftPalette.accent : DriftPalette.track)
                    .frame(width: index == 4 ? 12 : 8, height: index == 4 ? 12 : 8)
            }
        }
    }
}

private struct MiniCategoryBreakdownRow: View {
    private let segments: [(String, Double, Color)] = [
        ("Food", 0.5, Color.orange),
        ("Shopping", 0.3, Color.pink),
        ("Rides", 0.2, Color.blue)
    ]

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xs) {
            GeometryReader { geo in
                HStack(spacing: 0) {
                    ForEach(segments.indices, id: \.self) { index in
                        Rectangle()
                            .fill(segments[index].2)
                            .frame(width: geo.size.width * segments[index].1)
                    }
                }
                .clipShape(Capsule())
            }
            .frame(height: 10)

            HStack {
                ForEach(segments.indices, id: \.self) { index in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(segments[index].2)
                            .frame(width: 6, height: 6)
                        Text(segments[index].0)
                            .font(.caption2)
                            .foregroundStyle(DriftPalette.muted)
                    }
                    if index < segments.count - 1 {
                        Spacer()
                    }
                }
            }
        }
    }
}

private struct TrustRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(DriftPalette.accent)
                .frame(width: 36, height: 36)
                .background(Circle().fill(DriftPalette.accent.opacity(0.12)))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(DriftPalette.ink)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(DriftPalette.muted)
            }

            Spacer()
        }
        .accessibilityElement(children: .combine)
    }
}

private enum BucketOption: String, CaseIterable, Identifiable {
    case foodDelivery
    case coffee
    case amazon
    case dining
    case rideshare
    case subscriptions

    var id: String { rawValue }

    var title: String {
        switch self {
        case .foodDelivery: return "Food Delivery"
        case .coffee: return "Coffee"
        case .amazon: return "Amazon"
        case .dining: return "Dining"
        case .rideshare: return "Rideshare"
        case .subscriptions: return "Subscriptions"
        }
    }

    var icon: String {
        switch self {
        case .foodDelivery: return "fork.knife"
        case .coffee: return "cup.and.saucer"
        case .amazon: return "cart"
        case .dining: return "wineglass"
        case .rideshare: return "car"
        case .subscriptions: return "play.rectangle"
        }
    }
}

private struct BucketChip: View {
    let option: BucketOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Spacing.xs) {
                Image(systemName: option.icon)
                Text(option.title)
                    .font(.subheadline.weight(.medium))
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .foregroundStyle(isSelected ? DriftPalette.chipText : DriftPalette.ink)
            .background {
                Capsule()
                    .fill(isSelected ? DriftPalette.accentDeep : DriftPalette.chip)
            }
        }
        .buttonStyle(.plain)
    }
}

private enum NotificationTimeOption: String, CaseIterable {
    case sevenPM
    case eightPM
    case ninePM

    var title: String {
        switch self {
        case .sevenPM: return "7:00 PM"
        case .eightPM: return "8:00 PM"
        case .ninePM: return "9:00 PM"
        }
    }
}

private struct TimeChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignTokens.Spacing.sm)
                .foregroundStyle(isSelected ? DriftPalette.chipText : DriftPalette.ink)
                .background {
                    Capsule()
                        .fill(isSelected ? DriftPalette.accentDeep : DriftPalette.chip)
                }
        }
        .buttonStyle(.plain)
    }
}

private struct TagView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption.weight(.medium))
            .padding(.horizontal, DesignTokens.Spacing.sm)
            .padding(.vertical, DesignTokens.Spacing.xs)
            .foregroundStyle(.white)
            .background {
                Capsule().fill(Color.white.opacity(0.2))
            }
    }
}

private struct FlexibleGrid<Content: View>: View {
    let columns: Int
    let spacing: CGFloat
    let content: Content

    init(columns: Int, spacing: CGFloat, @ViewBuilder content: () -> Content) {
        self.columns = columns
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns), spacing: spacing) {
            content
        }
    }
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    OnboardingView(isComplete: .constant(false))
}
