import SwiftUI
import UI
import Core

/// Smart chart that switches between Line (Day) and Bar (Week/Month) based on period
public struct SpendingChart: View {
    let period: SpendingPeriod
    let chartData: [ChartDataPoint]
    let selectedIndex: Int?
    let onSelect: ((Int) -> Void)?

    public init(
        period: SpendingPeriod,
        chartData: [ChartDataPoint],
        selectedIndex: Int? = nil,
        onSelect: ((Int) -> Void)? = nil
    ) {
        self.period = period
        self.chartData = chartData
        self.selectedIndex = selectedIndex
        self.onSelect = onSelect
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text(chartTitle)
                .font(.system(size: 16, weight: .semibold, design: .serif))
                .foregroundStyle(DriftPalette.ink)

            GlassCard {
                chartContent
                    .frame(height: 180)
            }
        }
    }

    private var chartTitle: String {
        switch period {
        case .day: return "Today's Spending"
        case .week: return "Daily Breakdown"
        case .month: return "Weekly Breakdown"
        }
    }

    @ViewBuilder
    private var chartContent: some View {
        switch period {
        case .day:
            DriftLineChart(
                dataPoints: chartData.map { point in
                    LineChartDataPoint(
                        id: point.id,
                        label: point.label,
                        date: point.date,
                        amount: point.amount,
                        isCurrentPeriod: point.isCurrentPeriod
                    )
                },
                currentPointIndex: selectedIndex,
                onTap: onSelect
            )

        case .week, .month:
            DriftBarChart(
                dataPoints: chartData.map { point in
                    BarChartDataPoint(
                        id: point.id,
                        label: point.label,
                        date: point.date,
                        amount: point.amount,
                        isCurrentPeriod: point.isCurrentPeriod
                    )
                },
                selectedIndex: selectedIndex,
                onSelect: onSelect
            )
        }
    }
}

#Preview("Day View") {
    let calendar = Calendar.current
    let now = Date()
    let points = [0, 6, 9, 12, 15, 18, 21].enumerated().map { index, hour -> ChartDataPoint in
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = hour
        let date = calendar.date(from: components)!
        let amount = Decimal(Double(index + 1) * 20.0)
        return ChartDataPoint(
            label: "\(hour)",
            date: date,
            amount: amount,
            isCurrentPeriod: index == 4
        )
    }

    return SpendingChart(period: .day, chartData: points)
        .padding()
}

#Preview("Week View") {
    let calendar = Calendar.current
    let now = Date()
    let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!

    let points = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"].enumerated().map { index, day -> ChartDataPoint in
        let date = calendar.date(byAdding: .day, value: index, to: weekStart)!
        let amount = Decimal(Double.random(in: 50...200))
        return ChartDataPoint(
            label: day,
            date: date,
            amount: amount,
            isCurrentPeriod: index == 3
        )
    }

    return SpendingChart(period: .week, chartData: points)
        .padding()
}
