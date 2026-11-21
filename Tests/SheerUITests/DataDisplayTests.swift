import Foundation
import SwiftUI
import Testing

@testable import SheerUI

struct DataDisplayTests {
    @Test func stackedScaleUsesTheLargestColumnSum() {
        let scale = SampleChartScale(values: [[8, 2], [3, 9]], mode: .stacked, ceiling: nil, minimumPeak: 1)
        #expect(scale.domain == 0...12)
    }

    @Test func quietChartUsesTheMinimumPeak() {
        let scale = SampleChartScale(values: [[2, 3]], mode: .stacked, ceiling: nil, minimumPeak: 20)
        #expect(scale.domain == 0...20)
    }

    @Test func fixedCeilingKeepsTheNaturalScale() {
        let scale = SampleChartScale(values: [[20], [150]], mode: .stacked, ceiling: 100, minimumPeak: 200)
        #expect(scale.domain == 0...100)
    }

    @Test func emptyAndZeroChartsKeepANonzeroScale() {
        #expect(SampleChartScale(values: [], mode: .stacked, ceiling: nil, minimumPeak: 0).domain == 0...1)
        #expect(SampleChartScale(values: [[0, 0]], mode: .mirrored, ceiling: nil, minimumPeak: 10).domain == -5...5)
    }

    @Test func mirroredSidesUseTheirOwnPeaksOnACommonScale() {
        let scale = SampleChartScale(values: [[80, 5, 5], [20, 10, 10]], mode: .mirrored, ceiling: nil, minimumPeak: 1)
        #expect(scale.domain == -20...80)
    }

    @Test func mirroredFloorPreservesThePeakRatio() {
        let scale = SampleChartScale(values: [[30, 10]], mode: .mirrored, ceiling: nil, minimumPeak: 100)
        #expect(scale.domain == -25...75)
    }

    @Test func mirroredChartWithOneQuietSideKeepsTheOtherSideVisible() {
        #expect(SampleChartScale(values: [[0, 20]], mode: .mirrored, ceiling: nil, minimumPeak: 1).domain == -20...0)
        #expect(SampleChartScale(values: [[20, 0]], mode: .mirrored, ceiling: nil, minimumPeak: 1).domain == 0...20)
    }

    @Test func chartAlignsDatesAndBuildsExplicitStacks() throws {
        let first = Date(timeIntervalSinceReferenceDate: 10)
        let last = first.addingTimeInterval(1)
        let series = [
            ChartSeries(name: Text(verbatim: "A"), slot: 0, points: [(last, 4), (first, 3), (first, 2)]),
            ChartSeries(name: Text(verbatim: "B"), slot: 1, points: [(first, 7)])
        ]
        let data = SampleChartData(series: series, mode: .stacked, ceiling: nil, minimumPeak: 1)
        #expect(data.columns.map(\.date) == [first, last])
        #expect(data.columns.map(\.values) == [[5, 7], [4, 0]])
        #expect(data.scale.domain == 0...12)
        let stacked = try #require(data.bars.first { $0.id.date == first && $0.series == 1 })
        #expect(stacked.lower == 5)
        #expect(stacked.upper == 12)
        #expect(data.nearest(to: last.addingTimeInterval(-0.2))?.date == last)
    }

    @Test(arguments: [1.0, 86_400.0]) func chartSpacingWorksForSecondsAndDays(interval: Double) {
        let first = Date(timeIntervalSinceReferenceDate: 0)
        let last = first.addingTimeInterval(interval)
        let series = [ChartSeries(name: Text(verbatim: "A"), slot: 0, points: [(first, 10), (last, 20)])]
        let data = SampleChartData(series: series, mode: .stacked, ceiling: nil, minimumPeak: 1)
        let width = data.barWidthFraction * data.domain.upperBound.timeIntervalSince(data.domain.lowerBound)
        #expect(width == interval * 0.75)
        #expect(abs((interval - width) / width - 1 / 3) < 0.000_001)
        #expect(data.domain.upperBound == last.addingTimeInterval(interval / 2))
        #expect(data.barWidthFraction == 0.375)
    }

    @Test func mirroredMarksStackDownward() throws {
        let date = Date(timeIntervalSinceReferenceDate: 0)
        let series = [10.0, 4, 2].enumerated().map {
            ChartSeries(name: Text(verbatim: String($0.offset)), slot: $0.offset, points: [(date, $0.element)])
        }
        let data = SampleChartData(series: series, mode: .mirrored, ceiling: nil, minimumPeak: 1)
        let last = try #require(data.bars.last)
        #expect(last.lower == -6)
        #expect(last.upper == -4)
    }

    @Test func capacityFoldsOnlyPartsBeyondEight() throws {
        let parts = (1...11).map { CapacityPart(name: Text(verbatim: String($0)), slot: $0 - 1, value: Double($0)) }
        let segments = CapacitySegment.folded(parts)
        #expect(segments.count == 9)
        #expect(segments.prefix(8).map(\.slot) == Array(0..<8).map(Optional.some))
        let overflow = try #require(segments.last)
        #expect(overflow.slot == nil)
        #expect(overflow.value == 30)
        #expect(segments.reduce(0) { $0 + $1.value } == 66)
        #expect(CapacitySegment.folded(Array(parts.prefix(8))).count == 8)
    }

    @Test func capacityIgnoresEmptyAndInvalidParts() {
        let parts = [0.0, -1, .nan, .infinity, 5].enumerated().map {
            CapacityPart(name: Text(verbatim: String($0.offset)), slot: $0.offset, value: $0.element)
        }
        #expect(CapacitySegment.folded(parts).map(\.value) == [5])
        #expect(CapacitySegment.folded([]).isEmpty)
    }

    @Test func capacityPreservesFreeSpaceAndFitsOverCapacityValues() {
        let segments = [CapacitySegment(id: 0, slot: 0, value: 30), CapacitySegment(id: 1, slot: 1, value: 20)]
        #expect(CapacitySegment.fractions(segments, total: 100) == [0.3, 0.2])
        #expect(CapacitySegment.fractions(segments, total: 40) == [0.6, 0.4])
        #expect(CapacitySegment.fractions(segments, total: 0) == [0.6, 0.4])
        #expect(CapacitySegment.fractions([], total: 0).isEmpty)
    }

    @Test(arguments: zip([-2.0, 0, 0.25, 1, 4, .nan, .infinity, -.infinity], [0.0, 0, 0.25, 1, 1, 0, 1, 0]))
    func fractionsStayWithinTheTrack(value: Double, expected: Double) {
        #expect(clampedFraction(value) == expected)
    }
}
