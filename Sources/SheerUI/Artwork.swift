import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// What a row is, drawn as the thing itself: the system's own picture of a product, this Mac, a brand's mark in its color, or a symbol for a kind.
public enum Artwork: Hashable, Sendable {
    /// A type identifier whose system icon pictures the product, such as `com.apple.studio-display`.
    case product(String)
    case computer
    /// The icon the system shows for a file, folder or app on this Mac, such as an app bundle's own icon.
    case file(URL)
    case mark(BrandMark)
    case symbol(String)
    /// A picture a person supplied by address; `fallback` shows until it loads and when it cannot.
    indirect case image(URL, fallback: Artwork)
}

/// A one path mark on a 24 point grid with its brand color.
public struct BrandMark: Hashable, Sendable {
    public let path: String
    public let hex: UInt32

    public init(path: String, hex: UInt32) {
        self.path = path
        self.hex = hex
    }

    /// The brand color, or the primary text color when the brand color would vanish on the sheet in this appearance.
    func color(in scheme: ColorScheme) -> Color {
        let red = Double((hex >> 16) & 0xFF) / 255, green = Double((hex >> 8) & 0xFF) / 255, blue = Double(hex & 0xFF) / 255
        let luminance = 0.2126 * red + 0.7152 * green + 0.0722 * blue
        let vanishes = scheme == .dark ? luminance < 0.12 : luminance > 0.7
        return vanishes ? .primary : Color(red: red, green: green, blue: blue)
    }

    @MainActor private static var images: [String: NSImage] = [:]

    @MainActor var image: NSImage {
        if let image = Self.images[path] { return image }
        let svg = #"<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="\#(path)"/></svg>"#
        let image = NSImage(data: Data(svg.utf8)) ?? NSImage()
        image.isTemplate = true
        Self.images[path] = image
        return image
    }
}

/// An `Artwork` at one size, with an optional state dot on its trailing foot. Marks and symbols sit inside the frame the way the system's product icons do, so a column of mixed artwork lines up.
public struct ArtworkView: View {
    let artwork: Artwork
    var size: CGFloat
    var badge: Color?
    @Environment(\.colorScheme) private var scheme

    public init(_ artwork: Artwork, size: CGFloat = Metrics.rowArtwork, badge: Color? = nil) {
        self.artwork = artwork
        self.size = size
        self.badge = badge
    }

    public var body: some View {
        picture
            .frame(width: size, height: size)
            .overlay(alignment: .bottomTrailing) {
                if let badge {
                    StateDot(color: badge)
                        .background(Circle().fill(.sheet).padding(-2))
                        .offset(x: 2, y: 1)
                }
            }
            .accessibilityHidden(true)
    }

    @ViewBuilder private var picture: some View {
        switch artwork {
        case .product(let identifier):
            Image(nsImage: NSWorkspace.shared.icon(for: UTType(identifier) ?? .item))
                .resizable()
                .interpolation(.high)
        case .computer:
            Image(nsImage: NSImage(named: NSImage.computerName) ?? NSImage())
                .resizable()
                .interpolation(.high)
        case .file(let url):
            Image(nsImage: FileIcons.icon(for: url))
                .resizable()
                .interpolation(.high)
        case .mark(let mark):
            Image(nsImage: mark.image)
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(mark.color(in: scheme))
                .padding(size * 0.14)
        case .symbol(let name):
            Image(systemName: name)
                .font(.system(size: size * 0.56))
                .foregroundStyle(.secondary)
        case .image(let url, let fallback):
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image.resizable().interpolation(.high).scaledToFit()
                } else {
                    ArtworkView(fallback, size: size)
                }
            }
        }
    }
}

/// File icons read once per path, because the system builds every resolution of an icon on each request.
@MainActor enum FileIcons {
    private static let cache = NSCache<NSURL, NSImage>()

    static func icon(for url: URL) -> NSImage {
        if let image = cache.object(forKey: url as NSURL) { return image }
        let image = NSWorkspace.shared.icon(forFile: url.path)
        cache.setObject(image, forKey: url as NSURL)
        return image
    }
}
