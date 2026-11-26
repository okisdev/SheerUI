import SwiftUI
import Testing

@testable import SheerUI

struct SidebarTests {
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
