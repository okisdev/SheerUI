import AppKit
import SwiftUI

public struct CardsFormStyle: FormStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        CardsFormBody(content: configuration.content)
            .scrollContentBackground(.hidden)
            .labelStyle(SettingsLabelStyle())
            .labeledContentStyle(SettingsRowStyle())
            .toggleStyle(SettingsToggleStyle())
            .textFieldStyle(.plain)
    }
}

extension EnvironmentValues {
    /// Set by a container that scrolls and sizes the form itself, such as a form sheet.
    @Entry var cardsFormEmbedded = false
}

private struct CardsFormBody: View {
    let content: FormStyleConfiguration.Content
    @Environment(\.cardsFormEmbedded) private var embedded

    var body: some View {
        if embedded {
            sections
        } else {
            ScrollView {
                sections
                    .padding(.top, 8)
                    .padding(.bottom, 24)
            }
        }
    }

    private var sections: some View {
        VStack(alignment: .leading, spacing: Metrics.sectionSpacing) {
            ForEach(sections: content) { section in
                SettingsSection(section: section)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Metrics.pageInset)
    }
}

extension FormStyle where Self == CardsFormStyle {
    public static var cards: CardsFormStyle { CardsFormStyle() }
}

public struct SettingsNotice<Action: View>: View {
    let text: Text
    var systemImage = "arrow.clockwise.circle.fill"
    var tint: Color = .orange
    @ViewBuilder let action: Action

    public init(text: Text, systemImage: String = "arrow.clockwise.circle.fill", tint: Color = .orange, @ViewBuilder action: () -> Action) {
        self.text = text
        self.systemImage = systemImage
        self.tint = tint
        self.action = action()
    }

    public var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
                .accessibilityHidden(true)
            text
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            action
                .controlSize(.small)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(tint.opacity(0.12), in: .rect(cornerRadius: 10))
    }
}

public struct SettingsSliderRow: View {
    let title: Text
    let systemImage: String
    let valueText: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var onCommit: () -> Void = {}

    public init(
        title: LocalizedStringKey, systemImage: String, valueText: String, value: Binding<Double>, range: ClosedRange<Double>,
        onCommit: @escaping () -> Void = {}
    ) {
        self.init(title: Text(title), systemImage: systemImage, valueText: valueText, value: value, range: range, onCommit: onCommit)
    }

    public init(
        title: Text, systemImage: String, valueText: String, value: Binding<Double>, range: ClosedRange<Double>,
        onCommit: @escaping () -> Void = {}
    ) {
        self.title = title
        self.systemImage = systemImage
        self.valueText = valueText
        self._value = value
        self.range = range
        self.onCommit = onCommit
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label {
                    title
                } icon: {
                    Image(systemName: systemImage)
                }
                Spacer()
                Text(valueText)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Slider(value: $value, in: range) { editing in
                if !editing { onCommit() }
            }
            .accessibilityLabel(title)
        }
    }
}

private struct SettingsSection: View {
    let section: SectionConfiguration

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !section.header.isEmpty {
                section.header
                    .font(.sectionLabel)
                    .foregroundStyle(.primary)
                    .accessibilityAddTraits(.isHeader)
            }
            if !section.content.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(section.content.enumerated()), id: \.offset) { index, row in
                        row
                            .padding(.vertical, 7)
                            .frame(maxWidth: .infinity, minHeight: Metrics.rowHeight + 6, alignment: .leading)
                        if index < section.content.count - 1 {
                            Rectangle().fill(.hairline).frame(height: 1)
                        }
                    }
                }
                .padding(.horizontal, Metrics.cardInset)
                .padding(.vertical, 2)
                .background(.groupFill, in: .rect(cornerRadius: Metrics.groupRadius, style: .continuous))
            }
            if !section.footer.isEmpty {
                section.footer
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

/// SF Symbols differ in width, so every icon gets the same column to keep titles aligned.
private struct SettingsLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 10) {
            configuration.icon
                .foregroundStyle(.secondary)
                .frame(width: 22)
            configuration.title
        }
    }
}

private struct SettingsRowStyle: LabeledContentStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 12) {
            configuration.label
                .frame(maxWidth: .infinity, alignment: .leading)
            configuration.content
                .foregroundStyle(.secondary)
        }
    }
}

private struct SettingsToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        LabeledContent {
            Toggle(isOn: configuration.$isOn) {}
                .labelsHidden()
                .toggleStyle(.switch)
        } label: {
            configuration.label
        }
    }
}

/// A row of an Info tab: the label, then a value that copies itself when clicked.
public struct InfoRow: View {
    let label: Text
    let value: String
    var monospaced = false

    public init(label: Text, value: String, monospaced: Bool = false) {
        self.label = label
        self.value = value
        self.monospaced = monospaced
    }

    public init(label: LocalizedStringKey, value: String, monospaced: Bool = false) {
        self.init(label: Text(label), value: value, monospaced: monospaced)
    }

    public var body: some View {
        LabeledContent {
            Button {
                Clipboard.copy(value)
            } label: {
                Text(value)
                    .font(monospaced ? .body.monospaced() : .body)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .textSelection(.enabled)
            }
            .buttonStyle(.plain)
            .help(String(localized: "Copy", bundle: .module))
        } label: {
            label
        }
    }
}

/// A key and value table inside an Info tab, such as labels, environment or mounts.
public struct KeyValueTable: View {
    let keyTitle: Text
    let valueTitle: Text
    let pairs: [(key: String, value: String)]

    public init(keyTitle: Text, valueTitle: Text, pairs: [(key: String, value: String)]) {
        self.keyTitle = keyTitle
        self.valueTitle = valueTitle
        self.pairs = pairs
    }

    public init(keyTitle: LocalizedStringKey, valueTitle: LocalizedStringKey, pairs: [(key: String, value: String)]) {
        self.init(keyTitle: Text(keyTitle), valueTitle: Text(valueTitle), pairs: pairs)
    }

    public var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 6) {
            GridRow {
                keyTitle
                valueTitle
            }
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)
            ForEach(Array(pairs.enumerated()), id: \.offset) { _, pair in
                GridRow {
                    Text(pair.key).lineLimit(1).truncationMode(.middle)
                    Text(pair.value).foregroundStyle(.secondary).lineLimit(1).truncationMode(.middle)
                }
                .textSelection(.enabled)
            }
        }
    }
}
