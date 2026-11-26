import SwiftUI
import Testing

@testable import SheerUI

struct SidebarTests {
    @Test func fixedWidthIgnoresDrags() {
        #expect(SidebarWidth.fixed.clamped(400) == Metrics.sidebarWidth)
        #expect(SidebarWidth.fixed(240).clamped(100) == 240)
    }

    @Test(arguments: zip([100.0, 180, 250, 360, 900, .nan, .infinity], [180.0, 180, 250, 360, 360, 220, 220]))
    func resizableWidthStaysInItsRange(drag: Double, expected: Double) {
        let width = Double(SidebarWidth.resizable.clamped(CGFloat(drag)))
        #expect(width == expected)
    }

    @Test func resizableIdealFallsInsideItsRange() {
        #expect(SidebarWidth.resizable(ideal: 500, range: 200...300).ideal == 300)
    }

    @Test(arguments: [
        (2, MoveCommandDirection.up, 2),
        (1, .down, 1),
        (0, .up, 2),
        (0, .down, 1),
        (3, .up, 3),
        (3, .down, 3),
        (1, .left, 1),
        (1, .right, 1)
    ])
    func moveCommandsFollowOrderAndStopAtEnds(selection: Int, direction: MoveCommandDirection, expected: Int) {
        #expect(SidebarList<Int, EmptyView>.step(from: selection, in: [2, 0, 1], direction: direction) == expected)
    }

    @Test(arguments: [MoveCommandDirection.up, .down])
    func emptyOrderKeepsSelection(direction: MoveCommandDirection) {
        #expect(SidebarList<Int, EmptyView>.step(from: 0, in: [], direction: direction) == 0)
    }

    @Test(arguments: [MoveCommandDirection.up, .down])
    func singleItemKeepsSelection(direction: MoveCommandDirection) {
        #expect(SidebarList<Int, EmptyView>.step(from: 0, in: [0], direction: direction) == 0)
    }
}
