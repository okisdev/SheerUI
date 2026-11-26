import SwiftUI

extension EnvironmentValues {
    /// The selected sidebar page's name, set by the shell so a page's header leads with it without the page restating it.
    @Entry public var pageTitle = Text(verbatim: "")
    /// Views the shell puts beside the page's name, such as tabs for related lists.
    @Entry public var pageAccessory: AnyView?
    /// Leaves an opened row for its list; nil in a detail window, which has no list.
    @Entry public var detailBack: (() -> Void)?
    /// Whether a detail fills its own window, whose controls sit at the header's leading edge.
    @Entry public var detailInWindow = false
    @Entry var listRowDisclosure: Binding<Bool>?
    @Entry var listRowReservesDisclosure = false
    @Entry var listRowNested = false
}

/// Whether a page shows an opened row in place of its list, so a container holding the page can step its own chrome aside.
extension View {
    /// Draws the list rows inside in the compact size, as nested rows and small surfaces such as a popover use.
    public func compactListRows() -> some View {
        environment(\.listRowNested, true)
    }
}

public struct PageShowsDetail: PreferenceKey {
    public static let defaultValue = false
    public static func reduce(value: inout Bool, nextValue: () -> Bool) { value = value || nextValue() }
}

private struct DisclosurePresence: PreferenceKey {
    static let defaultValue = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) { value = value || nextValue() }
}

/// A page of rows on the sheet: its header (name, count, commands, search), then the rows. Opening a row replaces the list with that row's detail in place, and the name in the detail's header leads back; the list keeps its search and scroll underneath.
public struct ListPage<Commands: View, Rows: View, Detail: View>: View {
    var meta: Text?
    var search: Binding<String>?
    var searchPrompt: Text?
    var showsDetail = false
    var back: () -> Void = {}
    @ViewBuilder let commands: Commands
    @ViewBuilder let rows: Rows
    @ViewBuilder let detail: Detail
    @Environment(\.pageTitle) private var title
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        meta: Text? = nil, search: Binding<String>? = nil, searchPrompt: Text? = nil, showsDetail: Bool = false,
        back: @escaping () -> Void = {}, @ViewBuilder commands: () -> Commands, @ViewBuilder rows: () -> Rows, @ViewBuilder detail: () -> Detail
    ) {
        self.meta = meta
        self.search = search
        self.searchPrompt = searchPrompt
        self.showsDetail = showsDetail
        self.back = back
        self.commands = commands()
        self.rows = rows()
        self.detail = detail()
    }

    public var body: some View {
        ZStack {
            VStack(spacing: 10) {
                PageHeader(title: title, meta: meta) {
                    commands
                    if let search {
                        CapsuleSearchField(prompt: searchPrompt ?? Text(String(localized: "Search", bundle: .module)), text: search)
                    }
                }
                rows
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .opacity(showsDetail ? 0 : 1)
            .disabled(showsDetail)
            .allowsHitTesting(!showsDetail)
            .accessibilityHidden(showsDetail)
            if showsDetail {
                detail
                    .environment(\.detailBack, back)
                    .transition(.opacity.combined(with: .offset(x: reduceMotion ? 0 : 12)))
                    .onExitCommand(perform: back)
                    .background {
                        Button(String(localized: "Back", bundle: .module), action: back)
                            .keyboardShortcut("[")
                            .opacity(0)
                            .accessibilityElement(children: .ignore)
                            .accessibilityHidden(true)
                    }
            }
        }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: showsDetail)
        .preference(key: PageShowsDetail.self, value: showsDetail)
    }
}

extension ListPage where Commands == EmptyView {
    public init(
        meta: Text? = nil, search: Binding<String>? = nil, searchPrompt: Text? = nil, showsDetail: Bool = false,
        back: @escaping () -> Void = {}, @ViewBuilder rows: () -> Rows, @ViewBuilder detail: () -> Detail
    ) {
        self.init(
            meta: meta, search: search, searchPrompt: searchPrompt, showsDetail: showsDetail, back: back, commands: { EmptyView() }, rows: rows, detail: detail)
    }
}

extension ListPage where Detail == EmptyView {
    /// A page of rows that open nothing in place, such as items that open in their own windows.
    public init(
        meta: Text? = nil, search: Binding<String>? = nil, searchPrompt: Text? = nil, @ViewBuilder commands: () -> Commands,
        @ViewBuilder rows: () -> Rows
    ) {
        self.init(meta: meta, search: search, searchPrompt: searchPrompt, commands: commands, rows: rows, detail: { EmptyView() })
    }
}

/// The rows of a page: a scrolling column of groups whose text lines up with the header.
public struct GroupedList<Content: View>: View {
    @ViewBuilder let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) { content }
                .padding(.horizontal, Metrics.pageInset)
                .padding(.top, 4)
                .padding(.bottom, 24)
        }
        .scrollContentBackground(.hidden)
        .scrollBounceBehavior(.basedOnSize)
    }
}

/// A run of rows on a soft card, parted by inset hairlines, under an optional name with its count and at most one trailing command. Groups give a list its order without boxing every row.
public struct ListGroup<Trailing: View, Content: View>: View {
    var title: Text?
    var count: Int?
    @ViewBuilder let trailing: Trailing
    @ViewBuilder let content: Content
    @State private var reservesDisclosure = false

    public init(title: Text? = nil, count: Int? = nil, @ViewBuilder trailing: () -> Trailing, @ViewBuilder content: () -> Content) {
        self.title = title
        self.count = count
        self.trailing = trailing()
        self.content = content()
    }

    public init(title: LocalizedStringKey, count: Int? = nil, @ViewBuilder trailing: () -> Trailing, @ViewBuilder content: () -> Content) {
        self.init(title: Text(title), count: count, trailing: trailing, content: content)
    }

    @_disfavoredOverload
    public init(title: String? = nil, count: Int? = nil, @ViewBuilder trailing: () -> Trailing, @ViewBuilder content: () -> Content) {
        self.init(title: title.map { Text(verbatim: $0) }, count: count, trailing: trailing, content: content)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title {
                HStack(spacing: 6) {
                    title.foregroundStyle(.primary)
                    if let count { Text(count, format: .number).foregroundStyle(.tertiary).monospacedDigit() }
                    Spacer(minLength: 8)
                    trailing
                }
                .font(.sectionLabel)
                .frame(height: Metrics.rowControl)
                .accessibilityAddTraits(.isHeader)
            }
            VStack(spacing: 0) {
                Group(subviews: content) { rows in
                    ForEach(rows.indices, id: \.self) { index in
                        rows[index]
                        if index < rows.count - 1 {
                            Rectangle()
                                .fill(.hairline)
                                .frame(height: 1)
                                .padding(.horizontal, 12)
                        }
                    }
                }
            }
            .padding(2)
            .background(.groupFill, in: .rect(cornerRadius: Metrics.groupRadius, style: .continuous))
            .environment(\.listRowReservesDisclosure, reservesDisclosure)
            .onPreferenceChange(DisclosurePresence.self) { reservesDisclosure = $0 }
        }
    }
}

/// A row that holds rows of its own. A chevron at its leading edge turns as it opens; its children appear beneath it, indented so their dots line up with its title, in the compact row size along a guide line, so they read as part of it rather than as more of the list. Sibling rows in the same group keep the chevron's column so every dot stays on one line.
public struct DisclosureRow<Row: View, Children: View>: View {
    @Binding var isExpanded: Bool
    @State private var leading = StateDot.size
    let row: Row
    let children: Children
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(isExpanded: Binding<Bool>, @ViewBuilder row: () -> Row, @ViewBuilder children: () -> Children) {
        _isExpanded = isExpanded
        self.row = row()
        self.children = children()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            row
                .environment(\.listRowDisclosure, $isExpanded.animation(reduceMotion ? nil : .spring(duration: 0.3, bounce: 0)))
                .onPreferenceChange(ListRowLeading.self) { leading = $0 }
            if isExpanded {
                VStack(alignment: .leading, spacing: 0) { children }
                    .environment(\.listRowDisclosure, nil)
                    .environment(\.listRowReservesDisclosure, false)
                    .environment(\.listRowNested, true)
                    .padding(.leading, Metrics.disclosureColumn + 12 + leading + 12)
                    .overlay(alignment: .topLeading) {
                        Rectangle()
                            .fill(.hairline)
                            .frame(width: 1)
                            .padding(.leading, 10 + Metrics.disclosureColumn / 2)
                            .padding(.bottom, Metrics.nestedRowHeight / 2)
                    }
                    .padding(.bottom, 4)
                    .transition(.opacity)
            }
        }
        .background(isExpanded ? Color.primary.opacity(0.025) : .clear, in: .rect(cornerRadius: 10))
        .clipShape(.rect(cornerRadius: 10))
        .preference(key: DisclosurePresence.self, value: true)
    }
}

extension ListGroup where Trailing == EmptyView {
    public init(_ title: Text? = nil, count: Int? = nil, @ViewBuilder content: () -> Content) {
        self.init(title: title, count: count, trailing: { EmptyView() }, content: content)
    }

    public init(_ title: LocalizedStringKey, count: Int? = nil, @ViewBuilder content: () -> Content) {
        self.init(Text(title), count: count, content: content)
    }

    @_disfavoredOverload
    public init(_ title: String? = nil, count: Int? = nil, @ViewBuilder content: () -> Content) {
        self.init(title.map { Text(verbatim: $0) }, count: count, content: content)
    }
}

extension ListGroup {
    /// A group built from its rows' data rather than from a run of views. A group given its data
    /// counts itself and builds only the rows the person can see, which is what a list of every
    /// process or package needs: the eager form resolves every row on every change.
    public init<Data: RandomAccessCollection, Row: View>(
        _ title: Text? = nil,
        _ data: Data,
        @ViewBuilder trailing: () -> Trailing,
        @ViewBuilder row: @escaping (Data.Element) -> Row
    ) where Data.Element: Identifiable, Content == LazyRows<Data, Row> {
        self.init(title: title, count: data.count, trailing: trailing) {
            LazyRows(data: data, row: row)
        }
    }

    public init<Data: RandomAccessCollection, Row: View>(
        _ title: LocalizedStringKey,
        _ data: Data,
        @ViewBuilder trailing: () -> Trailing,
        @ViewBuilder row: @escaping (Data.Element) -> Row
    ) where Data.Element: Identifiable, Content == LazyRows<Data, Row> {
        self.init(Text(title), data, trailing: trailing, row: row)
    }

    @_disfavoredOverload
    public init<Data: RandomAccessCollection, Row: View>(
        _ title: String? = nil,
        _ data: Data,
        @ViewBuilder trailing: () -> Trailing,
        @ViewBuilder row: @escaping (Data.Element) -> Row
    ) where Data.Element: Identifiable, Content == LazyRows<Data, Row> {
        self.init(title.map { Text(verbatim: $0) }, data, trailing: trailing, row: row)
    }
}

extension ListGroup where Trailing == EmptyView {
    public init<Data: RandomAccessCollection, Row: View>(
        _ title: Text? = nil,
        _ data: Data,
        @ViewBuilder row: @escaping (Data.Element) -> Row
    ) where Data.Element: Identifiable, Content == LazyRows<Data, Row> {
        self.init(title, data, trailing: { EmptyView() }, row: row)
    }

    public init<Data: RandomAccessCollection, Row: View>(
        _ title: LocalizedStringKey,
        _ data: Data,
        @ViewBuilder row: @escaping (Data.Element) -> Row
    ) where Data.Element: Identifiable, Content == LazyRows<Data, Row> {
        self.init(Text(title), data, row: row)
    }

    @_disfavoredOverload
    public init<Data: RandomAccessCollection, Row: View>(
        _ title: String? = nil,
        _ data: Data,
        @ViewBuilder row: @escaping (Data.Element) -> Row
    ) where Data.Element: Identifiable, Content == LazyRows<Data, Row> {
        self.init(title.map { Text(verbatim: $0) }, data, row: row)
    }
}

/// The rows of a data driven `ListGroup`. It parts its own rows, because a group that let the
/// group part them would have to resolve every row to count them and would never stay lazy.
public struct LazyRows<Data: RandomAccessCollection, Row: View>: View where Data.Element: Identifiable {
    let data: Data
    @ViewBuilder let row: (Data.Element) -> Row

    public var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(data) { element in
                if element.id != data.first?.id {
                    Rectangle()
                        .fill(.hairline)
                        .frame(height: 1)
                        .padding(.horizontal, 12)
                }
                row(element)
            }
        }
    }
}

/// One meta line where rows would be, such as when a search matches nothing.
public struct EmptyLine: View {
    let text: Text

    public init(text: Text) {
        self.text = text
    }

    public init(text: LocalizedStringKey) {
        self.init(text: Text(text))
    }

    public var body: some View {
        text
            .font(.rowMeta)
            .foregroundStyle(.secondary)
            .padding(.horizontal, Metrics.pageInset)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

/// A filled dot beside its state word. The word is what VoiceOver reads.
/// The width of a row's leading artwork or dot, so a disclosure can line its children up under the row's title.
struct ListRowLeading: PreferenceKey {
    static let defaultValue = StateDot.size
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

public struct StateDot: View {
    nonisolated static let size: CGFloat = 9
    let color: Color

    public init(color: Color) {
        self.color = color
    }

    public var body: some View {
        Image(systemName: "circle.fill")
            .font(.system(size: Self.size))
            .foregroundStyle(color)
            .accessibilityHidden(true)
    }
}

/// A list row: optional artwork for what the row is (carrying the state dot on its foot) or a bare state dot, the name over an optional meta line, then its trailing value, followed by the row's commands while the pointer or the keyboard is on it. Clicking the row, or Return or Space while it has focus, opens it.
public struct ListRow<Trailing: View, Actions: View>: View {
    private enum Content {
        case standard(dot: Color?, artwork: Artwork?, title: String, meta: String, metaIsError: Bool, truncation: Text.TruncationMode, trailing: Trailing)
        case custom(Trailing)
    }

    private let content: Content
    var selected: Bool
    var open: (() -> Void)?
    @ViewBuilder let actions: Actions
    @State private var hovering = false
    @FocusState private var focused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.listRowDisclosure) private var disclosure
    @Environment(\.listRowReservesDisclosure) private var reservesDisclosure
    @Environment(\.listRowNested) private var nested

    public init(
        dot: Color? = nil, artwork: Artwork? = nil, title: String, meta: String, metaIsError: Bool = false, truncation: Text.TruncationMode = .tail,
        selected: Bool = false, open: (() -> Void)? = nil, @ViewBuilder trailing: () -> Trailing, @ViewBuilder actions: () -> Actions
    ) {
        self.content = .standard(
            dot: dot, artwork: artwork, title: title, meta: meta, metaIsError: metaIsError, truncation: truncation, trailing: trailing())
        self.selected = selected
        self.open = open
        self.actions = actions()
    }

    public init(
        selected: Bool = false, open: (() -> Void)? = nil, @ViewBuilder content: () -> Trailing, @ViewBuilder actions: () -> Actions
    ) {
        self.content = .custom(content())
        self.selected = selected
        self.open = open
        self.actions = actions()
    }

    private var active: Bool { hovering || focused }
    private var showsActions: Bool { active && Actions.self != EmptyView.self }
    private var primary: (() -> Void)? { open ?? disclosure.map { binding in { binding.wrappedValue.toggle() } } }

    public var body: some View {
        HStack(spacing: 12) {
            if let disclosure {
                Button {
                    disclosure.wrappedValue.toggle()
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(disclosure.wrappedValue ? 90 : 0))
                        .frame(width: Metrics.disclosureColumn, height: Metrics.disclosureColumn)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .help(disclosure.wrappedValue ? "Collapse" : "Expand")
                .accessibilityLabel(disclosure.wrappedValue ? "Collapse" : "Expand")
            } else if reservesDisclosure {
                Color.clear.frame(width: Metrics.disclosureColumn, height: 1)
            }
            HStack(spacing: 10) {
                switch content {
                case .standard(let dot, let artwork, let title, let meta, let metaIsError, let truncation, let trailing):
                    HStack(spacing: 12) {
                        Group {
                            if let artwork {
                                ArtworkView(artwork, size: nested ? Metrics.nestedRowArtwork : Metrics.rowArtwork, badge: dot)
                            } else if let dot {
                                StateDot(color: dot)
                            }
                        }
                        .preference(
                            key: ListRowLeading.self, value: artwork != nil ? (nested ? Metrics.nestedRowArtwork : Metrics.rowArtwork) : StateDot.size)
                        VStack(alignment: .leading, spacing: nested ? 2 : 3) {
                            Text(title)
                                .font(nested ? .callout : .rowTitle)
                                .lineLimit(1)
                                .truncationMode(truncation)
                            if !meta.isEmpty {
                                Text(meta)
                                    .font(.rowMeta)
                                    .foregroundStyle(metaIsError ? AnyShapeStyle(.red) : AnyShapeStyle(.secondary))
                                    .lineLimit(1)
                            }
                        }
                        Spacer(minLength: 8)
                        trailing
                            .foregroundStyle(.secondary)
                    }
                case .custom(let content):
                    HStack(spacing: 12) { content }
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if showsActions {
                    HStack(spacing: 6) { actions }
                        .buttonStyle(.circle(size: Metrics.rowControl))
                        .transition(.opacity.combined(with: .offset(x: reduceMotion ? 0 : 6)))
                }
            }
        }
        .padding(.horizontal, 10)
        .frame(minHeight: nested ? Metrics.nestedRowHeight : Metrics.listRowHeight)
        .background(selected ? .selectedFill : focused ? Color.primary.opacity(0.07) : hovering ? .hoverFill : .clear, in: .rect(cornerRadius: 10))
        .contentShape(.rect(cornerRadius: 10))
        .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: active)
        .onHover { hovering = $0 }
        .onTapGesture { primary?() }
        .focusable(primary != nil, interactions: .activate)
        .focused($focused)
        .focusEffectDisabled()
        .onKeyPress(.return) {
            primary?(); return primary == nil ? .ignored : .handled
        }
        .onKeyPress(.space) {
            primary?(); return primary == nil ? .ignored : .handled
        }
        .onKeyPress(.rightArrow) {
            guard let disclosure, !disclosure.wrappedValue else { return .ignored }
            disclosure.wrappedValue = true
            return .handled
        }
        .onKeyPress(.leftArrow) {
            guard let disclosure, disclosure.wrappedValue else { return .ignored }
            disclosure.wrappedValue = false
            return .handled
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(primary == nil ? [] : .isButton)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityValue(
            disclosure.map { $0.wrappedValue ? Text(String(localized: "Expanded", bundle: .module)) : Text(String(localized: "Collapsed", bundle: .module)) }
                ?? Text(verbatim: "")
        )
        .accessibilityAction { primary?() }
    }
}

extension ListRow where Actions == EmptyView {
    public init(
        dot: Color? = nil, artwork: Artwork? = nil, title: String, meta: String, metaIsError: Bool = false, truncation: Text.TruncationMode = .tail,
        selected: Bool = false, open: (() -> Void)? = nil, @ViewBuilder trailing: () -> Trailing
    ) {
        self.init(
            dot: dot, artwork: artwork, title: title, meta: meta, metaIsError: metaIsError, truncation: truncation, selected: selected, open: open,
            trailing: trailing,
            actions: { EmptyView() })
    }

    public init(selected: Bool = false, open: (() -> Void)? = nil, @ViewBuilder content: () -> Trailing) {
        self.init(selected: selected, open: open, content: content, actions: { EmptyView() })
    }
}

extension View {
    /// A glyph button in a row: the name is its help tag and its accessibility label.
    public func rowGlyph(_ name: Text) -> some View {
        self.labelStyle(.iconOnly)
            .buttonStyle(.borderless)
            .help(name)
            .accessibilityLabel(name)
    }

    public func rowGlyph(_ name: LocalizedStringKey) -> some View {
        rowGlyph(Text(name))
    }
}
