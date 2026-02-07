import SwiftUI
import Charts

/// A bar chart for displaying discrete period spending (Week/Month views)
public struct DriftBarChart: View {
    let dataPoints: [BarChartDataPoint]
    let selectedIndex: Int?
    let onSelect: ((Int) -> Void)?

    @State private var animateChart = false

    public init(
        dataPoints: [BarChartDataPoint],
        selectedIndex: Int? = nil,
        onSelect: ((Int) -> Void)? = nil
    ) {
        self.dataPoints = dataPoints
        self.selectedIndex = selectedIndex
        self.onSelect = onSelect
    }

    public var body: some View {
        Chart(Array(dataPoints.enumerated()), id: \.element.id) { index, point in
            BarMark(
                x: .value("Period", point.label),
                y: .value("Amount", animateChart ? NSDecimalNumber(decimal: point.amount).doubleValue : 0)
            )
            .foregroundStyle(barStyle(for: index, point: point))
            .cornerRadius(6)
            .annotation(position: .top, spacing: 4) {
                if selectedIndex == index || (selectedIndex == nil && point.isCurrentPeriod) {
                    Text(formatCompactCurrency(point.amount))
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(DriftPalette.muted)
                        .transition(.opacity)
                }
            }
        }
        .chartYScale(domain: 0...chartMaxAmount)
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let label = value.as(String.self) {
                        Text(label)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(DriftPalette.muted)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                AxisValueLabel {
                    if let amount = value.as(Double.self) {
                        Text(formatCompactCurrency(Decimal(amount)))
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(DriftPalette.muted)
                    }
                }
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                    .foregroundStyle(DriftPalette.track)
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        guard let onSelect = onSelect else { return }
                        let xPosition = location.x
                        if let label: String = proxy.value(atX: xPosition) {
                            if let index = dataPoints.firstIndex(where: { $0.label == label }) {
                                onSelect(index)
                            }
                        }
                    }
            }
        }
        .onAppear {
            withAnimation(DesignTokens.Animation.bouncy) {
                animateChart = true
            }
        }
    }

    private var chartMaxAmount: Double {
        let amounts = dataPoints.map { NSDecimalNumber(decimal: $0.amount).doubleValue }
        return (amounts.max() ?? 100) * 1.15
    }

    private func barStyle(for index: Int, point: BarChartDataPoint) -> AnyShapeStyle {
        if selectedIndex == index || (selectedIndex == nil && point.isCurrentPeriod) {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [DriftPalette.accent, DriftPalette.accentDeep],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        return AnyShapeStyle(DriftPalette.accent.opacity(0.35))
    }

    private func formatCompactCurrency(_ amount: Decimal) -> String {
        let doubleAmount = NSDecimalNumber(decimal: amount).doubleValue
        if doubleAmount >= 1000 {
            return "$\(Int(doubleAmount / 1000))K"
        } else if doubleAmount >= 1 {
            return "$\(Int(doubleAmount))"
        } else {
            return "$0"
        }
    }
}

// MARK: - Bar Chart Data Point

public struct BarChartDataPoint: Identifiable, Hashable {
    public let id: UUID
    public let label: String
    public let date: Date
    public let amount: Decimal
    public let isCurrentPeriod: Bool

    public init(
        id: UUID = UUID(),
        label: String,
        date: Date,
        amount: Decimal,
        isCurrentPeriod: Bool = false
    ) {
        self.id = id
        self.label = label
        self.date = date
        self.amount = amount
        self.isCurrentPeriod = isCurrentPeriod
    }
}

// MARK: - Preview

#Preview {
    let calendar = Calendar.current
    let now = Date()
    let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!

    let points = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"].enumerated().map { index, day -> BarChartDataPoint in
        let date = calendar.date(byAdding: .day, value: index, to: weekStart)!
        let amount = Decimal(Double.random(in: 50...200))
        return BarChartDataPoint(
            label: day,
            date: date,
            amount: amount,
            isCurrentPeriod: index == 3
        )
    }

    return VStack {
        DriftBarChart(dataPoints: points, selectedIndex: nil) { index in
            print("Selected: \(index)")
        }
        .frame(height: 200)
        .padding()
    }
}
