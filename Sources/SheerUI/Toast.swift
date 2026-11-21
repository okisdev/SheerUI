import AppKit
import Observation
import SwiftUI

/// A short confirmation for an action whose result does not show where the person is, such as a copy or an export.
public struct Toast: Identifiable, Equatable, Sendable {
    public let id = UUID()
    public let title: String
    public let systemImage: String
}

/// The toast on screen, shared by every window; the key window draws it.
@MainActor @Observable
public final class Toasts {
    public static let shared = Toasts()
    public private(set) var current: Toast?
    private var dismissal: Task<Void, Never>?

    public func show(_ title: String, systemImage: String = "checkmark.circle.fill") {
        let toast = Toast(title: title, systemImage: systemImage)
        current = toast
        dismissal?.cancel()
        dismissal = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1.8))
            guard !Task.isCancelled, self?.current?.id == toast.id else { return }
            self?.current = nil
        }
    }
}

/// Copies text and says so with a toast.
public enum Clipboard {
    @MainActor public static func copy(_ text: String, toast title: String? = nil) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        Toasts.shared.show(title ?? String(localized: "Copied", bundle: .module), systemImage: "doc.on.doc.fill")
    }
}

extension View {
    /// Draws the shared toast at the bottom centre of this window while it is the key window.
    public func toastHost() -> some View {
        overlay(alignment: .bottom) { ToastHost() }
    }
}

private struct ToastHost: View {
    @Environment(\.controlActiveState) private var activeState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var toasts = Toasts.shared

    var body: some View {
        ZStack {
            if activeState == .key, let toast = toasts.current {
                HStack(spacing: 8) {
                    Image(systemName: toast.systemImage)
                        .foregroundStyle(.secondary)
                    Text(toast.title)
                        .font(.callout.weight(.medium))
                        .lineLimit(1)
                }
                .padding(.horizontal, 16)
                .frame(height: 36)
                .background(.regularMaterial, in: .capsule)
                .overlay(Capsule().strokeBorder(Color.hairline))
                .shadow(color: .black.opacity(0.14), radius: 16, y: 6)
                .id(toast.id)
                .transition(.opacity.combined(with: .offset(y: reduceMotion ? 0 : 10)).combined(with: .scale(scale: reduceMotion ? 1 : 0.96)))
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.updatesFrequently)
                .onAppear { AccessibilityNotification.Announcement(toast.title).post() }
            }
        }
        .padding(.bottom, 28)
        .animation(reduceMotion ? .easeOut(duration: 0.1) : .spring(duration: 0.3, bounce: 0), value: toasts.current)
        .allowsHitTesting(false)
    }
}
