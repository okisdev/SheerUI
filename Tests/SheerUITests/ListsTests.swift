import AppKit
import SwiftUI
import Testing

@testable import SheerUI

@MainActor
struct ListsTests {
    private struct Item: Identifiable {
        let id: Int
    }

    @Test func groupsAcceptStringVariables() throws {
        let title = String("Section".prefix(7))
        let items = [Item(id: 1), Item(id: 2)]
        let group = ListGroup(title, count: 2) { Text(verbatim: "Row") }
        let trailing = ListGroup(title: title, count: 2, trailing: { Text(verbatim: "Command") }) { Text(verbatim: "Row") }
        let data = ListGroup(title, items) { Text($0.id, format: .number) }
        let dataTrailing = ListGroup(title, items, trailing: { Text(verbatim: "Command") }) { Text($0.id, format: .number) }

        #expect(group.title == Text(verbatim: title))
        #expect(trailing.title == Text(verbatim: title))
        #expect(data.title == Text(verbatim: title))
        #expect(dataTrailing.title == Text(verbatim: title))
        #expect(group.count == 2 && trailing.count == 2 && data.count == 2 && dataTrailing.count == 2)
        _ = try size(group)
        _ = try size(trailing)
        _ = try size(data)
        _ = try size(dataTrailing)
        _ = try size(ListGroup(title[...]) { Text(verbatim: "Row") })
    }

    @Test func groupsLocalizeLiteralTitles() throws {
        let items = [Item(id: 1)]
        let group = ListGroup("Section") { Text(verbatim: "Row") }
        let trailing = ListGroup(title: "Section", trailing: { Text(verbatim: "Command") }) { Text(verbatim: "Row") }
        let data = ListGroup("Section", items) { Text($0.id, format: .number) }
        let dataTrailing = ListGroup("Section", items, trailing: { Text(verbatim: "Command") }) { Text($0.id, format: .number) }

        #expect(group.title == Text("Section"))
        #expect(trailing.title == Text("Section"))
        #expect(data.title == Text("Section"))
        #expect(dataTrailing.title == Text("Section"))
        _ = try size(group)
        _ = try size(trailing)
        _ = try size(data)
        _ = try size(dataTrailing)

        let key: LocalizedStringKey = "Section"
        _ = try size(ListGroup(key) { Text(verbatim: "Row") })
    }

    @Test func groupsPreserveCallerText() throws {
        let title = Text("Section", tableName: "Sections", bundle: .main).italic()
        let items = [Item(id: 1)]
        let group = ListGroup(title) { Text(verbatim: "Row") }
        let trailing = ListGroup(title: title, trailing: { Text(verbatim: "Command") }) { Text(verbatim: "Row") }
        let data = ListGroup(title, items) { Text($0.id, format: .number) }
        let dataTrailing = ListGroup(title, items, trailing: { Text(verbatim: "Command") }) { Text($0.id, format: .number) }

        #expect(group.title == title)
        #expect(trailing.title == title)
        #expect(data.title == title)
        #expect(dataTrailing.title == title)
        _ = try size(group)
        _ = try size(trailing)
        _ = try size(data)
        _ = try size(dataTrailing)
    }

    @Test func untitledGroupsOmitTheHeaderAndCommand() throws {
        let items = [Item(id: 1)]
        let group = ListGroup(nil, count: 2) { Color.clear.frame(height: 20) }
        let trailing = ListGroup(title: nil, count: 2, trailing: { Color.red.frame(height: 100) }) { Color.clear.frame(height: 20) }
        let data = ListGroup(nil, items) { _ in Color.clear.frame(height: 20) }
        let dataTrailing = ListGroup(nil, items, trailing: { Color.red.frame(height: 100) }) { _ in Color.clear.frame(height: 20) }

        #expect(try size(group).height == 24)
        #expect(try size(trailing).height == 24)
        #expect(try size(data).height == 24)
        #expect(try size(dataTrailing).height == 24)
        #expect(try size(ListGroup { Color.clear.frame(height: 20) }).height == 24)
    }

    @Test func emptyDataGroupsKeepAZeroCount() throws {
        let items: [Item] = []
        let group = ListGroup("Section", items) { Text($0.id, format: .number) }
        #expect(group.count == 0)
        _ = try size(group)
    }

    @Test(arguments: [false, true])
    func standardAndCustomRowsRender(selected: Bool) throws {
        let standard: ListRow<Text, EmptyView> = ListRow(title: "Row", meta: "Details", selected: selected, open: {}) { Text(verbatim: "Value") }
        let custom: ListRow<Text, EmptyView> = ListRow(selected: selected, open: {}) { Text(verbatim: "Custom") }
        let standardActions = ListRow(title: "Row", meta: "", selected: selected, open: {}, trailing: { EmptyView() }) {
            Button {
            } label: {
                Image(systemName: "ellipsis")
            }
        }
        let customActions = ListRow(selected: selected, open: {}, content: { Text(verbatim: "Custom") }) {
            Button {
            } label: {
                Image(systemName: "ellipsis")
            }
        }

        #expect(try size(standard).height == Metrics.listRowHeight)
        #expect(try size(custom).height == Metrics.listRowHeight)
        #expect(try size(standardActions).height == Metrics.listRowHeight)
        #expect(try size(customActions).height == Metrics.listRowHeight)
        _ = try size(ListRow(title: "Row", meta: "") { EmptyView() })
        _ = try size(ListRow { Text(verbatim: "Custom") })
    }

    @Test(arguments: [ColorScheme.light, .dark], [false, true])
    func selectionFillsStandardAndCustomRows(colorScheme: ColorScheme, custom: Bool) throws {
        let selected = try backgroundAlpha(selected: true, custom: custom, colorScheme: colorScheme)
        let unselected = try backgroundAlpha(selected: false, custom: custom, colorScheme: colorScheme)
        #expect(selected > unselected)
    }

    @Test func customRowsKeepCompactHeightAndHorizontalPadding() throws {
        let row = ListRow { Color.red.frame(height: 12) }
        #expect(try size(row.compactListRows()).height == Metrics.nestedRowHeight)
        #expect(try size(ListRow { Color.red.frame(height: 72) }).height == 72)
        let image = try #require(ImageRenderer(content: ListRow { Color.red.frame(width: 300, height: 12) }).nsImage)
        #expect(image.size.width == 320)
    }

    private func size<Content: View>(_ content: Content) throws -> CGSize {
        try #require(ImageRenderer(content: content.frame(width: 320)).nsImage).size
    }

    private func backgroundAlpha(selected: Bool, custom: Bool, colorScheme: ColorScheme) throws -> CGFloat {
        let renderer = ImageRenderer(
            content: Group {
                if custom {
                    ListRow(selected: selected) { Text(verbatim: "Row") }
                } else {
                    ListRow(title: "Row", meta: "", selected: selected) { EmptyView() }
                }
            }
            .frame(width: 320)
            .environment(\.colorScheme, colorScheme))
        let image = try #require(renderer.cgImage)
        let color = try #require(NSBitmapImageRep(cgImage: image).colorAt(x: 300, y: 20))
        return color.alphaComponent
    }
}
