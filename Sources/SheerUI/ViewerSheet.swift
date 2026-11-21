import SwiftUI

/// A sheet that shows rather than completes, such as logs or output: its title over one line of subtitle, the content's own controls, then a round close button bound to Escape, all on one row whose corner sits as far from the top as from the side. The content's `tabAccessory` controls are drawn in that row.
public struct ViewerSheet<Content: View>: View {
    let title: String
    var subtitle: String?
    @ViewBuilder let content: Content
    @Environment(\.dismiss) private var dismiss

    public init(title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.headline)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    if let subtitle {
                        Text(subtitle)
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
        .frame(minWidth: 720, idealWidth: 900, minHeight: 460, idealHeight: 620)
    }
}
