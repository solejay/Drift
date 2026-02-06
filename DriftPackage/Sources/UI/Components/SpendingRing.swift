import SwiftUI
import Core

/// A ring chart showing spending by category
public struct SpendingRing: View {
    private let categories: [CategoryData]
    private let size: CGFloat
    private let lineWidth: CGFloat
    private let showLabels: Bool

    public struct CategoryData: Identifiable {
        public let id: UUID
        public let category: SpendingCategory
        public let amount: Decimal
        public let percentage: Double

        public init(
            id: UUID = UUID(),
            category: SpendingCategory,
            amount: Decimal,
            percentage: Double
        ) {
            self.id = id
            self.category = category
            self.amount = amount
            self.percentage = percentage
        }
    }

    public init(
        categories: [CategoryData],
        size: CGFloat = 200,
        lineWidth: CGFloat = 24,
        showLabels: Bool = true
    ) {
        self.categories = categories
        self.size = size
        self.lineWidth = lineWidth
        self.showLabels = showLabels
    }

    @State private var animateRing = false

    public var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(DriftPalette.chip, lineWidth: lineWidth)

            // Category segments
            ForEach(Array(categories.enumerated()), id: \.element.id) { index, data in
                RingSegment(
                    startAngle: startAngle(for: index),
                    endAngle: animateRing ? endAngle(for: index) : startAngle(for: index),
                    color: DesignTokens.Colors.category(data.category.rawValue),
                    lineWidth: lineWidth
                )
            }

            // Center content
            if showLabels {
                VStack(spacing: 4) {
                    Text(totalAmount)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(DriftPalette.ink)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    Text("Total")
                        .font(.caption)
                        .foregroundStyle(DriftPalette.muted)
                }
                .opacity(animateRing ? 1 : 0)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(DesignTokens.Animation.bouncy) {
                animateRing = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Spending ring chart, total \(totalAmount)")
    }

    private func startAngle(for index: Int) -> Angle {
        let previousPercentages = categories.prefix(index).map(\.percentage).reduce(0, +)
        return .degrees(previousPercentages * 360 - 90)
    }

    private func endAngle(for index: Int) -> Angle {
        let previousPercentages = categories.prefix(index + 1).map(\.percentage).reduce(0, +)
        return .degrees(previousPercentages * 360 - 90)
    }

    private var totalAmount: String {
        let total = categories.map(\.amount).reduce(0, +)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: total as NSDecimalNumber) ?? "$0"
    }
}

/// A single segment of the ring
private struct RingSegment: View {
    let startAngle: Angle
    let endAngle: Angle
    let color: Color
    let lineWidth: CGFloat

    var body: some View {
        Circle()
            .trim(from: trimStart, to: trimEnd)
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            .rotationEffect(.degrees(-90))
    }

    private var trimStart: CGFloat {
        CGFloat((startAngle.degrees + 90) / 360)
    }

    private var trimEnd: CGFloat {
        CGFloat((endAngle.degrees + 90) / 360)
    }
}

/// Legend for the spending ring
public struct SpendingRingLegend: View {
    private let categories: [SpendingRing.CategoryData]

    public init(categories: [SpendingRing.CategoryData]) {
        self.categories = categories
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(categories) { data in
                HStack(spacing: 8) {
                    Circle()
                        .fill(DesignTokens.Colors.category(data.category.rawValue))
                        .frame(width: 8, height: 8)

                    Text(data.category.displayName)
                        .font(.subheadline)

                    Spacer()

                    Text("\(Int(data.percentage * 100))%")
                        .font(.subheadline)
                        .foregroundStyle(DriftPalette.muted)
                        .monospacedDigit()
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        SpendingRing(categories: [
            .init(category: .food, amount: 350, percentage: 0.35),
            .init(category: .transport, amount: 150, percentage: 0.15),
            .init(category: .shopping, amount: 200, percentage: 0.20),
            .init(category: .entertainment, amount: 100, percentage: 0.10),
            .init(category: .subscriptions, amount: 200, percentage: 0.20),
        ])

        SpendingRingLegend(categories: [
            .init(category: .food, amount: 350, percentage: 0.35),
            .init(category: .transport, amount: 150, percentage: 0.15),
            .init(category: .shopping, amount: 200, percentage: 0.20),
        ])
        .padding()
    }
    .padding()
}
