import Foundation
import Testing

@testable import SheerUI

struct ArtworkTests {
    @Test func keepsBrandColorsUnlessTheyVanishOnTheSheet() {
        #expect(BrandMark(path: "", hex: 0xFF4438).color(in: .light) != .primary)
        #expect(BrandMark(path: "", hex: 0xFFCC01).color(in: .light) == .primary)
        #expect(BrandMark(path: "", hex: 0xFFCC01).color(in: .dark) != .primary)
        #expect(BrandMark(path: "", hex: 0x000000).color(in: .dark) == .primary)
    }

    @MainActor @Test func readsAFileIconOncePerPath() {
        let url = URL(fileURLWithPath: "/System/Applications/Calculator.app")
        #expect(FileIcons.icon(for: url) === FileIcons.icon(for: url))
    }
}
