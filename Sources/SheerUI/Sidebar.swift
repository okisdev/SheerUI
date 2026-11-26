import SwiftUI

/// The sizes a sidebar row takes from the Sidebar icon size chosen in System Settings > Appearance, as the system's own sidebars do.
private struct SidebarScale {
    let font: Font
    let height: CGFloat

    init(mode: Int) {
        switch mode {
        case 1: (font, height) = (.subheadline, 26)
        case 3: (font, height) = (.title3, 38)
        default: (font, height) = (.navigation, Metrics.sidebarRowHeight)
        }
    }
}

/// The look of a sidebar row without its action, so a button and a menu share it: a 22 wide leading column, the title, an optional trailing view, on a neutral fill while selected or hovered.
public struct SidebarRowLabel<Leading: View, Trailing: View>: View {
    let title: Text
    let selected: Bool
    @ViewBuilder let leading: Leading
    @ViewBuilder let trailing: Trailing
    @State private var hovering = false
    @AppStorage("NSTableViewDefaultSizeMode") private var sizeMode = 2

    public init(title: LocalizedStringKey, selected: Bool, @ViewBuilder leading: () -> Leading, @ViewBuilder trailing: () -> Trailing) {
        self.init(title: Text(title), selected: selected, leading: leading, trailing: trailing)
    }

    public init(title: Text, selected: Bool, @ViewBuilder leading: () -> Leading, @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.selected = selected
        self.leading = leading()
        self.trailing = trailing()
    }

    public var body: some View {
        let scale = SidebarScale(mode: sizeMode)
        HStack(spacing: 8) {
            leading
                .font(scale.font)
                .foregroundStyle(selected ? .primary : .secondary)
                .frame(width: 22)
            title
                .font(scale.font)
                .foregroundStyle(selected ? .primary : .secondary)
                .lineLimit(1)
            Spacer(minLength: 4)
            trailing
        }
        .fontWeight(selected ? .medium : .regular)
        .padding(.horizontal, 10)
        .frame(height: scale.height)
        .background(selected ? Color.primary.opacity(0.08) : hovering ? Color.primary.opacity(0.04) : .clear, in: .rect(cornerRadius: 9))
        .contentShape(.rect(cornerRadius: 9))
        .animation(.easeOut(duration: 0.12), value: hovering)
        .animation(.easeOut(duration: 0.16), value: selected)
        .onHover { hovering = $0 }
    }
}

extension SidebarRowLabel where Trailing == EmptyView {
    public init(title: LocalizedStringKey, selected: Bool, @ViewBuilder leading: () -> Leading) {
        self.init(title: Text(title), selected: selected, leading: leading) { EmptyView() }
    }

    public init(title: Text, selected: Bool, @ViewBuilder leading: () -> Leading) {
        self.init(title: title, selected: selected, leading: leading) { EmptyView() }
    }
}

/// A row in a window sidebar: an icon column and the title, on a neutral fill while selected, with an optional trailing view such as a status dot.
public struct SidebarRow<Trailing: View>: View {
    let title: Text
    let systemImage: String
    let selected: Bool
    let action: () -> Void
    @ViewBuilder let trailing: Trailing

    public init(
        title: LocalizedStringKey, systemImage: String, selected: Bool, action: @escaping () -> Void, @ViewBuilder trailing: () -> Trailing
    ) {
        self.init(title: Text(title), systemImage: systemImage, selected: selected, action: action, trailing: trailing)
    }

    public init(title: Text, systemImage: String, selected: Bool, action: @escaping () -> Void, @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.systemImage = systemImage
        self.selected = selected
        self.action = action
        self.trailing = trailing()
    }

    public var body: some View {
        Button(action: action) {
            SidebarRowLabel(title: title, selected: selected) {
                Image(systemName: systemImage)
            } trailing: {
                trailing
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

extension SidebarRow where Trailing == EmptyView {
    public init(title: LocalizedStringKey, systemImage: String, selected: Bool, action: @escaping () -> Void) {
        self.init(title: Text(title), systemImage: systemImage, selected: selected, action: action) { EmptyView() }
    }

    public init(title: Text, systemImage: String, selected: Bool, action: @escaping () -> Void) {
        self.init(title: title, systemImage: systemImage, selected: selected, action: action) { EmptyView() }
    }
}
