import Foundation
import Testing
@testable import SheerUI

@Suite struct FileBrowserTests {
    private func entry(_ name: String, directory: Bool = false, modified: TimeInterval = 0, size: Int64? = 0, kind: String = "File") -> FileBrowserEntry {
        FileBrowserEntry(url: URL(filePath: "/files/\(name)"), isDirectory: directory, modified: Date(timeIntervalSince1970: modified), size: size, kind: kind)
    }

    @Test func namesUseNaturalOrderAndKeepFoldersFirst() {
        let entries = [entry("file10"), entry("z", directory: true, size: nil), entry("file2"), entry("a", directory: true, size: nil)]
        #expect(FileBrowserEntry.sorted(entries, by: .name, ascending: true).map(\.name) == ["a", "z", "file2", "file10"])
        #expect(FileBrowserEntry.sorted(entries, by: .name, ascending: false).map(\.name) == ["z", "a", "file10", "file2"])
    }

    @Test func allColumnsSortBothDirectionsWithStableTies() {
        let entries = [
            entry("c", modified: 10, size: 2_000, kind: "Text"), entry("b", modified: 20, size: 5, kind: "Archive"),
            entry("a", modified: 20, size: 5, kind: "Archive")
        ]
        for column in [FileBrowserEntry.Column.modified, .kind] {
            #expect(FileBrowserEntry.sorted(entries, by: column, ascending: column == .kind).map(\.name) == ["a", "b", "c"])
            #expect(FileBrowserEntry.sorted(entries, by: column, ascending: column != .kind).map(\.name) == ["c", "a", "b"])
        }
        #expect(FileBrowserEntry.sorted(entries, by: .size, ascending: true).map(\.name) == ["a", "b", "c"])
        #expect(FileBrowserEntry.sorted(entries, by: .size, ascending: false).map(\.name) == ["c", "a", "b"])
        #expect(FileBrowserEntry.sorted([], by: .name, ascending: true).isEmpty)
    }

    @Test func sizeFormattingUsesDecimalFileUnits() {
        let locale = Locale(identifier: "en_US")
        #expect(FileBrowserEntry.formattedSize(nil, locale: locale).isEmpty)
        #expect(FileBrowserEntry.formattedSize(0, locale: locale) == "0 bytes")
        #expect(FileBrowserEntry.formattedSize(42, locale: locale) == "42 bytes")
        #expect(FileBrowserEntry.formattedSize(1_000, locale: locale) == "1 kB")
        #expect(FileBrowserEntry.formattedSize(1_000_000, locale: locale) == "1 MB")
        #expect(FileBrowserEntry.formattedSize(1_500_000_000, locale: locale) == "1.5 GB")
    }

    @Test func readsMetadataWithoutFollowingLinksOrEscapingTheRoot() async throws {
        let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let folder = root.appending(path: "folder", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try Data("hello".utf8).write(to: root.appending(path: ".hidden"))
        let link = root.appending(path: "escape")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: root.deletingLastPathComponent())
        let entries = try await FileBrowserDirectory.read(root: root, directory: root)
        #expect(Set(entries.map(\.name)) == ["folder", ".hidden", "escape"])
        #expect(entries.first { $0.name == "folder" }?.isDirectory == true)
        #expect(entries.first { $0.name == ".hidden" }?.size == 5)
        #expect(entries.first { $0.name == "escape" }?.isSymbolicLink == true)
        #expect(entries.first { $0.name == "escape" }?.isDirectory == false)
        #expect(throws: (any Error).self) { try FileBrowserDirectory.validate(root: root, url: link) }
        await #expect(throws: (any Error).self) { try await FileBrowserDirectory.read(root: root, directory: link) }
        await #expect(throws: (any Error).self) { try await FileBrowserDirectory.read(root: root, directory: root.deletingLastPathComponent()) }
        #expect(try await FileBrowserDirectory.read(root: root, directory: folder).isEmpty)
    }
}
