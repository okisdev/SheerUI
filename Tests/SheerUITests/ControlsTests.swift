import SwiftUI
import Testing

@testable import SheerUI

@MainActor
struct ControlsTests {
    @Test(arguments: [26, 30] as [CGFloat], [CapsuleButtonStyle.Weight.plain, .prominent, .ink])
    func capsuleHeightMatchesSize(height: CGFloat, weight: CapsuleButtonStyle.Weight) throws {
        let button = Button {
        } label: {
            Text(verbatim: "Continue")
        }
        .buttonStyle(CapsuleButtonStyle(weight: weight, size: height))
        #expect(try size(button).height == height)
    }

    @Test func capsuleConveniencesKeepTheirHeight() throws {
        let button = Button {
        } label: {
            Text(verbatim: "Continue")
        }
        #expect(try size(button.buttonStyle(.capsule)).height == Metrics.control)
        #expect(try size(button.buttonStyle(.prominentCapsule)).height == Metrics.control)
        #expect(try size(button.buttonStyle(.inkCapsule)).height == Metrics.control)
        #expect(try size(button.buttonStyle(.capsule(size: 26))).height == 26)
    }

    @Test(arguments: [false, true])
    func legacyCapsuleInitializerKeepsItsHeight(prominent: Bool) throws {
        let button = Button {
        } label: {
            Text(verbatim: "Continue")
        }
        .buttonStyle(CapsuleButtonStyle(prominent: prominent))
        #expect(try size(button).height == Metrics.control)
    }

    @Test func compactCapsuleUsesSmallerHorizontalPadding() throws {
        let button = Button {
        } label: {
            Text(verbatim: "Continue")
        }
        let compact = try size(button.buttonStyle(.capsule(size: 26)))
        let regular = try size(button.buttonStyle(.capsule))
        #expect(regular.width - compact.width == 8)
    }

    @Test(arguments: [26, 30] as [CGFloat])
    func tabsHeightMatchesSize(height: CGFloat) throws {
        let options = [(value: 0, title: Text(verbatim: "First")), (value: 1, title: Text(verbatim: "Second"))]
        let localizedOptions: [(value: Int, title: LocalizedStringKey)] = [(0, "First"), (1, "Second")]
        #expect(try size(CapsuleTabs(Text(verbatim: "View"), options: options, selection: .constant(0), size: height)).height == height)
        #expect(try size(CapsuleTabs("View", options: localizedOptions, selection: .constant(0), size: height)).height == height)
        #expect(try size(CapsuleTabs(options: options, selection: .constant(0), size: height)).height == height)
        #expect(try size(CapsuleTabs(options: localizedOptions, selection: .constant(0), size: height)).height == height)
    }

    @Test func legacyTabsInitializersKeepTheirHeight() throws {
        let options = [(value: 0, title: Text(verbatim: "First")), (value: 1, title: Text(verbatim: "Second"))]
        let localizedOptions: [(value: Int, title: LocalizedStringKey)] = [(0, "First"), (1, "Second")]
        #expect(try size(CapsuleTabs(options: options, selection: .constant(0))).height == Metrics.control)
        #expect(try size(CapsuleTabs(options: localizedOptions, selection: .constant(0))).height == Metrics.control)
    }

    @Test(arguments: [26, 30] as [CGFloat])
    func emptyTabsKeepTheirHeight(height: CGFloat) throws {
        let options: [(value: Int, title: Text)] = []
        #expect(try size(CapsuleTabs(options: options, selection: .constant(0), size: height)).height == height)
        #expect(try size(CapsuleTabs(Text(verbatim: "View"), options: options, selection: .constant(0), size: height)).height == height)
    }

    private func size<Content: View>(_ content: Content) throws -> CGSize {
        try #require(ImageRenderer(content: content).nsImage).size
    }
}
