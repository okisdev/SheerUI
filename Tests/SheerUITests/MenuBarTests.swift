import SwiftUI
import Testing

@testable import SheerUI

@MainActor
struct MenuBarTests {
    @Test(arguments: [nil, "1", "12", "999"])
    func reservesValueWidth(_ value: String?) throws {
        let reserve = Text(verbatim: "999")
        let expected = try size(MenuBarLabel(systemImage: "bolt.fill", value: reserve, reserve: reserve))
        let actual = try size(MenuBarLabel(systemImage: "bolt.fill", value: value.map { Text(verbatim: $0) }, reserve: reserve))
        #expect(actual == expected)
    }

    @Test func expandsBeyondReservedWidth() throws {
        let reserved = try size(MenuBarLabel(value: Text(verbatim: "9"), reserve: Text(verbatim: "999")))
        let wider = try size(MenuBarLabel(value: Text(verbatim: "12345"), reserve: Text(verbatim: "999")))
        #expect(wider.width > reserved.width)
        #expect(wider.height == reserved.height)
    }

    @Test func separatesSectionsWithinThePanelInsets() throws {
        let empty = try size(MenuBarPanel { EmptyView() })
        let single = try size(MenuBarPanel { Color.clear.frame(height: 20) })
        let multiple = try size(
            MenuBarPanel {
                Color.clear.frame(height: 20)
                Color.clear.frame(height: 30)
            })
        #expect(empty == CGSize(width: 320, height: 32))
        #expect(single == CGSize(width: 320, height: 52))
        #expect(multiple == CGSize(width: 320, height: 96))
    }

    private func size<Content: View>(_ content: Content) throws -> CGSize {
        try #require(ImageRenderer(content: content).nsImage).size
    }
}
