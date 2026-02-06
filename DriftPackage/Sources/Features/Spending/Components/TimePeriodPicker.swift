import SwiftUI
import UI

/// Segmented control for selecting spending time period (D | W | M)
public struct TimePeriodPicker: View {
    @Binding var selectedPeriod: SpendingPeriod
    private let showsBackground: Bool

    public init(selectedPeriod: Binding<SpendingPeriod>, showsBackground: Bool = true) {
        self._selectedPeriod = selectedPeriod
        self.showsBackground = showsBackground
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(SpendingPeriod.allCases) { period in
                periodButton(period)
            }
        }
        .padding(4)
        .background {
            if showsBackground {
                if #available(iOS 26.0, *) {
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                        .fill(.ultraThinMaterial)
                } else {
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                        .fill(DriftPalette.chip)
                }
            }
        }
    }

    private func periodButton(_ period: SpendingPeriod) -> some View {
        Button {
            HapticManager.selection()
            withAnimation(DesignTokens.Animation.spring) {
                selectedPeriod = period
            }
        } label: {
            Text(period.rawValue)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, DesignTokens.Spacing.md)
                .frame(minHeight: 36)
                .foregroundStyle(selectedPeriod == period ? DriftPalette.chipText : DriftPalette.ink)
                .background {
                    if selectedPeriod == period {
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.sm)
                            .fill(DriftPalette.accentDeep)
                    }
                }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    @Previewable @State var period: SpendingPeriod = .day

    VStack(spacing: 32) {
        TimePeriodPicker(selectedPeriod: $period)

        Text("Selected: \(period.displayName)")
    }
    .padding()
}
