import Testing

@testable import SheerUI

struct ArtworkTests {
    @Test func keepsBrandColorsUnlessTheyVanishOnTheSheet() {
        #expect(BrandMark(path: "", hex: 0xFF4438).color(in: .light) != .primary)
        #expect(BrandMark(path: "", hex: 0xFFCC01).color(in: .light) == .primary)
        #expect(BrandMark(path: "", hex: 0xFFCC01).color(in: .dark) != .primary)
        #expect(BrandMark(path: "", hex: 0x000000).color(in: .dark) == .primary)
    }
}
