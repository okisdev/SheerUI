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
        HStack(spacing: 3) {
            if let systemImage { Image(systemName: systemImage) }
            if value != nil || reserve != nil {
                ZStack(alignment: .leading) {
                    reserve.hidden()
                    value
                }
            }
        }
        .font(.system(size: 12, weight: .medium))
        .monospacedDigit()
        .foregroundStyle(attention ? AnyShapeStyle(Color(nsColor: .systemOrange)) : AnyShapeStyle(.primary))
        .transaction { $0.animation = nil }
        .fixedSize()
        .accessibilityElement(children: .combine)
    }
}

/// Two readings stacked in the height of one menu bar line, such as a rate out over a rate in. The
/// glyphs keep a column of their own and each value is right aligned in the width of the reserve,
/// so neither the glyphs nor the item move as the numbers change.
public struct MenuBarStack: View {
    let top: Text
    let bottom: Text
    let reserve: Text
    let glyphs: (top: String, bottom: String)?
    var attention: Bool

    public init(top: Text, bottom: Text, reserve: Text, glyphs: (top: String, bottom: String)? = nil, attention: Bool = false) {
        self.top = top
        self.bottom = bottom
        self.reserve = reserve
        self.glyphs = glyphs
        self.attention = attention
    }

    public var body: some View {
        HStack(spacing: 3) {
            if let glyphs {
                VStack(spacing: Self.leading) {
                    Text(glyphs.top)
                    Text(glyphs.bottom)
                }
                .font(.system(size: 9, weight: .bold))
            }
            VStack(alignment: .trailing, spacing: Self.leading) {
                line(top)
                line(bottom)
            }
        }
        .font(.system(size: 9.5, weight: .medium))
        .monospacedDigit()
        .foregroundStyle(attention ? AnyShapeStyle(Color(nsColor: .systemOrange)) : AnyShapeStyle(.primary))
        .transaction { $0.animation = nil }
        .fixedSize()
        .accessibilityElement(children: .combine)
    }

    private static let leading: CGFloat = -2

    private func line(_ text: Text) -> some View {
        ZStack(alignment: .trailing) {
            reserve.hidden()
            text
        }
    }
}

/// A level as a short rounded bar beside a caption read down its side, the way a fuel gauge reads at
/// a glance: how full a disk is, how busy the processor is. Several parts stack from the bottom in
/// their chart colors, such as user time under system time.
public struct MenuBarLevel: View {
    let caption: String
    let parts: [Double]
    var attention: Bool

    public init(caption: String, fraction: Double, attention: Bool = false) {
        self.init(caption: caption, parts: [fraction], attention: attention)
    }

    public init(caption: String, parts: [Double], attention: Bool = false) {
        self.caption = caption
        self.parts = parts
        self.attention = attention
    }

    private static let size = CGSize(width: 8, height: 17)
    private static let inset: CGFloat = 1.5

    public var body: some View {
        HStack(spacing: 2) {
            VStack(spacing: -2.5) {
                ForEach(Array(caption.uppercased().enumerated()), id: \.offset) { _, letter in
                    Text(String(letter))
                }
            }
            .font(.system(size: 6.5, weight: .bold))
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .strokeBorder(.primary.opacity(0.5), lineWidth: 1)
                VStack(spacing: 0) {
                    ForEach(Array(parts.enumerated().reversed()), id: \.offset) { index, part in
                        Rectangle()
                            .fill(attention ? AnyShapeStyle(Color(nsColor: .systemOrange)) : ChartPalette.color(index))
                            .frame(height: (Self.size.height - Self.inset * 2) * clampedFraction(part))
                    }
                }
                .frame(height: Self.size.height - Self.inset * 2, alignment: .bottom)
                .clipShape(.rect(cornerRadius: 1.5, style: .continuous))
                .padding(Self.inset)
            }
            .frame(width: Self.size.width, height: Self.size.height)
        }
        .transaction { $0.animation = nil }
        .fixedSize()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(caption))
        .accessibilityValue(Text(clampedFraction(parts.reduce(0, +)), format: .percent))
    }
}

/// A battery drawn at the size of a menu bar glyph with its charge filled in and its percent inside,
/// so the reading costs the width of the icon alone. Charging shows a bolt; a low charge turns orange.
public struct MenuBarBattery: View {
    let percent: Int
    let charging: Bool
    var attention: Bool

    public init(percent: Int, charging: Bool, attention: Bool = false) {
        self.percent = percent
        self.charging = charging
        self.attention = attention
    }

    private static let body = CGSize(width: 24, height: 12)

    public var body: some View {
        let fraction = clampedFraction(Double(percent) / 100)
        HStack(spacing: 1) {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                    .strokeBorder(.primary.opacity(0.45), lineWidth: 1)
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(attention ? AnyShapeStyle(Color(nsColor: .systemOrange)) : AnyShapeStyle(.primary.opacity(0.35)))
                    .frame(width: max(2, (Self.body.width - 4) * fraction))
                    .padding(2)
                HStack(spacing: 0) {
                    if charging {
                        Image(systemName: "bolt.fill").font(.system(size: 7, weight: .bold))
                    }
                    Text(percent, format: .number)
                        .font(.system(size: 8.5, weight: .bold))
                        .monospacedDigit()
                }
                .frame(maxWidth: .infinity)
            }
            .frame(width: Self.body.width, height: Self.body.height)
            Capsule()
                .fill(.primary.opacity(0.45))
                .frame(width: 1.5, height: 4)
        }
        .transaction { $0.animation = nil }
        .fixedSize()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(charging ? Text("Battery, charging", bundle: .module) : Text("Battery", bundle: .module))
        .accessibilityValue(Text(Double(percent) / 100, format: .percent))
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
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(.primary.opacity(0.08), lineWidth: 0.5)
                        }
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

    public init(title: LocalizedStringKey, value: Text, fraction: Double?, warning: Bool = false, @ViewBuilder trailing: () -> Trailing) {
        self.init(title: Text(title), value: value, fraction: fraction, warning: warning, trailing: trailing)
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
                .layoutPriority(fraction == nil ? 2 : 0)
            Spacer(minLength: 8)
            if let fraction {
                Meter(value: fraction, warning: warning).frame(width: 72)
            }
            if let value {
                value
                    .foregroundStyle(warning && fraction == nil ? ChartPalette.color(2) : AnyShapeStyle(.secondary))
                    .lineLimit(1)
                    .truncationMode(.middle)
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
                    item.title
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
    let title: Text
    let values: [String]
    let open: (() -> Void)?

    public init(artwork: Artwork? = nil, title: Text, values: [String], open: (() -> Void)? = nil) {
        self.artwork = artwork
        self.title = title
        self.values = values
        self.open = open
    }

    public init(artwork: Artwork? = nil, title: LocalizedStringKey, values: [String], open: (() -> Void)? = nil) {
        self.init(artwork: artwork, title: Text(title), values: values, open: open)
    }

    /// A row named by data, such as an app's name, shown as is.
    @_disfavoredOverload
    public init(artwork: Artwork? = nil, title: some StringProtocol, values: [String], open: (() -> Void)? = nil) {
        self.init(artwork: artwork, title: Text(title), values: values, open: open)
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

    public init(_ titles: [LocalizedStringKey]) {
        self.init(titles.map { Text($0) })
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
        Color(
            nsColor: NSColor(name: nil) { appearance in
                appearance.bestMatch(from: [.darkAqua, .vibrantDark]) != nil
                    ? NSColor.white.withAlphaComponent(0.07)
                    : NSColor.white.withAlphaComponent(0.72)
            })
    }
}
