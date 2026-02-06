import SwiftUI
import UI

/// Hero card showing total spending with comparison to average (Apple Health-style)
public struct SpendingHeroCard: View {
    let period: SpendingPeriod
    let totalSpent: String
    let averageAmount: String?
    let comparisonPercentage: Double?
    let transactionCount: Int

    public init(
        period: SpendingPeriod,
        totalSpent: String,
        averageAmount: String? = nil,
        comparisonPercentage: Double? = nil,
        transactionCount: Int = 0
    ) {
        self.period = period
        self.totalSpent = totalSpent
        self.averageAmount = averageAmount
        self.comparisonPercentage = comparisonPercentage
        self.transactionCount = transactionCount
    }

    private var gradient: LinearGradient {
        switch period {
        case .day:
            return LinearGradient(
                colors: [DriftPalette.sunset, DriftPalette.sunsetDeep],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .week:
            return LinearGradient(
                colors: [DriftPalette.accent, DriftPalette.accentDeep],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .month:
            return LinearGradient(
                colors: [DriftPalette.sage, DriftPalette.sageDeep],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var periodTitle: String {
        switch period {
        case .day: return "Spent Today"
        case .week: return "Weekly Spending"
        case .month: return "Monthly Spending"
        }
    }

    public var body: some View {
        HeroCard(gradient: gradient) {
            VStack(spacing: DesignTokens.Spacing.md) {
                // Title
                Text(periodTitle)
                    .font(.system(size: 14, weight: .semibold, design: .serif))
                    .foregroundStyle(.white.opacity(0.8))

                // Total amount with numeric transition
                Text(totalSpent)
                    .font(.system(size: 50, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(DesignTokens.Animation.spring, value: totalSpent)
                    .minimumScaleFactor(0.7)

                // Comparison row (Apple Health style)
                if let average = averageAmount {
                    HStack(spacing: DesignTokens.Spacing.xl) {
                        // Current period
                        VStack(spacing: 4) {
                            Text(totalSpent)
                                .font(.title3.weight(.semibold))
                                .contentTransition(.numericText())
                            Text(period.displayName)
                                .font(.caption)
                                .opacity(0.8)
                        }

                        // Divider
                        Rectangle()
                            .fill(.white.opacity(0.3))
                            .frame(width: 1, height: 40)

                        // Average
                        VStack(spacing: 4) {
                            Text(average)
                                .font(.title3.weight(.semibold))
                                .contentTransition(.numericText())
                            Text("Average")
                                .font(.caption)
                                .opacity(0.8)
                        }
                    }
                    .foregroundStyle(.white)
                }

                // Comparison percentage and transaction count
                HStack(spacing: DesignTokens.Spacing.lg) {
                    if let comparison = comparisonPercentage {
                        HStack(spacing: 4) {
                            Image(systemName: comparison > 0 ? "arrow.up" : "arrow.down")
                                .font(.caption)
                                .accessibilityLabel(comparison > 0 ? "Up" : "Down")
                            Text("\(Int(abs(comparison) * 100))% vs \(comparisonLabel)")
                                .font(.caption)
                        }
                        .foregroundStyle(.white.opacity(0.7))
                    }

                    if transactionCount > 0 {
                        Text("\(transactionCount) transactions")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(periodTitle): \(totalSpent), \(transactionCount) transactions")
    }

    private var comparisonLabel: String {
        switch period {
        case .day: return "yesterday"
        case .week: return "last week"
        case .month: return "last month"
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        SpendingHeroCard(
            period: .day,
            totalSpent: "$128.48",
            averageAmount: "$95.00",
            comparisonPercentage: 0.15,
            transactionCount: 7
        )

        SpendingHeroCard(
            period: .week,
            totalSpent: "$765.96",
            comparisonPercentage: -0.08,
            transactionCount: 44
        )

        SpendingHeroCard(
            period: .month,
            totalSpent: "$3,192.96",
            comparisonPercentage: 0.12,
            transactionCount: 145
        )
    }
    .padding()
    .background(Color(uiColor: .systemGroupedBackground))
}
