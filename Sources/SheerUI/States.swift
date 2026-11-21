import SwiftUI

/// A page with nothing to show: a glyph, one label, one sentence and at most one next step as a capsule, centered where the rows would be.
public struct EmptyState: View {
    let title: Text
    let systemImage: String
    var message: Text?
    var actionTitle: Text?
    var action: () -> Void = {}

    public init(title: Text, systemImage: String, message: Text? = nil, actionTitle: Text? = nil, action: @escaping () -> Void = {}) {
        self.title = title
        self.systemImage = systemImage
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    public init(
        title: LocalizedStringKey, systemImage: String, message: Text? = nil, actionTitle: LocalizedStringKey? = nil, action: @escaping () -> Void = {}
    ) {
        self.init(title: Text(title), systemImage: systemImage, message: message, actionTitle: actionTitle.map { Text($0) }, action: action)
    }

    public var body: some View {
        VStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 38, weight: .regular))
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
            VStack(spacing: 5) {
                title
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.secondary)
                if let message {
                    message
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .textSelection(.enabled)
                }
            }
            if let actionTitle {
                Button(action: action) { actionTitle }
                    .buttonStyle(.capsule)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: 380)
        .padding(.bottom, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
    }
}

/// Live work: a 5 by 5 grid whose dots blink on their own periods between 0.9 and 1.4 s. Under Reduce Motion the grid holds still.
public struct DotMatrix: View {
    var size: CGFloat = 14
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(size: CGFloat = 14) {
        self.size = size
    }

    public var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            Canvas { canvas, area in
                let step = area.width / 5
                let dot = step * 0.6
                for index in 0..<25 {
                    let period = 0.9 + Double((index * 7) % 11) * 0.05
                    let phase = Double((index * 13) % 25) / 25
                    let wave = reduceMotion ? 0.5 : 0.5 + 0.5 * sin((time / period + phase) * 2 * .pi)
                    let rect = CGRect(x: CGFloat(index % 5) * step + (step - dot) / 2, y: CGFloat(index / 5) * step + (step - dot) / 2, width: dot, height: dot)
                    canvas.fill(Path(ellipseIn: rect), with: .color(.secondary.opacity(0.2 + 0.8 * wave)))
                }
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel(String(localized: "Working", bundle: .module))
    }
}

/// Rows still on their way: after 400 ms, six placeholder rows in the footprint of the rows they stand for, so a quick answer never flashes and a slow one never moves the layout. The title is what VoiceOver reads.
public struct LoadingState: View {
    let title: Text
    var rows = 6
    @State private var visible = false

    public init(title: Text, rows: Int = 6) {
        self.title = title
        self.rows = rows
    }

    public init(title: LocalizedStringKey, rows: Int = 6) {
        self.init(title: Text(title), rows: rows)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(0..<rows, id: \.self) { index in
                PlaceholderRow(index: index)
            }
        }
        .padding(.horizontal, Metrics.pageInset)
        .padding(.top, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .opacity(visible ? 1 : 0)
        .task {
            try? await Task.sleep(for: .milliseconds(400))
            withAnimation(.easeOut(duration: 0.2)) { visible = true }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
    }
}

/// Rows still on their way inside a card that is already drawn: no delay, because the card around them already holds the place.
public struct PlaceholderRows: View {
    var count = 3

    public init(count: Int = 3) {
        self.count = count
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(0..<count, id: \.self) { index in
                PlaceholderRow(index: index, dot: false)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Loading", bundle: .module))
    }
}

/// A settings page still loading: cards in the footprint of the form, so the page never opens on a blank pane.
public struct FormPlaceholder: View {
    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: Metrics.sectionSpacing) {
            ForEach([3, 2], id: \.self) { rows in
                VStack(alignment: .leading, spacing: 8) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.primary.opacity(0.06))
                        .frame(width: 90, height: 11)
                    PlaceholderRows(count: rows)
                        .padding(.horizontal, Metrics.cardInset)
                        .background(.groupFill, in: .rect(cornerRadius: Metrics.groupRadius, style: .continuous))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Metrics.pageInset)
        .padding(.top, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .transition(.opacity)
    }
}

/// One placeholder: a dot, a name bar and a meta bar, breathing between the fill and a little more unless Reduce Motion is on.
private struct PlaceholderRow: View {
    let index: Int
    var dot = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var bright = false

    var body: some View {
        let widths: [(CGFloat, CGFloat)] = [(150, 220), (190, 170), (120, 240), (170, 200), (140, 180), (200, 230)]
        let width = widths[index % widths.count]
        HStack(spacing: 12) {
            if dot { Circle().frame(width: 9, height: 9) }
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 3).frame(width: width.0, height: 10)
                RoundedRectangle(cornerRadius: 3).frame(width: width.1, height: 8)
            }
        }
        .foregroundStyle(Color.primary.opacity(bright ? 0.08 : 0.045))
        .frame(height: dot ? Metrics.listRowHeight : Metrics.rowHeight + 6, alignment: .leading)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { bright = true }
        }
    }
}
