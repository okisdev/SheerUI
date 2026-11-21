import SwiftUI

/// The first line of a page, written into the sheet rather than drawn as a bar: the page's name, or its views as capsule tabs when it has several, or the path to an opened row whose first step leads back and whose last carries the row's artwork; then its count, its commands as round glyphs and its search. Its empty space drags the window.
public struct PageHeader<Trailing: View>: View {
    let title: Text
    var subject: Text?
    var artwork: Artwork?
    var meta: Text?
    var back: (() -> Void)?
    @ViewBuilder let trailing: Trailing
    @Environment(\.pageAccessory) private var accessory
    @Environment(\.detailInWindow) private var inWindow

    public init(title: Text, subject: Text? = nil, artwork: Artwork? = nil, meta: Text? = nil, back: (() -> Void)? = nil, @ViewBuilder trailing: () -> Trailing)
    {
        self.title = title
        self.subject = subject
        self.artwork = artwork
        self.meta = meta
        self.back = back
        self.trailing = trailing()
    }

    public init(
        title: LocalizedStringKey, subject: Text? = nil, artwork: Artwork? = nil, meta: Text? = nil, back: (() -> Void)? = nil,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.init(title: Text(title), subject: subject, artwork: artwork, meta: meta, back: back, trailing: trailing)
    }

    public var body: some View {
        HStack(spacing: 14) {
            location
            Spacer(minLength: 12)
            HStack(spacing: 8) { trailing }
                .buttonStyle(.circle)
        }
        .frame(height: Metrics.headerHeight)
        .padding(.leading, inWindow ? 84 : Metrics.pageInset)
        .padding(.trailing, Metrics.pageInset)
        .padding(.top, inWindow ? 7 : Metrics.pageTop)
        .background {
            Color.clear
                .contentShape(.rect)
                .gesture(WindowDragGesture())
                .allowsWindowActivationEvents(true)
        }
    }

    @ViewBuilder private var location: some View {
        if let subject, !inWindow {
            HStack(spacing: 8) {
                Button(action: { back?() }) {
                    title.foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help(Text("Back to \(title)", bundle: .module))
                Text(verbatim: "/").foregroundStyle(.tertiary)
                if let artwork { ArtworkView(artwork, size: Metrics.headerArtwork) }
                subject
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .font(.pageTitle)
        } else if let subject {
            HStack(spacing: 8) {
                if let artwork { ArtworkView(artwork, size: Metrics.headerArtwork) }
                subject
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .font(.pageTitle)
        } else {
            HStack(alignment: .center, spacing: 10) {
                if let accessory {
                    accessory
                } else {
                    title
                        .font(.pageTitle)
                        .accessibilityAddTraits(.isHeader)
                }
                if let meta {
                    meta
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
            }
            .lineLimit(1)
        }
    }
}

extension PageHeader where Trailing == EmptyView {
    public init(title: Text, subject: Text? = nil, artwork: Artwork? = nil, meta: Text? = nil, back: (() -> Void)? = nil) {
        self.init(title: title, subject: subject, artwork: artwork, meta: meta, back: back) { EmptyView() }
    }

    public init(title: LocalizedStringKey, subject: Text? = nil, artwork: Artwork? = nil, meta: Text? = nil, back: (() -> Void)? = nil) {
        self.init(title: Text(title), subject: subject, artwork: artwork, meta: meta, back: back) { EmptyView() }
    }
}
