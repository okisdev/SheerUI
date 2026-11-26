import Charts
import SwiftUI

public enum ChartPalette {
    public static func color(_ slot: Int) -> AnyShapeStyle {
        switch (slot % 8 + 8) % 8 {
        case 1: AnyShapeStyle(Color.green)
        case 2: AnyShapeStyle(Color.orange)
        case 3: AnyShapeStyle(Color.purple)
        case 4: AnyShapeStyle(Color.pink)
        case 5: AnyShapeStyle(Color.teal)
        case 6: AnyShapeStyle(Color.yellow)
        case 7: AnyShapeStyle(Color.indigo)
        default: AnyShapeStyle(.tint)
        }
    }
}

public struct ChartSeries {
    public var name: Text
    public var slot: Int
    public var points: [(date: Date, value: Double)]

    public init(name: Text, slot: Int, points: [(date: Date, value: Double)]) {
        self.name = name
        self.slot = slot
        self.points = points
    }

    public init(name: LocalizedStringKey, slot: Int, points: [(date: Date, value: Double)]) {
        self.init(name: Text(name), slot: slot, points: points)
    }
}

public struct SampleChart: View {
    public enum Mode: Sendable {
        case stacked
        /// The first series rises above zero; the remaining series stack below it on the same scale.
        case mirrored
    }

    private let series: [ChartSeries]
    private let mode: Mode
    private let ceiling: Double?
    private let minimumPeak: Double
    private let span: TimeInterval?
    private let height: CGFloat
    private let format: (Double) -> String

    public init(
        series: [ChartSeries], mode: Mode = .stacked, ceiling: Double? = nil, minimumPeak: Double = 1,
        span: TimeInterval? = nil, height: CGFloat = 96, format: @escaping (Double) -> String
    ) {
        self.series = series
        self.mode = mode
        self.ceiling = ceiling
        self.minimumPeak = minimumPeak
        self.span = span
        self.height = height
        self.format = format
    }

    public var body: some View {
        SampleChartPlot(
            series: series, data: SampleChartData(series: series, mode: mode, ceiling: ceiling, minimumPeak: minimumPeak, span: span), format: format
        )
        .frame(height: max(0, height))
        .transaction { $0.animation = nil }
    }
}

struct SampleChartScale {
    let domain: ClosedRange<Double>

    init(values: [[Double]], mode: SampleChart.Mode, ceiling: Double?, minimumPeak: Double) {
        let upperPeak: Double
        let lowerPeak: Double
        switch mode {
        case .stacked:
            upperPeak = values.map { $0.reduce(0) { $0 + nonnegativeValue($1) } }.max() ?? 0
            lowerPeak = 0
        case .mirrored:
            upperPeak = values.map { nonnegativeValue($0.first ?? 0) }.max() ?? 0
            lowerPeak = values.map { $0.dropFirst().reduce(0) { $0 + nonnegativeValue($1) } }.max() ?? 0
        }
        let peak = upperPeak + lowerPeak
        let fixed = ceiling.flatMap { $0.isFinite && $0 > 0 ? $0 : nil }
        let extent = fixed ?? max(peak, nonnegativeValue(minimumPeak))
        let safeExtent = extent > 0 ? extent : 1
        let lowerShare = mode == .mirrored ? (peak > 0 ? lowerPeak / peak : 0.5) : 0
        domain = (-safeExtent * lowerShare)...(safeExtent * (1 - lowerShare))
    }
}

struct SampleChartData {
    struct Column {
        let date: Date
        let values: [Double]
    }

    struct Bar: Identifiable {
        struct ID: Hashable {
            let date: Date
            let series: Int
        }

        let id: ID
        let lower: Double
        let upper: Double
        let value: Double
        let series: Int
    }

    let columns: [Column]
    let bars: [Bar]
    let scale: SampleChartScale
    let domain: ClosedRange<Date>
    let barWidthFraction: Double

    init(series: [ChartSeries], mode: SampleChart.Mode, ceiling: Double?, minimumPeak: Double, span: TimeInterval? = nil) {
        var values: [Date: [Double]] = [:]
        for (index, item) in series.enumerated() {
            for point in item.points where point.date.timeIntervalSinceReferenceDate.isFinite {
                if values[point.date] == nil { values[point.date] = Array(repeating: 0, count: series.count) }
                values[point.date]?[index] += nonnegativeValue(point.value)
            }
        }
        let all = values.keys.sorted().map { Column(date: $0, values: values[$0] ?? []) }
        let dates = all.map(\.date)
        let interval = zip(dates, dates.dropFirst()).map { $1.timeIntervalSince($0) }.min() ?? 1
        let oldest = dates.first ?? Date(timeIntervalSinceReferenceDate: 0)
        let newest = dates.last ?? oldest
        // A bar is centered on its sample, so the window reaches half a bar past the newest sample
        // and only samples whose whole bar fits inside it are drawn: nothing overhangs the plot.
        if let span, span.isFinite && span > 0 {
            let upper = newest.addingTimeInterval(interval / 2)
            domain = upper.addingTimeInterval(-span)...upper
            let firstVisible = domain.lowerBound.addingTimeInterval(interval / 2)
            columns = all.filter { $0.date >= firstVisible }
        } else {
            domain = oldest.addingTimeInterval(-interval / 2)...newest.addingTimeInterval(interval / 2)
            columns = all
        }
        barWidthFraction = interval * 0.75 / domain.upperBound.timeIntervalSince(domain.lowerBound)
        scale = SampleChartScale(values: columns.map(\.values), mode: mode, ceiling: ceiling, minimumPeak: minimumPeak)
        var marks: [Bar] = []
        for column in columns {
            var above = 0.0
            var below = 0.0
            for (index, value) in column.values.enumerated() where value > 0 {
                let mirrored = mode == .mirrored && index > 0
                let lower = mirrored ? below - value : above
                let upper = mirrored ? below : above + value
                marks.append(
                    Bar(
                        id: Bar.ID(date: column.date, series: index), lower: lower, upper: upper, value: value, series: index))
                if mirrored { below = lower } else { above = upper }
            }
        }
        bars = marks
    }

    func barWidth(in plotWidth: CGFloat) -> CGFloat {
        min(24, max(0, plotWidth) * barWidthFraction)
    }

    func nearest(to date: Date) -> Column? {
        columns.min { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }
    }
}

private struct SampleChartPlot: View {
    let series: [ChartSeries]
    let data: SampleChartData
    let format: (Double) -> String
    @State private var hovered: Date?

    var body: some View {
        GeometryReader { size in
            Chart {
                ForEach(data.bars) { bar in
                    let lower = min(max(bar.lower, data.scale.domain.lowerBound), data.scale.domain.upperBound)
                    let upper = min(max(bar.upper, data.scale.domain.lowerBound), data.scale.domain.upperBound)
                    BarMark(
                        x: .value(Text(verbatim: ""), bar.id.date),
                        yStart: .value(series[bar.series].name, lower), yEnd: .value(series[bar.series].name, upper),
                        width: .fixed(data.barWidth(in: size.size.width))
                    )
                    .foregroundStyle(ChartPalette.color(series[bar.series].slot))
                    .accessibilityLabel(series[bar.series].name)
                    .accessibilityValue(Text(format(bar.value)))
                }
                RuleMark(y: .value(Text(verbatim: ""), 0))
                    .foregroundStyle(.hairline)
                    .lineStyle(StrokeStyle(lineWidth: 1))
                    .accessibilityHidden(true)
                if let hovered, let column = data.columns.first(where: { $0.date == hovered }) {
                    RuleMark(x: .value(Text(verbatim: ""), column.date))
                        .foregroundStyle(.hairline)
                        .annotation(position: .top, spacing: 8, overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
                            SampleChartTooltip(series: series, column: column, format: format)
                        }
                        .accessibilityHidden(true)
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartLegend(.hidden)
            .chartXScale(domain: data.domain, range: .plotDimension(padding: 0))
            .chartYScale(domain: data.scale.domain, range: .plotDimension(padding: 0))
            .chartPlotStyle { $0.clipped() }
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(.rect)
                        .onContinuousHover { phase in
                            switch phase {
                            case .active(let point):
                                if let anchor = proxy.plotFrame {
                                    let frame = geometry[anchor]
                                    let date: Date? = proxy.value(atX: point.x - frame.minX)
                                    hovered = frame.contains(point) ? date.flatMap { data.nearest(to: $0)?.date } : nil
                                }
                            case .ended:
                                hovered = nil
                            }
                        }
                        .accessibilityHidden(true)
                }
            }
        }
    }
}

private struct SampleChartTooltip: View {
    let series: [ChartSeries]
    let column: SampleChartData.Column
    let format: (Double) -> String

    var body: some View {
        let entries = column.values.enumerated().filter { $0.element > 0 }.sorted {
            $0.element == $1.element ? $0.offset < $1.offset : $0.element > $1.element
        }
        VStack(alignment: .leading, spacing: 6) {
            Text(column.date, format: .dateTime.month(.abbreviated).day().hour().minute().second())
                .foregroundStyle(.secondary)
            ForEach(entries, id: \.offset) { index, value in
                HStack(spacing: 8) {
                    Circle().fill(ChartPalette.color(series[index].slot)).frame(width: 6, height: 6)
                    series[index].name
                    Spacer(minLength: 8)
                    Text(format(value)).monospacedDigit()
                }
            }
        }
        .font(.rowMeta)
        .padding(10)
        .frame(minWidth: 160, maxWidth: 260)
        .background(.regularMaterial, in: .rect(cornerRadius: 10))
        .overlay { RoundedRectangle(cornerRadius: 10).strokeBorder(.hairline, lineWidth: 1) }
        .allowsHitTesting(false)
    }
}
