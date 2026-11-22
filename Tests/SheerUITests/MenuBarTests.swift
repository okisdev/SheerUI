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

    @Test func setsEachSectionOnItsOwnCard() throws {
        let empty = try size(MenuBarPanel { EmptyView() })
        let single = try size(MenuBarPanel { Color.clear.frame(height: 20) })
        let multiple = try size(
            MenuBarPanel {
                Color.clear.frame(height: 20)
                Color.clear.frame(height: 30)
            })
        #expect(empty == CGSize(width: 300, height: 16))
        #expect(single == CGSize(width: 300, height: 56))
        #expect(multiple == CGSize(width: 300, height: 112))
    }

    @Test(arguments: ["1 KB/s", "12 MB/s", "999 MB/s"])
    func stackKeepsItsReservedWidth(_ value: String) throws {
        let reserve = Text(verbatim: "↓ 999 MB/s")
        let expected = try size(MenuBarStack(top: reserve, bottom: reserve, reserve: reserve))
        let actual = try size(MenuBarStack(top: Text(verbatim: "↓ \(value)"), bottom: Text(verbatim: "↑ 1 KB/s"), reserve: reserve))
        #expect(actual == expected)
    }

    private func size<Content: View>(_ content: Content) throws -> CGSize {
        try #require(ImageRenderer(content: content).nsImage).size
    }
}
