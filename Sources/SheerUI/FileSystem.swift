import Darwin
import Foundation
import UniformTypeIdentifiers

public struct FileBrowserEntry: Identifiable, Equatable, Sendable {
    public enum Column: String, CaseIterable, Sendable {
        case name, modified, size, kind
    }

    public let url: URL
    public let isDirectory: Bool
    public let isSymbolicLink: Bool
    public let modified: Date
    public let size: Int64?
    public let kind: String
    public let isWritable: Bool
    public var id: URL { url }
    public var name: String { url.lastPathComponent }

    public init(url: URL, isDirectory: Bool, isSymbolicLink: Bool = false, modified: Date, size: Int64?, kind: String, isWritable: Bool = false) {
        self.url = url
        self.isDirectory = isDirectory
        self.isSymbolicLink = isSymbolicLink
        self.modified = modified
        self.size = size
        self.kind = kind
        self.isWritable = isWritable
    }

    public static func sorted(_ entries: [Self], by column: Column, ascending: Bool) -> [Self] {
        entries.sorted { left, right in
            if left.isDirectory != right.isDirectory { return left.isDirectory }
            let order: ComparisonResult =
                switch column {
                case .name: left.name.localizedStandardCompare(right.name)
                case .modified: left.modified.compare(right.modified)
                case .size: (left.size ?? 0) < (right.size ?? 0) ? .orderedAscending : (left.size ?? 0) > (right.size ?? 0) ? .orderedDescending : .orderedSame
                case .kind: left.kind.localizedStandardCompare(right.kind)
                }
            if order != .orderedSame { return ascending ? order == .orderedAscending : order == .orderedDescending }
            let nameOrder = left.name.localizedStandardCompare(right.name)
            if nameOrder != .orderedSame { return nameOrder == .orderedAscending }
            return left.url.path < right.url.path
        }
    }

    public static func formattedSize(_ size: Int64?, locale: Locale = .current) -> String {
        guard let size else { return "" }
        return size.formatted(.byteCount(style: .file, spellsOutZero: false).locale(locale))
    }
}

public enum FileBrowserDirectory {
    @concurrent
    public static func read(root: URL, directory: URL) async throws -> [FileBrowserEntry] {
        let descriptor = try open(root: root, directory: directory)
        guard let stream = fdopendir(descriptor) else {
            close(descriptor)
            throw failure(directory)
        }
        defer { closedir(stream) }
        var filesystem = statfs()
        guard fstatfs(descriptor, &filesystem) == 0 else { throw failure(directory) }
        let writable = filesystem.f_flags & UInt32(MNT_RDONLY) == 0 && faccessat(descriptor, ".", W_OK, 0) == 0
        var entries: [FileBrowserEntry] = []
        while true {
            try Task.checkCancellation()
            errno = 0
            guard let entry = readdir(stream) else {
                if errno != 0 { throw failure(directory) }
                break
            }
            let name = withUnsafePointer(to: &entry.pointee.d_name) {
                $0.withMemoryRebound(to: CChar.self, capacity: Int(entry.pointee.d_namlen) + 1) { String(cString: $0) }
            }
            if name == "." || name == ".." { continue }
            var metadata = stat()
            guard fstatat(descriptor, name, &metadata, AT_SYMLINK_NOFOLLOW) == 0 else {
                if errno == ENOENT { continue }
                throw failure(directory.appending(path: name))
            }
            let directoryEntry = metadata.st_mode & S_IFMT == S_IFDIR
            let symbolicLink = metadata.st_mode & S_IFMT == S_IFLNK
            let regular = metadata.st_mode & S_IFMT == S_IFREG
            let url = directory.appending(path: name, directoryHint: directoryEntry ? .isDirectory : .notDirectory)
            let kind: String
            if directoryEntry {
                kind = String(localized: "Folder", bundle: .module)
            } else if symbolicLink {
                kind = String(localized: "Symbolic link", bundle: .module)
            } else if regular {
                kind = UTType(filenameExtension: url.pathExtension)?.localizedDescription ?? String(localized: "File", bundle: .module)
            } else {
                kind = String(localized: "Special file", bundle: .module)
            }
            entries.append(
                FileBrowserEntry(
                    url: url, isDirectory: directoryEntry, isSymbolicLink: symbolicLink,
                    modified: Date(timeIntervalSince1970: Double(metadata.st_mtimespec.tv_sec) + Double(metadata.st_mtimespec.tv_nsec) / 1_000_000_000),
                    size: directoryEntry ? nil : Int64(metadata.st_size), kind: kind, isWritable: writable
                ))
        }
        return entries
    }

    public static func validate(root: URL, url: URL) throws {
        if url.standardizedFileURL == root.standardizedFileURL {
            let descriptor = try open(root: root, directory: root)
            close(descriptor)
            return
        }
        let descriptor = try open(root: root, directory: url.deletingLastPathComponent())
        defer { close(descriptor) }
        var metadata = stat()
        guard fstatat(descriptor, url.lastPathComponent, &metadata, AT_SYMLINK_NOFOLLOW) == 0 else { throw failure(url) }
        guard metadata.st_mode & S_IFMT != S_IFLNK else { throw CocoaError(.fileReadNoPermission) }
    }

    @concurrent
    public static func trash(root: URL, entries: [FileBrowserEntry]) async throws {
        for entry in entries {
            try Task.checkCancellation()
            guard entry.isWritable else { throw CocoaError(.fileWriteNoPermission) }
            try validate(root: root, url: entry.url)
            try FileManager.default.trashItem(at: entry.url, resultingItemURL: nil)
        }
    }

    private static func open(root: URL, directory: URL) throws -> Int32 {
        let rootParts = root.standardizedFileURL.pathComponents
        let parts = directory.standardizedFileURL.pathComponents
        guard parts.starts(with: rootParts) else { throw CocoaError(.fileReadNoPermission) }
        var descriptor = Darwin.open(root.path, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
        guard descriptor >= 0 else { throw failure(root) }
        for part in parts.dropFirst(rootParts.count) {
            let child = openat(descriptor, part, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
            let savedError = errno
            close(descriptor)
            guard child >= 0 else { throw failure(directory, code: savedError) }
            descriptor = child
        }
        return descriptor
    }

    private static func failure(_ url: URL, code: Int32 = errno) -> NSError {
        NSError(domain: NSPOSIXErrorDomain, code: Int(code), userInfo: [NSFilePathErrorKey: url.path])
    }
}
