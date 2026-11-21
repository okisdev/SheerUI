import SwiftUI

/// Commands a view inside a page sends up to the end of the page's header row, because the page, not the view, owns that row.
public struct PageCommandsKey: PreferenceKey {
    public static var defaultValue: PageCommands? { nil }
    public static func reduce(value: inout PageCommands?, nextValue: () -> PageCommands?) { value = PageCommands(value, nextValue()) }
}

public struct PageCommands: Equatable {
    public let view: AnyView
    public static func == (lhs: Self, rhs: Self) -> Bool { false }

    /// Both sets of commands in order, or whichever exists.
    init?(_ first: PageCommands?, _ second: PageCommands?) {
        switch (first, second) {
        case (nil, nil): return nil
        case (let only?, nil), (nil, let only?): view = only.view
        case (let first?, let second?):
            view = AnyView(
                HStack(spacing: 8) {
                    first.view; second.view
                })
        }
    }

    init(view: AnyView) { self.view = view }
}

extension View {
    /// Puts these commands at the trailing end of the header of the page that holds this view, as round glyphs.
    public func pageCommands<Commands: View>(@ViewBuilder _ commands: () -> Commands) -> some View {
        let sent = PageCommands(view: AnyView(commands()))
        return transformPreference(PageCommandsKey.self) { $0 = PageCommands($0, sent) }
    }
}

/// The room a page header takes above the content, so content that scrolls starts under it.
private let headerRoom = Metrics.pageTop + Metrics.headerHeight + 10

/// A page on the sheet: its header written into the sheet (name, count, then the commands of the page and of whatever view inside
/// it sends some), then the content.
public struct Page<Commands: View, Content: View>: View {
    let title: Text
    var meta: Text?
    @ViewBuilder let commands: Commands
    @ViewBuilder let content: Content

    public init(title: Text, meta: Text? = nil, @ViewBuilder commands: () -> Commands, @ViewBuilder content: () -> Content) {
        self.title = title
        self.meta = meta
        self.commands = commands()
        self.content = content()
    }

    public var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.top, headerRoom)
            .overlayPreferenceValue(PageCommandsKey.self, alignment: .top) { sent in
                PageHeader(title: title, meta: meta) {
                    commands
                    sent?.view
                }
            }
    }
}

extension Page where Commands == EmptyView {
    public init(title: Text, meta: Text? = nil, @ViewBuilder content: () -> Content) {
        self.init(title: title, meta: meta, commands: { EmptyView() }, content: content)
    }
}

/// A page whose rows open in place of it: the opened row's view replaces the list, the header turns into the path back (the page's
/// name, then the row's), and Escape or Command [ steps back. The list stays alive underneath with its scroll and search.
public struct DrillPage<Route: Hashable, Commands: View, Root: View, Detail: View>: View {
    let title: Text
    var meta: Text?
    @Binding var path: [Route]
    let subject: (Route) -> Text
    @ViewBuilder let commands: Commands
    @ViewBuilder let root: Root
    let detail: (Route) -> Detail
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        title: Text, meta: Text? = nil, path: Binding<[Route]>, subject: @escaping (Route) -> Text, @ViewBuilder commands: () -> Commands,
        @ViewBuilder root: () -> Root, @ViewBuilder detail: @escaping (Route) -> Detail
    ) {
        self.title = title
        self.meta = meta
        _path = path
        self.subject = subject
        self.commands = commands()
        self.root = root()
        self.detail = detail
    }

    private func back() { if !path.isEmpty { path.removeLast() } }

    public var body: some View {
        let opened = path.last
        ZStack(alignment: .top) {
            root
                .opacity(opened == nil ? 1 : 0)
                .allowsHitTesting(opened == nil)
                .accessibilityHidden(opened != nil)
                .transformPreference(PageCommandsKey.self) { if opened != nil { $0 = nil } }
            if let opened {
                detail(opened)
                    .id(opened)
                    .transition(.opacity.combined(with: .offset(x: reduceMotion ? 0 : 12)))
                    .onExitCommand(perform: back)
                    .background {
                        Button(String(localized: "Back", bundle: .module), action: back)
                            .keyboardShortcut("[")
                            .opacity(0)
                            .accessibilityHidden(true)
                    }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, headerRoom)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: path)
        .overlayPreferenceValue(PageCommandsKey.self, alignment: .top) { sent in
            PageHeader(title: title, subject: opened.map(subject), meta: opened == nil ? meta : nil, back: { path.removeAll() }) {
                if opened == nil { commands }
                sent?.view
            }
        }
    }
}

extension DrillPage where Commands == EmptyView {
    public init(
        title: Text, meta: Text? = nil, path: Binding<[Route]>, subject: @escaping (Route) -> Text, @ViewBuilder root: () -> Root,
        @ViewBuilder detail: @escaping (Route) -> Detail
    ) {
        self.init(title: title, meta: meta, path: path, subject: subject, commands: { EmptyView() }, root: root, detail: detail)
    }
}
