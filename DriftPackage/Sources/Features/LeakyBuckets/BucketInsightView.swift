import SwiftUI
import Core
import UI

/// Streaming insight card that displays AI-generated or template insights for a leaky bucket
struct BucketInsightView: View {
    let bucket: LeakyBucket
    let insightStream: AsyncStream<BucketInsightInfo>

    @State private var currentInsight: BucketInsightInfo?
    @State private var isLoading = true

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                HStack {
                    Image(systemName: "lightbulb")
                        .foregroundStyle(DriftPalette.sunset)
                    Text("Insight")
                        .font(.system(size: 16, weight: .semibold, design: .serif))
                        .foregroundStyle(DriftPalette.ink)
                }

                if isLoading {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        ShimmerView()
                            .frame(height: 14)
                        ShimmerView()
                            .frame(width: 200, height: 14)
                    }
                    .padding(.vertical, DesignTokens.Spacing.xs)
                } else if let insight = currentInsight {
                    Text(insight.insightText)
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundStyle(DriftPalette.muted)
                        .contentTransition(.opacity)

                    if let action = insight.actionSuggestion, !action.isEmpty {
                        HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
                            Image(systemName: "arrow.right.circle")
                                .font(.caption)
                                .foregroundStyle(DriftPalette.sage)
                                .padding(.top, 2)

                            Text(action)
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundStyle(DriftPalette.ink)
                        }
                        .padding(.top, DesignTokens.Spacing.xs)
                    }

                    if let alt = insight.alternativeUse, !alt.isEmpty {
                        HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
                            Image(systemName: "lightbulb.min")
                                .font(.caption)
                                .foregroundStyle(DriftPalette.sunset)
                                .padding(.top, 2)

                            Text(alt)
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundStyle(DriftPalette.muted)
                        }
                        .padding(.top, DesignTokens.Spacing.xxs)
                    }
                }
            }
        }
        .animation(DesignTokens.Animation.spring, value: isLoading)
        .task {
            for await insight in insightStream {
                withAnimation(DesignTokens.Animation.spring) {
                    currentInsight = insight
                    if !insight.insightText.isEmpty {
                        isLoading = false
                    }
                }
            }
            if currentInsight == nil {
                isLoading = false
            }
        }
    }
}
