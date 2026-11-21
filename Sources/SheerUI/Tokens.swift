import AppKit
import SwiftUI

/// Every fixed length the app draws with.
public enum Metrics {
    public static let cardRadius: CGFloat = 16
    public static let cardInset: CGFloat = 12
    public static let pagePadding: CGFloat = 24
    public static let sectionSpacing: CGFloat = 20
    public static let rowHeight: CGFloat = 36
    public static let columnWidth: CGFloat = 640
    public static let editorHeight: CGFloat = 160

    public static let sidebarWidth: CGFloat = 220
    public static let sidebarRowHeight: CGFloat = 32
    public static let sidebarTop: CGFloat = 52
    public static let sheetInset: CGFloat = 8
    public static let sheetRadius: CGFloat = 14
    public static let pageInset: CGFloat = 28
    /// A header's top padding, set so the controls at its trailing corner sit as far from the top edge as from the side.
    public static let pageTop: CGFloat = pageInset - (headerHeight - control) / 2
    public static let headerHeight: CGFloat = 32
    public static let listRowHeight: CGFloat = 44
    public static let control: CGFloat = 30
    public static let rowControl: CGFloat = 26
    public static let groupRadius: CGFloat = 14
    public static let nestedRowHeight: CGFloat = 36
    public static let disclosureColumn: CGFloat = 14
    public static let rowArtwork: CGFloat = 28
    public static let nestedRowArtwork: CGFloat = 22
    public static let headerArtwork: CGFloat = 26
}

/// The app's grounds: the window behind the sidebar, and the sheet the selected page sits on.
extension ShapeStyle where Self == Color {
    public static var settingsPage: Color { Color(nsColor: .windowBackgroundColor) }
    public static var settingsCard: Color { Color.primary.opacity(0.045) }
    public static var sheet: Color { Color(nsColor: .textBackgroundColor) }
    public static var controlFill: Color { Color.primary.opacity(0.06) }
    public static var hoverFill: Color { Color.primary.opacity(0.045) }
    public static var selectedFill: Color { Color.primary.opacity(0.08) }
    public static var hairline: Color { Color.primary.opacity(0.07) }
    public static var groupFill: Color { Color.primary.opacity(0.035) }
}

/// The text roles the window's chrome and rows use, so every page sets type the same way.
extension Font {
    public static let navigation = Font.body
    public static let pageTitle = Font.title2.weight(.semibold)
    public static let rowTitle = Font.body
    public static let rowMeta = Font.subheadline
    public static let sectionLabel = Font.headline
    /// A figure that answers the page, such as a count or a price, in the design the person chose for numbers.
    public static func figure(design: Font.Design = .default) -> Font { .system(size: 20, weight: .medium, design: design) }
}
