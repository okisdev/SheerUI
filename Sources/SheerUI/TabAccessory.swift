import SwiftUI

extension EnvironmentValues {
    /// Whether the view sits under a tab row that holds the view's own controls.
    @Entry public var hostsTabAccessory = false
}

/// The controls of the chosen tab, carried up to the right end of its tab row.
public struct TabAccessoryKey: PreferenceKey {
    public static var defaultValue: TabAccessory? { nil }
    public static func reduce(value: inout TabAccessory?, nextValue: () -> TabAccessory?) { value = nextValue() ?? value }
}

public struct TabAccessory: Equatable {
    public let id: String
    public let view: AnyView
    public static func == (lhs: Self, rhs: Self) -> Bool { false }
}

extension View {
    /// Puts a tab's controls at the right end of the tab row above it, or above the view when no tab row holds it.
    public func tabAccessory<Accessory: View>(_ id: String, @ViewBuilder _ accessory: () -> Accessory) -> some View {
        modifier(TabAccessoryPlacement(id: id, accessory: accessory()))
    }
}

private struct TabAccessoryPlacement<Accessory: View>: ViewModifier {
    let id: String
    let accessory: Accessory
    @Environment(\.hostsTabAccessory) private var hosted

    func body(content: Content) -> some View {
        if hosted {
            content.preference(key: TabAccessoryKey.self, value: TabAccessory(id: id, view: AnyView(accessory)))
        } else {
            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    Spacer(minLength: 0)
                    accessory
                }
                .buttonStyle(.circle)
                .frame(height: Metrics.control)
                .padding(.horizontal, Metrics.pageInset)
                content
            }
        }
    }
}
