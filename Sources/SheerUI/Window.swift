import AppKit
import SwiftUI

/// The window's own light, translucent material behind the sidebar, so the desktop shows faintly through the chrome without darkening it, while the page stays solid.
public struct WindowMaterial: NSViewRepresentable {
    public init() {}

    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .underWindowBackground
        view.blendingMode = .behindWindow
        view.state = .followsWindowActiveState
        return view
    }

    public func updateNSView(_ view: NSVisualEffectView, context: Context) {}
}

extension View {
    /// The window's chrome: its translucent material under a light veil, so the desktop only tints the sidebar instead of darkening it.
    public func windowChromeBackground() -> some View {
        background {
            WindowMaterial()
                .overlay(
                    Color(
                        nsColor: NSColor(name: nil) { appearance in
                            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
                                ? NSColor.windowBackgroundColor.withAlphaComponent(0.45)
                                : NSColor.white.withAlphaComponent(0.62)
                        })
                )
                .ignoresSafeArea()
        }
    }
}

extension View {
    /// Lets the content run under a hidden title bar and gives the window controls room in the sidebar strip.
    public func windowChrome() -> some View {
        background(WindowChrome())
    }
}

/// Places the window controls as far from the leading edge as from the top of the sidebar strip.
///
/// AppKit lays the controls out for a bare 28 point title bar and does so again whenever the title or toolbar changes, so the controls are moved back each time their frames change.
private struct WindowChrome: NSViewRepresentable {
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { context.coordinator.attach(to: view.window) }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async { context.coordinator.attach(to: nsView.window) }
    }

    @MainActor
    final class Coordinator {
        private weak var window: NSWindow?
        private var observers: [NSObjectProtocol] = []

        func attach(to window: NSWindow?) {
            guard let window, self.window !== window else { return }
            self.window = window
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.styleMask.insert(.fullSizeContentView)
            window.titlebarSeparatorStyle = .none
            placeControls()
            let names: [Notification.Name] = [
                NSWindow.didResizeNotification,
                NSWindow.didEndLiveResizeNotification,
                NSWindow.didExitFullScreenNotification,
                NSWindow.didBecomeKeyNotification,
                NSWindow.didResignKeyNotification
            ]
            observers = names.map { name in
                NotificationCenter.default.addObserver(forName: name, object: window, queue: .main) { [weak self] _ in
                    MainActor.assumeIsolated { self?.placeControls() }
                }
            }
            // A new title lays the title bar out again after the change, so the controls are placed
            // once that pass has run.
            titleObservation = window.observe(\.title, options: [.new]) { [weak self] _, _ in
                DispatchQueue.main.async { MainActor.assumeIsolated { self?.placeControls() } }
            }
            watchControls()
        }

        private var placing = false
        private var titleObservation: NSKeyValueObservation?
        private var frameObservers: [NSObjectProtocol] = []
        private var watched: [ObjectIdentifier] = []

        /// Follows the frames of the controls and their container, and follows the new ones when
        /// AppKit replaces them, which it does when it rebuilds the title bar.
        private func watchControls() {
            guard let window else { return }
            let views = [window.standardWindowButton(.closeButton), window.standardWindowButton(.closeButton)?.superview?.superview].compactMap { $0 }
            let identities = views.map(ObjectIdentifier.init)
            guard identities != watched else { return }
            watched = identities
            for observer in frameObservers { NotificationCenter.default.removeObserver(observer) }
            frameObservers = views.map { view in
                view.postsFrameChangedNotifications = true
                return NotificationCenter.default.addObserver(forName: NSView.frameDidChangeNotification, object: view, queue: .main) { [weak self] _ in
                    MainActor.assumeIsolated { self?.placeControls() }
                }
            }
        }

        private func placeControls() {
            guard
                !placing,
                let window,
                let close = window.standardWindowButton(.closeButton),
                let titlebar = close.superview,
                let container = titlebar.superview,
                !window.styleMask.contains(.fullScreen)
            else { return }
            placing = true
            defer { placing = false }
            watchControls()
            let height = Metrics.sidebarTop - 6
            var frame = container.frame
            frame.size.height = height
            frame.origin.y = window.frame.height - height
            container.frame = frame
            titlebar.frame = container.bounds
            let inset = (height - close.frame.height) / 2
            let shift = inset - close.frame.minX
            for type in [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton] {
                guard let button = window.standardWindowButton(type) else { continue }
                button.setFrameOrigin(NSPoint(x: button.frame.minX + shift, y: (height - button.frame.height) / 2))
            }
        }

        isolated deinit {
            for observer in observers + frameObservers { NotificationCenter.default.removeObserver(observer) }
        }
    }
}

extension View {
    /// Sets a page on the sheet: the bright rounded surface inset from the window's edges.
    public func sheetSurface() -> some View {
        self
            .background(.sheet, in: .rect(cornerRadius: Metrics.sheetRadius, style: .continuous))
            .clipShape(.rect(cornerRadius: Metrics.sheetRadius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Metrics.sheetRadius, style: .continuous).strokeBorder(.hairline))
            .padding([.top, .trailing, .bottom], Metrics.sheetInset)
    }
}
