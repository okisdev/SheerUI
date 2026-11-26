import SwiftUI

/// A sheet that shows rather than completes, such as logs or output: its title over one line of subtitle, the content's own controls, then a round close button bound to Escape, all on one row whose corner sits as far from the top as from the side. The content's `tabAccessory` controls are drawn in that row.
public struct ViewerSheet<Content: View>: View {
    let title: Text
    var subtitle: Text?
    var width: CGFloat?
    @ViewBuilder let content: Content
    @Environment(\.dismiss) private var dismiss

    public init(title: Text, subtitle: Text? = nil, width: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.width = width
        self.content = content()
    }

    public init(title: LocalizedStringKey, subtitle: LocalizedStringKey? = nil, width: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.init(title: Text(title), subtitle: subtitle.map { Text($0) }, width: width, content: content)
    }

    /// A viewer named by data, such as a file's name, shown as is.
    @_disfavoredOverload
    public init(title: some StringProtocol, subtitle: (some StringProtocol)? = String?.none, width: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.init(title: Text(title), subtitle: subtitle.map { Text($0) }, width: width, content: content)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 1) {
                    title
                        .font(.headline)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    if let subtitle {
                        subtitle
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 12)
                Button(String(localized: "Close", bundle: .module), systemImage: "xmark") { dismiss() }
                    .buttonStyle(.circle)
                    .keyboardShortcut(.cancelAction)
                    .help(String(localized: "Close", bundle: .module))
            }
            .frame(height: Metrics.control)
            .padding(.horizontal, Metrics.pageInset)
            .padding(.top, Metrics.pageInset)
            content
                .environment(\.hostsTabAccessory, true)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .overlayPreferenceValue(TabAccessoryKey.self, alignment: .topTrailing) { accessory in
            if let accessory {
                HStack(spacing: 8) { accessory.view }
                    .buttonStyle(.circle)
                    .frame(height: Metrics.control)
                    .padding(.top, Metrics.pageInset)
                    .padding(.trailing, Metrics.pageInset + Metrics.control + 8)
            }
        }
        .background(.sheet)
        .frame(minWidth: width ?? 720, idealWidth: width ?? 900, maxWidth: width, minHeight: 460, idealHeight: 620)
    }
}
