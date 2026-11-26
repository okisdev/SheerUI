import SwiftUI

/// A sheet that completes something: its title over one line saying what it makes, level with the sheet's corner like a page header, the form as cards sized to what it holds (scrolling only past the window's reach), then a footer with at most one secondary command on the leading side and Cancel (or the sheet's own word for leaving, such as Later) and the one finishing command on the trailing side. Escape cancels and Return finishes; while it works, the footer shows the work and the sheet cannot be dismissed.
public struct FormSheet<Content: View, Secondary: View>: View {
    let title: Text
    var subtitle: Text?
    let action: Text
    var cancel: Text?
    var canFinish: Bool
    var working: Text?
    var width: CGFloat
    let finish: () -> Void
    @ViewBuilder let secondary: Secondary
    @ViewBuilder let content: Content
    @Environment(\.dismiss) private var dismiss
    @State private var contentHeight: CGFloat = 0

    public init(
        title: LocalizedStringKey, subtitle: LocalizedStringKey? = nil, action: LocalizedStringKey, cancel: LocalizedStringKey? = nil, canFinish: Bool = true,
        working: LocalizedStringKey? = nil,
        width: CGFloat = 560, finish: @escaping () -> Void, @ViewBuilder secondary: () -> Secondary, @ViewBuilder content: () -> Content
    ) {
        self.init(
            title: Text(title), subtitle: subtitle.map { Text($0) }, action: Text(action), cancel: cancel.map { Text($0) }, canFinish: canFinish,
            working: working.map { Text($0) },
            width: width, finish: finish, secondary: secondary, content: content)
    }

    public init(
        title: Text, subtitle: Text? = nil, action: Text, cancel: Text? = nil, canFinish: Bool = true, working: Text? = nil,
        width: CGFloat = 560, finish: @escaping () -> Void, @ViewBuilder secondary: () -> Secondary, @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.action = action
        self.cancel = cancel
        self.canFinish = canFinish
        self.working = working
        self.width = width
        self.finish = finish
        self.secondary = secondary()
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 1) {
                title.font(.headline).lineLimit(1)
                if let subtitle {
                    subtitle.font(.subheadline).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(minHeight: Metrics.control)
            .padding(.horizontal, Metrics.pageInset)
            .padding(.top, Metrics.pageInset)
            .padding(.bottom, 16)
            ScrollView {
                content
                    .environment(\.cardsFormEmbedded, true)
                    .formStyle(.cards)
                    .onGeometryChange(for: CGFloat.self) {
                        $0.size.height
                    } action: {
                        contentHeight = $0
                    }
            }
            .scrollBounceBehavior(.basedOnSize)
            .frame(height: min(max(contentHeight, 1), 560))
            HStack(spacing: 8) {
                secondary
                    .buttonStyle(.capsule)
                    .disabled(working != nil)
                Spacer(minLength: 12)
                if let working {
                    HStack(spacing: 8) {
                        DotMatrix()
                        working.font(.callout).foregroundStyle(.secondary).lineLimit(1)
                    }
                    .transition(.opacity)
                }
                Button(role: .cancel) {
                    dismiss()
                } label: {
                    cancel ?? Text(String(localized: "Cancel", bundle: .module))
                }
                .buttonStyle(.capsule)
                .keyboardShortcut(.cancelAction)
                .disabled(working != nil)
                Button(action: finish) { action }
                    .buttonStyle(.inkCapsule)
                    .keyboardShortcut(.defaultAction)
                    .disabled(!canFinish || working != nil)
            }
            .padding(.horizontal, Metrics.pageInset)
            .padding(.top, 20)
            .padding(.bottom, Metrics.pageInset)
            .animation(.easeOut(duration: 0.15), value: working != nil)
        }
        .frame(width: width)
        .background(.sheet)
        .interactiveDismissDisabled(working != nil)
    }
}

extension FormSheet where Secondary == EmptyView {
    public init(
        title: Text, subtitle: Text? = nil, action: Text, cancel: Text? = nil, canFinish: Bool = true, working: Text? = nil, width: CGFloat = 560,
        finish: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            title: title, subtitle: subtitle, action: action, cancel: cancel, canFinish: canFinish, working: working, width: width, finish: finish,
            secondary: { EmptyView() },
            content: content)
    }

    public init(
        title: LocalizedStringKey, subtitle: LocalizedStringKey? = nil, action: LocalizedStringKey, cancel: LocalizedStringKey? = nil, canFinish: Bool = true,
        working: LocalizedStringKey? = nil,
        width: CGFloat = 560, finish: @escaping () -> Void, @ViewBuilder content: () -> Content
    ) {
        self.init(
            title: title, subtitle: subtitle, action: action, cancel: cancel, canFinish: canFinish, working: working, width: width, finish: finish,
            secondary: { EmptyView() },
            content: content)
    }
}

/// A text setting in a card: the label leading and a borderless field trailing, its text in the primary ink.
public struct FieldRow: View {
    let title: Text
    @Binding var text: String
    var prompt: String
    var monospaced: Bool
    var autofocus: Bool
    @FocusState private var focused: Bool

    public init(_ title: LocalizedStringKey, text: Binding<String>, prompt: String = "", monospaced: Bool = false, autofocus: Bool = false) {
        self.init(Text(title), text: text, prompt: prompt, monospaced: monospaced, autofocus: autofocus)
    }

    public init(_ title: Text, text: Binding<String>, prompt: String = "", monospaced: Bool = false, autofocus: Bool = false) {
        self.title = title
        _text = text
        self.prompt = prompt
        self.monospaced = monospaced
        self.autofocus = autofocus
    }

    public var body: some View {
        LabeledContent {
            TextField(text: $text, prompt: Text(verbatim: prompt)) { title }
                .labelsHidden()
                .textFieldStyle(.plain)
                .multilineTextAlignment(.trailing)
                .font(monospaced ? .body.monospaced() : .body)
                .foregroundStyle(.primary)
                .focused($focused)
        } label: {
            title
        }
        .onAppear { if autofocus { focused = true } }
    }
}

/// How far a long piece of work has come: a thin capsule track filled to the fraction, with one meta line under it.
public struct ProgressLine: View {
    let fraction: Double?
    let status: String

    public init(fraction: Double?, status: String) {
        self.fraction = fraction
        self.status = status
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { proxy in
                Capsule()
                    .fill(Color.primary.opacity(0.08))
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(.tint)
                            .frame(width: proxy.size.width * min(1, max(0, fraction ?? 0)))
                            .animation(.easeOut(duration: 0.25), value: fraction)
                    }
            }
            .frame(height: 4)
            Text(status)
                .font(.rowMeta)
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .lineLimit(1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(status))
        .accessibilityValue(fraction.map { $0.formatted(.percent.precision(.fractionLength(0))) } ?? "")
    }
}
