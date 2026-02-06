import SwiftUI

/// A reusable shimmer/skeleton loading effect
public struct ShimmerView: View {
    @State private var phase: CGFloat = -1

    private let cornerRadius: CGFloat

    public init(cornerRadius: CGFloat = DesignTokens.CornerRadius.sm) {
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(DriftPalette.chip)
            .overlay {
                GeometryReader { geo in
                    let width = geo.size.width
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .white.opacity(0.3), location: 0.5),
                            .init(color: .clear, location: 1)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: width * 0.6)
                    .offset(x: width * phase)
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            }
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    phase = 1.5
                }
            }
    }
}

// MARK: - Spending Shimmer Skeletons

/// Skeleton loading state for the SpendingView hero card area
public struct SpendingHeroShimmer: View {
    public init() {}

    public var body: some View {
        GlassCard {
            VStack(spacing: DesignTokens.Spacing.md) {
                ShimmerView()
                    .frame(width: 100, height: 14)

                ShimmerView(cornerRadius: DesignTokens.CornerRadius.md)
                    .frame(width: 180, height: 48)

                HStack(spacing: DesignTokens.Spacing.lg) {
                    ShimmerView()
                        .frame(width: 80, height: 14)
                    ShimmerView()
                        .frame(width: 80, height: 14)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignTokens.Spacing.lg)
        }
    }
}

/// Skeleton loading state for the chart area
public struct ChartShimmer: View {
    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            ShimmerView()
                .frame(width: 140, height: 16)

            GlassCard {
                HStack(alignment: .bottom, spacing: DesignTokens.Spacing.sm) {
                    ForEach(0..<7, id: \.self) { index in
                        ShimmerView(cornerRadius: 4)
                            .frame(height: barHeight(for: index))
                    }
                }
                .frame(height: 150)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func barHeight(for index: Int) -> CGFloat {
        let heights: [CGFloat] = [60, 90, 45, 120, 80, 100, 50]
        return heights[index % heights.count]
    }
}

/// Skeleton loading state for category breakdown list
public struct CategoryListShimmer: View {
    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            ShimmerView()
                .frame(width: 100, height: 12)

            ForEach(0..<4, id: \.self) { _ in
                GlassCard(padding: DesignTokens.Spacing.sm) {
                    HStack(spacing: DesignTokens.Spacing.md) {
                        ShimmerView(cornerRadius: DesignTokens.CornerRadius.pill)
                            .frame(width: 36, height: 36)

                        VStack(alignment: .leading, spacing: 6) {
                            ShimmerView()
                                .frame(width: 100, height: 14)
                            ShimmerView()
                                .frame(height: 4)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            ShimmerView()
                                .frame(width: 60, height: 14)
                            ShimmerView()
                                .frame(width: 30, height: 10)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Leaky Buckets Shimmer Skeletons

/// Skeleton loading state for the LeakyBuckets summary card
public struct LeakySummaryShimmer: View {
    public init() {}

    public var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        ShimmerView()
                            .frame(width: 120, height: 12)
                        ShimmerView(cornerRadius: DesignTokens.CornerRadius.md)
                            .frame(width: 100, height: 28)
                        ShimmerView()
                            .frame(width: 80, height: 12)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 6) {
                        ShimmerView()
                            .frame(width: 70, height: 16)
                        ShimmerView()
                            .frame(width: 60, height: 12)
                    }
                }
            }
        }
    }
}

/// Skeleton loading state for bucket list items
public struct BucketListShimmer: View {
    public init() {}

    public var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            ForEach(0..<3, id: \.self) { _ in
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    HStack {
                        ShimmerView(cornerRadius: DesignTokens.CornerRadius.pill)
                            .frame(width: 36, height: 36)

                        VStack(alignment: .leading, spacing: 4) {
                            ShimmerView()
                                .frame(width: 120, height: 16)
                            ShimmerView()
                                .frame(width: 80, height: 12)
                        }
                        Spacer()
                    }

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            ShimmerView()
                                .frame(width: 70, height: 22)
                            ShimmerView()
                                .frame(width: 50, height: 12)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            ShimmerView()
                                .frame(width: 60, height: 16)
                            ShimmerView()
                                .frame(width: 40, height: 12)
                        }
                    }
                }
                .padding(DesignTokens.Spacing.cardPadding)
                .background(Color(.systemBackground).opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.card))
            }
        }
    }
}

// MARK: - Staggered Appearance Modifier

/// Modifier that animates a view appearing with a stagger delay
struct StaggeredAppearModifier: ViewModifier {
    let index: Int
    let staggerDelay: Double

    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .animation(
                DesignTokens.Animation.spring.delay(Double(index) * staggerDelay),
                value: appeared
            )
            .onAppear {
                appeared = true
            }
    }
}

public extension View {
    /// Animates the view in with a stagger based on its index
    func staggeredAppear(index: Int, delay: Double = 0.05) -> some View {
        modifier(StaggeredAppearModifier(index: index, staggerDelay: delay))
    }
}

#Preview("Shimmer Views") {
    ScrollView {
        VStack(spacing: 24) {
            SpendingHeroShimmer()
            ChartShimmer()
            CategoryListShimmer()

            Divider()

            LeakySummaryShimmer()
            BucketListShimmer()
        }
        .padding()
    }
    .background(DriftBackground())
}
