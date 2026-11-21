import AppKit
import SwiftUI

/// A control that opens a menu: the label is drawn as a plain button, and a click pops up an AppKit menu built from the SwiftUI
/// content under it.
///
/// A SwiftUI `Menu` with a drawn label (`.menuStyle(.button)` with a plain button style) stops answering clicks on macOS 27, so
/// every menu here opens through `NSHostingMenu` instead, which also keeps the control one accessibility element. The menu's
/// content gets the label's environment, because an AppKit menu sits outside the view hierarchy.
public struct PopUpMenu<Label: View, Content: View>: View {
    let content: () -> Content
    let label: Label
    @State private var anchor = MenuAnchor()
    @Environment(\.self) private var environment

    public init(@ViewBuilder content: @escaping () -> Content, @ViewBuilder label: () -> Label) {
        self.content = content
        self.label = label()
    }

    public var body: some View {
        Button(action: open) { label }
            .buttonStyle(.plain)
            .background(MenuAnchorView(anchor: anchor))
            .accessibilityAddTraits(.isButton)
    }

    private func open() {
        guard let view = anchor.view else { return }
        let menu = NSHostingMenu(rootView: content().environment(\.self, environment))
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: view.isFlipped ? view.bounds.maxY + 4 : -4), in: view)
    }
}

/// The AppKit view behind a menu's label, so the menu opens under it.
@MainActor private final class MenuAnchor {
    weak var view: NSView?
}

private struct MenuAnchorView: NSViewRepresentable {
    let anchor: MenuAnchor

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        anchor.view = view
        return view
    }

    func updateNSView(_ view: NSView, context: Context) { anchor.view = view }
}

/// A round menu on the same soft fill as `CircleButtonStyle`, for sort, filter and More. Its title is the help tag and the VoiceOver
/// label.
public struct CircleMenu<Content: View>: View {
    let title: Text
    let systemImage: String
    var size: CGFloat
    let content: () -> Content
    @State private var hovering = false

    public init(title: Text, systemImage: String, size: CGFloat = Metrics.control, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.systemImage = systemImage
        self.size = size
        self.content = content
    }

    public init(title: LocalizedStringKey, systemImage: String, size: CGFloat = Metrics.control, @ViewBuilder content: @escaping () -> Content) {
        self.init(title: Text(title), systemImage: systemImage, size: size, content: content)
    }

    public var body: some View {
        PopUpMenu(content: content) {
            Image(systemName: systemImage)
                .font(.system(size: size * 0.42, weight: .medium))
                .foregroundStyle(.primary)
                .frame(width: size, height: size)
                .background(Color.primary.opacity(hovering ? 0.1 : 0.06), in: .circle)
                .contentShape(.circle)
                .animation(.easeOut(duration: 0.12), value: hovering)
        }
        .fixedSize()
        .onHover { hovering = $0 }
        .help(title)
        .accessibilityLabel(title)
    }
}

/// A capsule naming what is chosen, whose menu holds the choices: the product's own control in place of a system pop up button.
public struct MenuCapsule<Content: View>: View {
    let current: Text
    var height: CGFloat
    let content: () -> Content
    @State private var hovering = false

    public init(_ current: Text, height: CGFloat = Metrics.rowControl, @ViewBuilder content: @escaping () -> Content) {
        self.current = current
        self.height = height
        self.content = content
    }

    public var body: some View {
        PopUpMenu(content: content) {
            HStack(spacing: 6) {
                current.lineLimit(1)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 12)
            .frame(height: height)
            .background(Color.primary.opacity(hovering ? 0.1 : 0.06), in: .capsule)
            .contentShape(.capsule)
            .animation(.easeOut(duration: 0.12), value: hovering)
        }
        .fixedSize()
        .onHover { hovering = $0 }
    }
}

/// A choice among a few values, shown as a capsule naming the chosen one; its menu lists the rest with a check beside the chosen.
public struct MenuPicker<Value: Hashable>: View {
    let title: Text
    let options: [(value: Value, title: Text)]
    @Binding var selection: Value

    public init(_ title: Text, options: [(value: Value, title: Text)], selection: Binding<Value>) {
        self.title = title
        self.options = options
        _selection = selection
    }

    public init(_ title: LocalizedStringKey, options: [(value: Value, title: LocalizedStringKey)], selection: Binding<Value>) {
        self.init(Text(title), options: options.map { ($0.value, Text($0.title)) }, selection: selection)
    }

    public var body: some View {
        MenuCapsule(options.first { $0.value == selection }?.title ?? Text(verbatim: "")) {
            Picker(selection: $selection) {
                ForEach(options.indices, id: \.self) { index in
                    options[index].title.tag(options[index].value)
                }
            } label: {
                title
            }
            .pickerStyle(.inline)
            .labelsHidden()
        }
        .accessibilityLabel(title)
    }
}
