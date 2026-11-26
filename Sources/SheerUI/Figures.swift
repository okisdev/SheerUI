import SwiftUI

public struct Figures<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 24, alignment: .topLeading)], alignment: .leading, spacing: 16) {
            content
        }
    }
}

public struct Figure: View {
    private let label: Text
    private let value: Text
    private let detail: Text?
    private let warning: Bool
    private let action: (() -> Void)?

    public init(label: Text, value: Text, detail: Text? = nil, warning: Bool = false, action: (() -> Void)? = nil) {
        self.label = label
        self.value = value
        self.detail = detail
        self.warning = warning
        self.action = action
    }

    public init(label: LocalizedStringKey, value: Text, detail: Text? = nil, warning: Bool = false, action: (() -> Void)? = nil) {
        self.init(label: Text(label), value: value, detail: detail, warning: warning, action: action)
    }

    public var body: some View {
        if let action {
            Button(action: action) {
                FigureContent(label: label, value: value, detail: detail, warning: warning)
            }
            .buttonStyle(FigureButtonStyle())
        } else {
            FigureContent(label: label, value: value, detail: detail, warning: warning)
        }
    }
}

private struct FigureContent: View {
    let label: Text
    let value: Text
    let detail: Text?
    let warning: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            label.font(.rowMeta).foregroundStyle(.secondary)
            value
                .font(.figure())
                .monospacedDigit()
                .contentTransition(.numericText())
                .foregroundStyle(warning ? ChartPalette.color(2) : AnyShapeStyle(.primary))
            if let detail {
                detail.font(.rowMeta).foregroundStyle(.secondary)
            }
        }
        .lineLimit(1)
        .padding(10)
        .frame(minWidth: 150, maxWidth: .infinity, alignment: .topLeading)
        .contentShape(.rect(cornerRadius: 10))
        .accessibilityElement(children: .combine)
    }
}

private struct FigureButtonStyle: ButtonStyle {
    @State private var hovering = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(.hoverFill.opacity(hovering || configuration.isPressed ? 1 : 0), in: .rect(cornerRadius: 10))
            .onHover { hovering = $0 }
    }
}
