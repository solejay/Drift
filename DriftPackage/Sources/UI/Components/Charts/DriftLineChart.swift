import SwiftUI
import Charts

/// A line chart with area fill for displaying cumulative spending (Apple Health-style)
public struct DriftLineChart: View {
    let dataPoints: [LineChartDataPoint]
    let currentPointIndex: Int?
    let onTap: ((Int) -> Void)?

    @State private var animateChart = false

    public init(
        dataPoints: [LineChartDataPoint],
        currentPointIndex: Int? = nil,
        onTap: ((Int) -> Void)? = nil
    ) {
        self.dataPoints = dataPoints
        self.currentPointIndex = currentPointIndex
        self.onTap = onTap
    }

    public var body: some View {
        Chart(dataPoints) { point in
            let amount = NSDecimalNumber(decimal: point.amount).doubleValue

            // Area fill below line
            AreaMark(
                x: .value("Time", point.date),
                y: .value("Amount", animateChart ? amount : 0)
            )
            .foregroundStyle(
                .linearGradient(
                    colors: [DriftPalette.accent.opacity(0.3), DriftPalette.accent.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)

            // Line
            LineMark(
                x: .value("Time", point.date),
                y: .value("Amount", animateChart ? amount : 0)
            )
            .foregroundStyle(DriftPalette.accentDeep)
            .lineStyle(StrokeStyle(lineWidth: 2.5))
            .interpolationMethod(.catmullRom)

            // Current point indicator
            if point.isCurrentPeriod && animateChart {
                PointMark(
                    x: .value("Time", point.date),
                    y: .value("Amount", amount)
                )
                .foregroundStyle(DriftPalette.sunsetDeep)
                .symbolSize(100)
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { value in
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(formatTime(date))
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
                        Text(formatCompactCurrency(amount))
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
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onEnded { value in
                                guard let onTap = onTap else { return }
                                let xPosition = value.location.x
                                if let date: Date = proxy.value(atX: xPosition) {
                                    if let index = findNearestIndex(for: date) {
                                        onTap(index)
                                    }
                                }
                            }
                    )
            }
        }
        .onAppear {
            withAnimation(DesignTokens.Animation.bouncy) {
                animateChart = true
            }
        }
    }

    private func findNearestIndex(for date: Date) -> Int? {
        guard !dataPoints.isEmpty else { return nil }

        var nearestIndex = 0
        var minDistance = abs(dataPoints[0].date.timeIntervalSince(date))

        for (index, point) in dataPoints.enumerated() {
            let distance = abs(point.date.timeIntervalSince(date))
            if distance < minDistance {
                minDistance = distance
                nearestIndex = index
            }
        }

        return nearestIndex
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        return formatter.string(from: date).lowercased()
    }

    private func formatCompactCurrency(_ amount: Double) -> String {
        if amount >= 1000 {
            return "$\(Int(amount / 1000))K"
        } else if amount >= 1 {
            return "$\(Int(amount))"
        } else {
            return "$0"
        }
    }
}

// MARK: - Line Chart Data Point

public struct LineChartDataPoint: Identifiable, Hashable {
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
    let points = [0, 6, 9, 12, 15, 18, 21].enumerated().map { index, hour -> LineChartDataPoint in
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = hour
        let date = calendar.date(from: components)!
        let amount = Decimal(Double(index + 1) * 25.0)
        return LineChartDataPoint(
            label: "\(hour)",
            date: date,
            amount: amount,
            isCurrentPeriod: index == 4
        )
    }

    return VStack {
        DriftLineChart(dataPoints: points)
            .frame(height: 200)
            .padding()
    }
}
