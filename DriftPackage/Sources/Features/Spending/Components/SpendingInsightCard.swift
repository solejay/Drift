import SwiftUI
import UI

/// Apple Health-style insight card showing spending patterns
public struct SpendingInsightCard: View {
    let insightText: String
    let isPositive: Bool

    public init(insightText: String, isPositive: Bool = false) {
        self.insightText = insightText
        self.isPositive = isPositive
    }

    private var iconName: String {
        isPositive ? "arrow.down.circle" : "arrow.up.circle"
    }

    private var iconColor: Color {
        isPositive ? DriftPalette.sage : DriftPalette.sunsetDeep
    }

    public var body: some View {
        GlassCard {
            HStack(spacing: DesignTokens.Spacing.md) {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundStyle(iconColor)
                    .accessibilityLabel(isPositive ? "Spending down" : "Spending up")

                Text(insightText)
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundStyle(DriftPalette.ink)
                    .multilineTextAlignment(.leading)

                Spacer()
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    VStack(spacing: 16) {
        SpendingInsightCard(
            insightText: "You're spending 15% more than you usually do this week",
            isPositive: false
        )

        SpendingInsightCard(
            insightText: "You're spending 8% less than you usually do today",
            isPositive: true
        )
    }
    .padding()
    .background(Color(uiColor: .systemGroupedBackground))
}
