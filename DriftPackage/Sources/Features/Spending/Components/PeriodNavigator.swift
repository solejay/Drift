import SwiftUI
import UI

/// Navigation control with previous/next buttons and period label
public struct PeriodNavigator: View {
    let label: String
    let canGoForward: Bool
    let onPrevious: () -> Void
    let onNext: () -> Void

    public init(
        label: String,
        canGoForward: Bool,
        onPrevious: @escaping () -> Void,
        onNext: @escaping () -> Void
    ) {
        self.label = label
        self.canGoForward = canGoForward
        self.onPrevious = onPrevious
        self.onNext = onNext
    }

    public var body: some View {
        HStack {
            Button {
                HapticManager.impact(.light)
                onPrevious()
            } label: {
                circularArrowButton(systemName: "chevron.left", enabled: true)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Previous period")

            Spacer()

            Text(label)
                .font(.system(size: 16, weight: .semibold, design: .serif))
                .foregroundStyle(DriftPalette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer()

            Button {
                HapticManager.impact(.light)
                onNext()
            } label: {
                circularArrowButton(systemName: "chevron.right", enabled: canGoForward)
            }
            .buttonStyle(.plain)
            .disabled(!canGoForward)
            .accessibilityLabel("Next period")
        }
    }

    @ViewBuilder
    private func circularArrowButton(systemName: String, enabled: Bool) -> some View {
        if #available(iOS 26.0, *) {
            Image(systemName: systemName)
                .font(.body.weight(.semibold))
                .foregroundStyle(enabled ? DriftPalette.ink : DriftPalette.muted)
                .frame(width: 44, height: 44)
                .glassEffect(in: .circle)
        } else {
            Image(systemName: systemName)
                .font(.body.weight(.semibold))
                .foregroundStyle(enabled ? DriftPalette.ink : DriftPalette.muted)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
        }
    }
}

#Preview {
    VStack(spacing: 32) {
        PeriodNavigator(
            label: "Today",
            canGoForward: false,
            onPrevious: {},
            onNext: {}
        )

        PeriodNavigator(
            label: "Jan 15-21",
            canGoForward: true,
            onPrevious: {},
            onNext: {}
        )

        PeriodNavigator(
            label: "January 2026",
            canGoForward: true,
            onPrevious: {},
            onNext: {}
        )
    }
    .padding()
}
