import SwiftUI

/// A command that loses data or work, for the last group of a menu after a separator: red, its title ending in an ellipsis because it always asks first. The action opens the caller's confirmation; it never performs the loss itself.
public struct DestructiveButton: View {
    let title: Text
    var systemImage: String?
    let action: () -> Void

    public init(_ title: Text, systemImage: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    public init(_ title: LocalizedStringKey, systemImage: String? = nil, action: @escaping () -> Void) {
        self.init(Text(title), systemImage: systemImage, action: action)
    }

    public var body: some View {
        Button(role: .destructive, action: action) {
            if let systemImage {
                Label {
                    title.foregroundStyle(.red)
                } icon: {
                    Image(systemName: systemImage).foregroundStyle(.red)
                }
            } else {
                title.foregroundStyle(.red)
            }
        }
    }
}
