import SwiftUI
import Core

/// Card displaying a detected leaky bucket (recurring expense pattern)
/// Origin-inspired clean design with white cards and subtle shadows
public struct LeakyBucketCard: View {
    private let bucket: LeakyBucket
    private let onTap: (() -> Void)?

    public init(bucket: LeakyBucket, onTap: (() -> Void)? = nil) {
        self.bucket = bucket
        self.onTap = onTap
    }

    public var body: some View {
        Group {
            if let onTap {
                Button {
                    onTap()
                } label: {
                    cardContent
                }
                .buttonStyle(LeakyBucketButtonStyle())
            } else {
                cardContent
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(bucket.merchantName), \(bucket.frequency.displayName), \(bucket.formattedMonthlyImpact) monthly, \(bucket.formattedYearlyImpact) yearly")
        .accessibilityHint(onTap != nil ? "Tap to view details" : "")
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            // Header: Icon + Merchant name + Frequency
            HStack {
                CategoryIcon(category: bucket.category, size: .medium)

                VStack(alignment: .leading, spacing: 2) {
                    Text(bucket.merchantName)
                        .font(.headline)
                        .foregroundStyle(DriftPalette.ink)
                        .lineLimit(1)

                    Text(bucket.frequency.displayName)
                        .font(.caption)
                        .foregroundStyle(DriftPalette.muted)
                }

                Spacer()
            }

            // Amounts: Monthly (prominent, left) / Yearly (secondary, right)
            HStack(alignment: .top) {
                // Monthly amount - primary
                VStack(alignment: .leading, spacing: 4) {
                    Text(bucket.formattedMonthlyImpact)
                        .font(.title2.weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(DriftPalette.ink)
                        .contentTransition(.numericText())

                    Text("Monthly")
                        .font(.caption)
                        .foregroundStyle(DriftPalette.muted)
                }

                Spacer()

                // Yearly amount - secondary
                VStack(alignment: .trailing, spacing: 4) {
                    Text(bucket.formattedYearlyImpact)
                        .font(.body)
                        .monospacedDigit()
                        .foregroundStyle(DriftPalette.muted)
                        .contentTransition(.numericText())

                    Text("Yearly")
                        .font(.caption)
                        .foregroundStyle(DriftPalette.muted.opacity(0.7))
                }
            }
        }
        .padding(DesignTokens.Spacing.cardPadding)
        .background(Color(.systemBackground).opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.card))
        .shadow(DesignTokens.Shadow.small)
    }
}

// MARK: - Button Style

private struct LeakyBucketButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(DesignTokens.Animation.spring, value: configuration.isPressed)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            LeakyBucketCard(bucket: LeakyBucket(
                merchantName: "Starbucks",
                category: .food,
                frequency: .daily,
                averageAmount: 5.50,
                monthlyImpact: 165,
                confidenceScore: 0.92,
                occurrenceCount: 45
            ))

            LeakyBucketCard(bucket: LeakyBucket(
                merchantName: "Netflix",
                category: .subscriptions,
                frequency: .monthly,
                averageAmount: 15.99,
                monthlyImpact: 15.99,
                confidenceScore: 1.0,
                occurrenceCount: 6
            ))

            LeakyBucketCard(bucket: LeakyBucket(
                merchantName: "Uber",
                category: .transport,
                frequency: .weekdays,
                averageAmount: 12.50,
                monthlyImpact: 250,
                confidenceScore: 0.85,
                occurrenceCount: 40
            ))
        }
        .padding()
        .background(DesignTokens.Colors.warmBackground)
    }
}
