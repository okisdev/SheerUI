import SwiftUI

/// A round glyph button on a soft fill: the page header's and a row's commands. Its title is the help tag and the VoiceOver label.
public struct CircleButtonStyle: ButtonStyle {
    var size: CGFloat = Metrics.control
    var selected = false
    @Environment(\.isEnabled) private var enabled
    @State private var hovering = false

    public init(size: CGFloat = Metrics.control, selected: Bool = false) {
        self.size = size
        self.selected = selected
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .labelStyle(.iconOnly)
            .font(.system(size: size * 0.42, weight: .medium))
            .foregroundStyle(selected ? AnyShapeStyle(.tint) : enabled ? AnyShapeStyle(.primary) : AnyShapeStyle(.tertiary))
            .frame(width: size, height: size)
            .background(fill(pressed: configuration.isPressed), in: .circle)
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .contentShape(.circle)
            .animation(.easeOut(duration: 0.12), value: hovering)
            .animation(.easeOut(duration: 0.15), value: selected)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
            .onHover { hovering = $0 }
            .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func fill(pressed: Bool) -> Color {
        if selected { return Color.accentColor.opacity(pressed ? 0.24 : hovering ? 0.2 : 0.15) }
        return Color.primary.opacity(pressed ? 0.14 : hovering && enabled ? 0.1 : 0.06)
    }
}

extension ButtonStyle where Self == CircleButtonStyle {
    public static var circle: CircleButtonStyle { CircleButtonStyle() }
    public static func circle(size: CGFloat) -> CircleButtonStyle { CircleButtonStyle(size: size) }
    /// A round toggle: the accent on a tinted fill while it is on.
    public static func circle(selected: Bool) -> CircleButtonStyle { CircleButtonStyle(selected: selected) }
}

/// A capsule button: soft for most commands, filled with the accent only for the one move a state calls for.
public struct CapsuleButtonStyle: ButtonStyle {
    var prominent = false
    @Environment(\.isEnabled) private var enabled
    @State private var hovering = false

    public init(prominent: Bool = false) {
        self.prominent = prominent
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.medium))
            .foregroundStyle(prominent ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
            .padding(.horizontal, 16)
            .frame(height: Metrics.control)
            .background(fill(pressed: configuration.isPressed), in: .capsule)
            .opacity(enabled ? 1 : 0.45)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .contentShape(.capsule)
            .animation(.easeOut(duration: 0.12), value: hovering)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
            .onHover { hovering = $0 }
    }

    private func fill(pressed: Bool) -> Color {
        if prominent { return Color.accentColor.opacity(pressed ? 0.8 : hovering ? 0.92 : 1) }
        return Color.primary.opacity(pressed ? 0.14 : hovering ? 0.1 : 0.06)
    }
}

extension ButtonStyle where Self == CapsuleButtonStyle {
    public static var capsule: CapsuleButtonStyle { CapsuleButtonStyle() }
    public static var prominentCapsule: CapsuleButtonStyle { CapsuleButtonStyle(prominent: true) }
}

/// The page's search: a capsule field that Command F focuses and Escape clears.
public struct CapsuleSearchField: View {
    let prompt: Text
    @Binding var text: String
    var width: CGFloat = 220
    @FocusState private var focused: Bool

    public init(prompt: LocalizedStringKey, text: Binding<String>, width: CGFloat = 220) {
        self.init(prompt: Text(prompt), text: text, width: width)
    }

    public init(prompt: Text, text: Binding<String>, width: CGFloat = 220) {
        self.prompt = prompt
        self._text = text
        self.width = width
    }

    public var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            TextField(text: $text, prompt: prompt) { prompt }
                .textFieldStyle(.plain)
                .focused($focused)
                .onExitCommand {
                    text = ""; focused = false
                }
            if !text.isEmpty {
                Button(String(localized: "Clear Search", bundle: .module), systemImage: "xmark.circle.fill") { text = "" }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.plain)
                    .foregroundStyle(.tertiary)
                    .help(String(localized: "Clear Search", bundle: .module))
            }
        }
        .padding(.horizontal, 12)
        .frame(width: width, height: Metrics.control)
        .background(Color.primary.opacity(focused ? 0.08 : 0.06), in: .capsule)
        .background {
            Button(String(localized: "Find", bundle: .module)) { focused = true }
                .keyboardShortcut("f")
                .opacity(0)
                .accessibilityElement(children: .ignore)
                .accessibilityHidden(true)
        }
    }
}

/// Views of one subject as capsule segments: the chosen one on a raised fill.
public struct CapsuleTabs<Value: Hashable>: View {
    let options: [(value: Value, title: Text)]
    @Binding var selection: Value
    @Namespace private var namespace

    public init(options: [(value: Value, title: LocalizedStringKey)], selection: Binding<Value>) {
        self.init(options: options.map { ($0.value, Text($0.title)) }, selection: selection)
    }

    public init(options: [(value: Value, title: Text)], selection: Binding<Value>) {
        self.options = options
        self._selection = selection
    }

    public var body: some View {
        HStack(spacing: 2) {
            ForEach(Array(options.enumerated()), id: \.offset) { _, option in
                let chosen = option.value == selection
                Button {
                    withAnimation(.snappy(duration: 0.2)) { selection = option.value }
                } label: {
                    option.title
                        .font(.body.weight(.medium))
                        .foregroundStyle(chosen ? .primary : .secondary)
                        .padding(.horizontal, 14)
                        .frame(height: Metrics.control - 4)
                        .background {
                            if chosen {
                                Capsule()
                                    .fill(Color(nsColor: .controlBackgroundColor))
                                    .shadow(color: .black.opacity(0.08), radius: 1, y: 0.5)
                                    .matchedGeometryEffect(id: "tab", in: namespace)
                            }
                        }
                        .contentShape(.capsule)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(chosen ? .isSelected : [])
            }
        }
        .padding(2)
        .background(Color.primary.opacity(0.06), in: .capsule)
        .fixedSize()
    }
}

/// The page's one finishing move, floating at the foot of the sheet beside the figure it acts on.
public struct ActionCapsule<Content: View>: View {
    @ViewBuilder let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        HStack(spacing: 12) { content }
            .padding(.leading, 20)
            .padding(.trailing, 6)
            .padding(.vertical, 6)
            .background(.sheet, in: .capsule)
            .overlay(Capsule().strokeBorder(.hairline))
            .shadow(color: .black.opacity(0.12), radius: 16, y: 6)
    }
}
