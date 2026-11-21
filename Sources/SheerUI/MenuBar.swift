import SwiftUI

public struct MenuBarLabel: View {
    var systemImage: String?
    var value: Text?
    var attention: Bool
    var reserve: Text?

    public init(systemImage: String? = nil, value: Text? = nil, attention: Bool = false, reserve: Text? = nil) {
        self.systemImage = systemImage
        self.value = value
        self.attention = attention
        self.reserve = reserve
    }

    public var body: some View {
        HStack(spacing: 4) {
            if let systemImage { Image(systemName: systemImage) }
            if value != nil || reserve != nil {
                ZStack(alignment: .trailing) {
                    reserve.hidden()
                    value
                }
            }
        }
        .font(.system(size: 12, weight: .medium))
        .monospacedDigit()
        .foregroundStyle(attention ? AnyShapeStyle(Color(nsColor: .systemOrange)) : AnyShapeStyle(.primary))
        .fixedSize()
        .accessibilityElement(children: .combine)
    }
}

public struct MenuBarPanel<Content: View>: View {
    @ViewBuilder let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Group(subviews: content) { sections in
                ForEach(sections) { section in
                    if section.id != sections.first?.id {
                        Rectangle().fill(.hairline).frame(height: 1).frame(height: 14)
                    }
                    section
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(16)
        .frame(width: 320)
        .background(.sheet)
    }
}

public struct MenuBarSection<Trailing: View, Content: View>: View {
    let title: Text
    @ViewBuilder let trailing: Trailing
    @ViewBuilder let content: Content

    public init(title: Text, @ViewBuilder trailing: () -> Trailing, @ViewBuilder content: () -> Content) {
        self.title = title
        self.trailing = trailing()
        self.content = content()
    }

    public init(title: LocalizedStringKey, @ViewBuilder trailing: () -> Trailing, @ViewBuilder content: () -> Content) {
        self.init(title: Text(title), trailing: trailing, content: content)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                title
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 8)
                trailing
            }
            content
        }
    }
}

extension MenuBarSection where Trailing == EmptyView {
    public init(title: Text, @ViewBuilder content: () -> Content) {
        self.init(title: title, trailing: { EmptyView() }, content: content)
    }

    public init(title: LocalizedStringKey, @ViewBuilder content: () -> Content) {
        self.init(title: Text(title), content: content)
    }
}
