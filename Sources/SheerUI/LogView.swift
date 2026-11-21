import SwiftUI

/// One line of output from a process.
public struct LogLine: Identifiable, Sendable {
    public enum Level: Sendable { case normal, warning, error }

    public let id: Int
    public let message: String
    public let timestamp: String
    public let date: Date
    public let source: String
    public let level: Level

    public init(id: Int, message: String, timestamp: String, date: Date, source: String, failed: Bool = false) {
        self.id = id
        self.message = message
        self.timestamp = timestamp
        self.date = date
        self.source = source
        self.level = failed ? .error : Self.level(of: message)
    }

    public func text(timestamps: Bool) -> String {
        (timestamps && !timestamp.isEmpty ? timestamp + " " : "") + (source.isEmpty ? "" : "[\(source)] ") + message
    }

    public func matches(_ query: String) -> Bool {
        let words = query.split(separator: " ")
        return words.allSatisfy { message.localizedCaseInsensitiveContains($0) || source.localizedCaseInsensitiveContains($0) }
    }

    /// The level a line states about itself; which stream it came on says nothing, because many servers log everything to standard error.
    static func level(of message: String) -> Level {
        let head = message.prefix(160).lowercased()
        if head.range(of: #"(\b|\[|level=)(error|err|fatal|panic|crit|critical|emerg|alert)(\b|\]|:)"#, options: .regularExpression) != nil { return .error }
        if head.range(of: #"(\b|\[|level=)(warn|warning)(\b|\]|:)"#, options: .regularExpression) != nil { return .warning }
        return .normal
    }
}

/// Output as it is written: each line's time, its source in its own color when several sources share the view, then the message, red or orange only when the line itself says error or warning, search matches marked in place. While following, it stays at the newest line; scrolling up stops following and a capsule offers the way back with how many lines arrived since.
public struct LogView: View {
    let lines: [LogLine]
    let query: String
    let timestamps: Bool
    let wrap: Bool
    let fontSize: Double
    @Binding var follow: Bool
    var selectedID: Int?
    var select: (LogLine) -> Void
    @State private var seenCount = 0
    @State private var userScrolling = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        lines: [LogLine], query: String = "", timestamps: Bool = false, wrap: Bool = true, fontSize: Double = 12, follow: Binding<Bool>, selectedID: Int? = nil,
        select: @escaping (LogLine) -> Void = { _ in }
    ) {
        self.lines = lines
        self.query = query
        self.timestamps = timestamps
        self.wrap = wrap
        self.fontSize = fontSize
        _follow = follow
        self.selectedID = selectedID
        self.select = select
    }

    private var sources: [String] {
        var seen: [String] = []
        for line in lines where !line.source.isEmpty && !seen.contains(line.source) {
            seen.append(line.source)
            if seen.count > 8 { break }
        }
        return seen
    }

    public var body: some View {
        let sources = sources
        let font = Font.system(size: fontSize, design: .monospaced)
        let sourceWidth = sources.count > 1 ? CGFloat(sources.map(\.count).max() ?? 0) * fontSize * 0.62 : 0
        ScrollViewReader { proxy in
            GeometryReader { geometry in
                ScrollView(wrap ? [.vertical] : [.horizontal, .vertical]) {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(lines) { line in
                            LogRow(
                                line: line, query: query, timestamps: timestamps, wrap: wrap, font: font,
                                sourceColor: sources.count > 1 ? Self.color(for: line.source, in: sources) : nil,
                                sourceWidth: sourceWidth, selected: line.id == selectedID
                            )
                            .onTapGesture { select(line) }
                        }
                        Color.clear.frame(height: 12).id("end")
                    }
                    .padding(.top, 4)
                    .frame(minWidth: geometry.size.width, alignment: .leading)
                }
                .onScrollPhaseChange { _, phase in userScrolling = phase == .interacting || phase == .tracking || phase == .decelerating }
                .onScrollGeometryChange(for: Bool.self) { geometry in
                    geometry.contentOffset.y + geometry.containerSize.height >= geometry.contentSize.height - 24
                } action: { _, atEnd in
                    guard userScrolling else { return }
                    if follow != atEnd { follow = atEnd }
                }
            }
            .overlay(alignment: .bottom) {
                if !follow, lines.count > seenCount {
                    Button {
                        follow = true
                    } label: {
                        Label(String(localized: "\(lines.count - seenCount) new", bundle: .module), systemImage: "arrow.down")
                            .labelStyle(.titleAndIcon)
                            .monospacedDigit()
                    }
                    .buttonStyle(.prominentCapsule)
                    .padding(.bottom, 16)
                    .transition(.opacity.combined(with: .offset(y: reduceMotion ? 0 : 8)))
                    .help(String(localized: "Jump to Latest", bundle: .module))
                }
            }
            .animation(reduceMotion ? nil : .spring(duration: 0.25, bounce: 0), value: !follow && lines.count > seenCount)
            .onChange(of: lines.last?.id) {
                if follow { proxy.scrollTo("end", anchor: .bottom) }
            }
            .onChange(of: follow) { _, value in
                if value { proxy.scrollTo("end", anchor: .bottom) } else { seenCount = lines.count }
            }
            .onAppear { proxy.scrollTo("end", anchor: .bottom) }
        }
    }

    /// The categorical hues, so each source keeps one color for as long as the view lists it.
    static func color(for source: String, in sources: [String]) -> Color {
        let palette: [Color] = [.blue, .teal, .purple, .orange, .pink, .green, .indigo, .brown]
        return palette[(sources.firstIndex(of: source) ?? 0) % palette.count]
    }
}

private struct LogRow: View {
    let line: LogLine
    let query: String
    let timestamps: Bool
    let wrap: Bool
    let font: Font
    let sourceColor: Color?
    let sourceWidth: CGFloat
    let selected: Bool
    @State private var hovering = false

    private var tone: Color? {
        switch line.level {
        case .error: .red
        case .warning: .orange
        case .normal: nil
        }
    }

    private var message: AttributedString {
        var text = AttributedString(line.message)
        if let tone { text.foregroundColor = tone }
        for word in query.split(separator: " ") where !word.isEmpty {
            var start = text.startIndex
            while start < text.endIndex, let range = text[start...].range(of: word, options: .caseInsensitive) {
                text[range].backgroundColor = Color.yellow.opacity(0.4)
                start = range.upperBound
            }
        }
        return text
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            if timestamps {
                Text(line.date, format: .dateTime.hour(.twoDigits(amPM: .omitted)).minute().second())
                    .foregroundStyle(.tertiary)
                    .fixedSize()
            }
            if let sourceColor {
                Text(line.source)
                    .foregroundStyle(sourceColor)
                    .lineLimit(1)
                    .frame(width: sourceWidth, alignment: .leading)
            }
            Text(message)
                .foregroundStyle(tone == nil ? AnyShapeStyle(.primary) : AnyShapeStyle(tone!))
                .fixedSize(horizontal: !wrap, vertical: true)
                .frame(maxWidth: wrap ? .infinity : nil, alignment: .leading)
        }
        .font(font)
        .textSelection(.enabled)
        .padding(.leading, Metrics.pageInset)
        .padding(.trailing, Metrics.pageInset)
        .padding(.vertical, 1.5)
        .background(alignment: .leading) {
            ZStack(alignment: .leading) {
                if selected { Color.accentColor.opacity(0.14) } else if hovering { Color.primary.opacity(0.04) }
                if let tone { tone.frame(width: 2).padding(.leading, Metrics.pageInset - 10) }
            }
        }
        .contentShape(.rect)
        .onHover { hovering = $0 }
        .accessibilityElement(children: .combine)
    }
}
