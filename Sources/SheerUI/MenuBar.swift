import SwiftUI

// MARK: - Status item labels

public struct MenuBarLabel: View {
    var systemImage: String?
    var value: Text?
    var attention: Bool
    var reserve: Text?

    public init(systemImage: String? = nil, value: Text? = nil, attention: Bool = false, reserve: Text? = nil) {
        self.systemImage = systemImage
        self.value = value
        self.attention = attention
        self.reserve = reserve
    }

    public var body: some View {
        HStack(spacing: 4) {
            if let systemImage { Image(systemName: systemImage) }
            if value != nil || reserve != nil {
                ZStack(alignment: .trailing) {
                    reserve.hidden()
                    value
                }
            }
        }
        .font(.system(size: 12, weight: .medium))
        .monospacedDigit()
        .foregroundStyle(attention ? AnyShapeStyle(Color(nsColor: .systemOrange)) : AnyShapeStyle(.primary))
        .fixedSize()
        .accessibilityElement(children: .combine)
    }
}

/// Two readings stacked in the height of one menu bar line, such as a rate in and a rate out, each
/// right aligned in the width of its reserve so the item never changes width as the numbers move.
public struct MenuBarStack: View {
    let top: Text
    let bottom: Text
    let reserve: Text
    var attention: Bool

    public init(top: Text, bottom: Text, reserve: Text, attention: Bool = false) {
        self.top = top
        self.bottom = bottom
        self.reserve = reserve
        self.attention = attention
    }

    public var body: some View {
        VStack(alignment: .trailing, spacing: -1) {
            line(top)
            line(bottom)
        }
        .font(.system(size: 9, weight: .medium))
        .monospacedDigit()
        .foregroundStyle(attention ? AnyShapeStyle(Color(nsColor: .systemOrange)) : AnyShapeStyle(.primary))
        .fixedSize()
        .accessibilityElement(children: .combine)
    }

    private func line(_ text: Text) -> some View {
        ZStack(alignment: .trailing) {
            reserve.hidden()
            text
        }
    }
}

/// A level as a short upright bar beside a caption read down its side, the way a fuel gauge reads
/// at a glance: how full a disk is, how busy the processor is.
public struct MenuBarLevel: View {
    let caption: String
    let fraction: Double
    var attention: Bool

    public init(caption: String, fraction: Double, attention: Bool = false) {
        self.caption = caption
        self.fraction = fraction
        self.attention = attention
    }

    public var body: some View {
        HStack(spacing: 2) {
            VStack(spacing: -2) {
                ForEach(Array(caption.uppercased().enumerated()), id: \.offset) { _, letter in
                    Text(String(letter))
                }
            }
            .font(.system(size: 6, weight: .bold))
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .strokeBorder(.primary.opacity(0.55), lineWidth: 1)
                RoundedRectangle(cornerRadius: 1, style: .continuous)
                    .fill(attention ? AnyShapeStyle(Color(nsColor: .systemOrange)) : AnyShapeStyle(.primary))
                    .frame(height: max(1, 12 * clampedFraction(fraction)))
                    .padding(2)
            }
            .frame(width: 7, height: 16)
        }
        .fixedSize()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(caption))
        .accessibilityValue(Text(clampedFraction(fraction), format: .percent))
    }
}

// MARK: - Popover panel

/// The popover of a status item: its sections as separate cards on the popover's own material, so
/// each reading is a block the eye lands on rather than a run of lines.
public struct MenuBarPanel<Content: View>: View {
    @ViewBuilder let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Group(subviews: content) { sections in
                ForEach(sections) { section in
                    section
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.menuCard, in: .rect(cornerRadius: 12, style: .continuous))
                }
            }
        }
        .padding(8)
        .frame(width: 300)
        .font(.rowMeta)
        .monospacedDigit()
    }
}

/// One card of a panel, under a name in the accent color so a panel of several cards reads as a
/// stack of named parts. The trailing slot holds column titles or one small command.
public struct MenuBarSection<Trailing: View, Content: View>: View {
    let title: Text
    @ViewBuilder let trailing: Trailing
    @ViewBuilder let content: Content

    public init(title: Text, @ViewBuilder trailing: () -> Trailing, @ViewBuilder content: () -> Content) {
        self.title = title
        self.trailing = trailing()
        self.content = content()
    }

    public init(title: LocalizedStringKey, @ViewBuilder trailing: () -> Trailing, @ViewBuilder content: () -> Content) {
        self.init(title: Text(title), trailing: trailing, content: content)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                title
                    .font(.rowMeta.weight(.semibold))
                    .foregroundStyle(.tint)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 8)
                trailing
                    .font(.rowMeta)
                    .foregroundStyle(.secondary)
            }
            content
        }
    }
}

extension MenuBarSection where Trailing == EmptyView {
    public init(title: Text, @ViewBuilder content: () -> Content) {
        self.init(title: title, trailing: { EmptyView() }, content: content)
    }

    public init(title: LocalizedStringKey, @ViewBuilder content: () -> Content) {
        self.init(title: Text(title), content: content)
    }
}

/// The headline card of a panel: a ring for how full or busy the thing is with its whole percent
/// inside, the thing's name, and its reading in words.
public struct MenuBarHeadline<Trailing: View>: View {
    let title: Text
    let value: Text
    let fraction: Double?
    var warning: Bool
    @ViewBuilder let trailing: Trailing

    public init(title: Text, value: Text, fraction: Double?, warning: Bool = false, @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.value = value
        self.fraction = fraction
        self.warning = warning
        self.trailing = trailing()
    }

    public var body: some View {
        HStack(spacing: 12) {
            if let fraction {
                MenuBarRing(fraction: fraction, warning: warning)
            }
            VStack(alignment: .leading, spacing: 1) {
                title.font(.rowTitle).foregroundStyle(.secondary)
                value
                    .font(.title3.weight(.medium))
                    .foregroundStyle(warning ? ChartPalette.color(2) : AnyShapeStyle(.primary))
                    .contentTransition(.numericText())
            }
            .lineLimit(1)
            Spacer(minLength: 8)
            trailing
        }
        .accessibilityElement(children: .combine)
    }
}

extension MenuBarHeadline where Trailing == EmptyView {
    public init(title: Text, value: Text, fraction: Double?, warning: Bool = false) {
        self.init(title: title, value: value, fraction: fraction, warning: warning, trailing: { EmptyView() })
    }

    public init(title: LocalizedStringKey, value: Text, fraction: Double?, warning: Bool = false) {
        self.init(title: Text(title), value: value, fraction: fraction, warning: warning)
    }
}

struct MenuBarRing: View {
    let fraction: Double
    let warning: Bool

    var body: some View {
        ZStack {
            Circle().stroke(.controlFill, lineWidth: 4)
            Circle()
                .trim(from: 0, to: clampedFraction(fraction))
                .stroke(warning ? ChartPalette.color(2) : ChartPalette.color(0), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text(Int((clampedFraction(fraction) * 100).rounded()), format: .number)
                .font(.system(size: 13, weight: .semibold))
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .frame(width: 40, height: 40)
        .accessibilityHidden(true)
    }
}

/// Two or three readings side by side above the chart they belong to, each centered over its name
/// and the dot of its series color, so a reading and its line in the chart are matched by color.
public struct MenuBarReadings: View {
    let readings: [MenuBarReading]

    public init(_ readings: [MenuBarReading]) {
        self.readings = readings
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 8) {
            ForEach(readings.indices, id: \.self) { index in
                let reading = readings[index]
                VStack(spacing: 2) {
                    reading.value
                        .font(.title3.weight(.medium))
                        .foregroundStyle(reading.warning ? ChartPalette.color(2) : AnyShapeStyle(.primary))
                        .contentTransition(.numericText())
                    HStack(spacing: 4) {
                        if let slot = reading.slot {
                            Circle().fill(ChartPalette.color(slot)).frame(width: 7, height: 7)
                        }
                        reading.label.foregroundStyle(.secondary)
                    }
                }
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
            }
        }
    }
}

public struct MenuBarReading {
    let label: Text
    let value: Text
    let slot: Int?
    let warning: Bool

    public init(label: Text, value: Text, slot: Int? = nil, warning: Bool = false) {
        self.label = label
        self.value = value
        self.slot = slot
        self.warning = warning
    }

    public init(label: LocalizedStringKey, value: Text, slot: Int? = nil, warning: Bool = false) {
        self.init(label: Text(label), value: value, slot: slot, warning: warning)
    }
}

/// A name with its value right aligned, and optionally a bar for how full or busy it is between
/// them, so a card of rows reads down two columns.
public struct MenuBarRow: View {
    let label: Text
    let value: Text?
    let fraction: Double?
    var warning: Bool
    var open: (() -> Void)?

    public init(label: Text, value: Text? = nil, fraction: Double? = nil, warning: Bool = false, open: (() -> Void)? = nil) {
        self.label = label
        self.value = value
        self.fraction = fraction
        self.warning = warning
        self.open = open
    }

    public init(_ label: LocalizedStringKey, value: Text? = nil, fraction: Double? = nil, warning: Bool = false, open: (() -> Void)? = nil) {
        self.init(label: Text(label), value: value, fraction: fraction, warning: warning, open: open)
    }

    public var body: some View {
        if let open {
            Button(action: open) { content }
                .buttonStyle(MenuBarRowButtonStyle())
        } else {
            content
        }
    }

    private var content: some View {
        HStack(spacing: 10) {
            label
                .foregroundStyle(.primary)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer(minLength: 8)
            if let fraction {
                Meter(value: fraction, warning: warning).frame(width: 72)
            }
            if let value {
                value
                    .foregroundStyle(warning && fraction == nil ? ChartPalette.color(2) : AnyShapeStyle(.secondary))
                    .lineLimit(1)
                    .contentTransition(.numericText())
                    .layoutPriority(1)
            }
        }
        .frame(minHeight: 20)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}

/// A short table of the things using a resource, such as the apps reading and writing a disk: each
/// row its icon and name, then one right aligned column per measure, titled in the section's
/// trailing slot through `MenuBarColumns`.
public struct MenuBarTable<Data: RandomAccessCollection>: View where Data.Element: Identifiable {
    let data: Data
    let row: (Data.Element) -> MenuBarTableRow

    public init(_ data: Data, row: @escaping (Data.Element) -> MenuBarTableRow) {
        self.data = data
        self.row = row
    }

    public var body: some View {
        VStack(spacing: 2) {
            ForEach(data) { element in
                let item = row(element)
                let line = HStack(spacing: 8) {
                    if let artwork = item.artwork {
                        ArtworkView(artwork, size: 18)
                    }
                    Text(item.title)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer(minLength: 8)
                    ForEach(item.values.indices, id: \.self) { index in
                        Text(item.values[index])
                            .foregroundStyle(.secondary)
                            .frame(width: MenuBarColumns.width, alignment: .trailing)
                            .contentTransition(.numericText())
                    }
                }
                .frame(minHeight: 22)
                .contentShape(.rect)
                .accessibilityElement(children: .combine)
                if let open = item.open {
                    Button(action: open) { line }.buttonStyle(MenuBarRowButtonStyle())
                } else {
                    line
                }
            }
        }
    }
}

public struct MenuBarTableRow {
    let artwork: Artwork?
    let title: String
    let values: [String]
    let open: (() -> Void)?

    public init(artwork: Artwork? = nil, title: String, values: [String], open: (() -> Void)? = nil) {
        self.artwork = artwork
        self.title = title
        self.values = values
        self.open = open
    }
}

/// The column titles of a `MenuBarTable`, set in its section's trailing slot so they sit on the
/// section's name line, each right aligned over its column.
public struct MenuBarColumns: View {
    static let width: CGFloat = 64
    let titles: [Text]

    public init(_ titles: [Text]) {
        self.titles = titles
    }

    public var body: some View {
        HStack(spacing: 8) {
            ForEach(titles.indices, id: \.self) { index in
                titles[index].frame(width: Self.width, alignment: .trailing)
            }
        }
    }
}

/// The figures under a chart, such as its peak, at either end of one quiet line.
public struct MenuBarFootnote: View {
    let leading: Text
    let trailing: Text?

    public init(leading: Text, trailing: Text? = nil) {
        self.leading = leading
        self.trailing = trailing
    }

    public var body: some View {
        HStack {
            leading
            Spacer(minLength: 8)
            trailing
        }
        .foregroundStyle(.secondary)
        .contentTransition(.numericText())
    }
}

/// The last card of a panel: the commands that leave the popover, the first of them the page the
/// panel summarizes.
public struct MenuBarCommands<Content: View>: View {
    @ViewBuilder let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        HStack(spacing: 8) {
            content
                .buttonStyle(.capsule)
            Spacer(minLength: 0)
        }
    }
}

private struct MenuBarRowButtonStyle: ButtonStyle {
    @State private var hovering = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 4)
            .background(
                configuration.isPressed ? AnyShapeStyle(.selectedFill) : hovering ? AnyShapeStyle(.hoverFill) : AnyShapeStyle(.clear),
                in: .rect(cornerRadius: 6, style: .continuous)
            )
            .padding(.horizontal, -4)
            .onHover { hovering = $0 }
    }
}

extension ShapeStyle where Self == Color {
    /// A card of a menu bar panel: lifted off the popover's material in light and dark alike.
    static var menuCard: Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .vibrantDark]) != nil
                ? NSColor.white.withAlphaComponent(0.07)
                : NSColor.white.withAlphaComponent(0.72)
        })
    }
}
