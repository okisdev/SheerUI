import SwiftUI

func clampedFraction(_ value: Double) -> Double {
    value.isNaN ? 0 : min(max(value, 0), 1)
}

func nonnegativeValue(_ value: Double) -> Double {
    value.isFinite ? max(0, value) : 0
}

public struct Meter: View {
    private let value: Double
    private let warning: Bool

    public init(value: Double, warning: Bool = false) {
        self.value = value
        self.warning = warning
    }

    public var body: some View {
        GeometryReader { geometry in
            Capsule()
                .fill(warning ? ChartPalette.color(2) : ChartPalette.color(0))
                .frame(width: geometry.size.width * clampedFraction(value))
        }
        .frame(height: 4)
        .background(.controlFill, in: .capsule)
        .clipShape(.capsule)
        .accessibilityElement(children: .ignore)
        .accessibilityValue(Text(clampedFraction(value), format: .percent))
    }
}

public struct ShareBar: View {
    private let fraction: Double

    public init(fraction: Double) {
        self.fraction = fraction
    }

    public var body: some View {
        Meter(value: fraction).frame(width: 80)
    }
}

public struct CapacityPart {
    public var name: Text
    public var slot: Int
    public var value: Double

    public init(name: Text, slot: Int, value: Double) {
        self.name = name
        self.slot = slot
        self.value = value
    }

    public init(name: LocalizedStringKey, slot: Int, value: Double) {
        self.init(name: Text(name), slot: slot, value: value)
    }
}

struct CapacitySegment: Identifiable {
    let id: Int
    let slot: Int?
    let value: Double

    var style: AnyShapeStyle {
        slot.map(ChartPalette.color) ?? AnyShapeStyle(.secondary)
    }

    static func folded(_ parts: [CapacityPart]) -> [Self] {
        let visible = parts.enumerated().filter { nonnegativeValue($0.element.value) > 0 }
        var segments = visible.prefix(8).map { Self(id: $0.offset, slot: $0.element.slot, value: nonnegativeValue($0.element.value)) }
        let remainder = visible.dropFirst(8).reduce(0) { $0 + nonnegativeValue($1.element.value) }
        if remainder > 0 {
            segments.append(Self(id: parts.count, slot: nil, value: remainder))
        }
        return segments
    }

    static func fractions(_ segments: [Self], total: Double) -> [Double] {
        let used = segments.reduce(0) { $0 + $1.value }
        let limit = max(nonnegativeValue(total), used)
        return segments.map { limit > 0 ? clampedFraction($0.value / limit) : 0 }
    }
}

public struct CapacityBar: View {
    private let parts: [CapacityPart]
    private let total: Double

    public init(parts: [CapacityPart], total: Double) {
        self.parts = parts
        self.total = total
    }

    public var body: some View {
        let segments = CapacitySegment.folded(parts)
        let fractions = CapacitySegment.fractions(segments, total: total)
        GeometryReader { geometry in
            let gap = min(1, geometry.size.width / CGFloat(max(segments.count - 1, 1)))
            let available = max(0, geometry.size.width - gap * CGFloat(max(segments.count - 1, 0)))
            HStack(spacing: gap) {
                ForEach(Array(zip(segments, fractions)), id: \.0.id) { segment, fraction in
                    Rectangle()
                        .fill(segment.style)
                        .frame(width: available * fraction)
                }
            }
        }
        .frame(height: 8)
        .background(.controlFill, in: .capsule)
        .clipShape(.capsule)
        .accessibilityElement(children: .ignore)
        .accessibilityValue(Text(clampedFraction(parts.reduce(0) { $0 + nonnegativeValue($1.value) } / total), format: .percent))
    }
}

/// Every part keeps its name; parts folded into the bar's overflow segment use a neutral dot.
public struct CapacityLegend: View {
    private let parts: [CapacityPart]
    private let format: (Double) -> String

    public init(parts: [CapacityPart], format: @escaping (Double) -> String) {
        self.parts = parts
        self.format = format
    }

    public var body: some View {
        let colored = Set(CapacitySegment.folded(parts).filter { $0.slot != nil }.map(\.id))
        VStack(spacing: 8) {
            ForEach(Array(parts.enumerated()), id: \.offset) { index, part in
                HStack(spacing: 8) {
                    Circle()
                        .fill(colored.contains(index) ? ChartPalette.color(part.slot) : AnyShapeStyle(.secondary))
                        .frame(width: 6, height: 6)
                        .accessibilityHidden(true)
                    part.name
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    Text(format(nonnegativeValue(part.value)))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .font(.rowMeta)
    }
}
