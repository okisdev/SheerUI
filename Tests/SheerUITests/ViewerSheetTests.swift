import SwiftUI
import Testing

@testable import SheerUI

@MainActor
struct ViewerSheetTests {
    @Test func stringTitlesAcceptNilAndOmittedSubtitles() throws {
        let name = String("Title".prefix(5))
        let sheet = ViewerSheet(title: name, subtitle: nil) { Text(verbatim: "Content") }
        let defaultSubtitle = ViewerSheet(title: name) { Text(verbatim: "Content") }

        #expect(sheet.title == Text(verbatim: name))
        #expect(sheet.subtitle == nil)
        #expect(defaultSubtitle.subtitle == nil)
        _ = try #require(ImageRenderer(content: sheet).nsImage)
        _ = try #require(ImageRenderer(content: defaultSubtitle).nsImage)
    }

    @Test(arguments: [String?.none, "Details"])
    func stringTitlesAcceptOptionalSubtitles(subtitle: String?) throws {
        let name = String("Title".prefix(5))
        let sheet = ViewerSheet(title: name, subtitle: subtitle, width: 800) { Text(verbatim: "Content") }

        #expect(sheet.title == Text(verbatim: name))
        #expect(sheet.subtitle == subtitle.map { Text(verbatim: $0) })
        let image = try #require(ImageRenderer(content: sheet).nsImage)
        #expect(image.size.width == 800)
    }

    @Test func literalTitlesAndSubtitlesStayLocalized() throws {
        let sheet = ViewerSheet(title: "Title", subtitle: "Details") { Text(verbatim: "Content") }

        #expect(sheet.title == Text("Title"))
        #expect(sheet.subtitle == Text("Details"))
        _ = try #require(ImageRenderer(content: sheet).nsImage)
    }
}
