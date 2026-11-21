import AppKit
import Darwin
import Observation
import QuickLook
import SwiftUI

/// A folder and everything under it, browsed in place: the path as a breadcrumb whose earlier folders go back, then one card of entries with folders first. A click selects, a double click or Return opens a folder in place or a file in its app, Space previews, Command Delete moves to the Trash, Command Up goes to the enclosing folder.
public struct FileBrowser: View {
    let root: URL
    var unavailableMessage: Text
    var openInTerminal: ((URL) throws -> Void)?
    @State private var model = FileBrowserModel()
    @State private var selection: URL?
    @State private var preview: URL?
    @State private var query = ""
    @AppStorage("fileSortColumn") private var sortColumn = FileBrowserEntry.Column.name.rawValue
    @AppStorage("fileSortAscending") private var ascending = true
    @FocusState private var focused: Bool

    public init(root: URL, unavailableMessage: Text? = nil, openInTerminal: ((URL) throws -> Void)? = nil) {
        self.root = root
        self.unavailableMessage = unavailableMessage ?? Text(String(localized: "This folder is not available right now.", bundle: .module))
        self.openInTerminal = openInTerminal
    }

    private var column: FileBrowserEntry.Column { .init(rawValue: sortColumn) ?? .name }
    private var entries: [FileBrowserEntry] {
        let all = model.entries ?? []
        let words = query.split(separator: " ")
        let matching = words.isEmpty ? all : all.filter { entry in words.allSatisfy { entry.name.localizedCaseInsensitiveContains($0) } }
        return FileBrowserEntry.sorted(matching, by: column, ascending: ascending)
    }
    private var atRoot: Bool { model.directory.standardizedFileURL == root.standardizedFileURL }
    private var selected: FileBrowserEntry? { entries.first { $0.url == selection } }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            pathBar
                .padding(.horizontal, Metrics.pageInset)
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .tabAccessory("files") { controls }
        .task(id: root) { model.appear(root: root) }
        .onDisappear { model.cancel() }
        .onChange(of: model.directory) {
            selection = nil
            query = ""
        }
        .quickLookPreview($preview, in: entries.filter { !$0.isDirectory }.map(\.url))
        .confirmationDialog(
            model.trashTargets.count == 1
                ? "Move \u{201C}\(model.trashTargets.first?.name ?? "")\u{201D} to the Trash?" : "Move \(model.trashTargets.count) items to the Trash?",
            isPresented: Binding(get: { !model.trashTargets.isEmpty }, set: { if !$0 { model.trashTargets = [] } }),
            titleVisibility: .visible
        ) {
            Button(String(localized: "Move to Trash", bundle: .module), role: .destructive, action: model.trash)
            Button(String(localized: "Cancel", bundle: .module), role: .cancel) { model.trashTargets = [] }
        }
        .alert("Cannot Complete the Action", isPresented: Binding(get: { model.actionFailure != nil }, set: { if !$0 { model.actionFailure = nil } })) {
            Button(String(localized: "OK", bundle: .module)) { model.actionFailure = nil }
        } message: {
            Text(model.actionFailure ?? "")
        }
    }

    /// The tab row's end: search in this folder, how it is sorted, then the two places the folder opens elsewhere.
    @ViewBuilder private var controls: some View {
        CapsuleSearchField(prompt: Text(String(localized: "Search", bundle: .module)), text: $query, width: 180)
        CircleMenu(title: Text(String(localized: "View Options", bundle: .module)), systemImage: "arrow.up.arrow.down") {
            Picker(String(localized: "Sort By", bundle: .module), selection: $sortColumn) {
                Text(String(localized: "Name", bundle: .module)).tag(FileBrowserEntry.Column.name.rawValue)
                Text(String(localized: "Date Modified", bundle: .module)).tag(FileBrowserEntry.Column.modified.rawValue)
                Text(String(localized: "Size", bundle: .module)).tag(FileBrowserEntry.Column.size.rawValue)
                Text(String(localized: "Kind", bundle: .module)).tag(FileBrowserEntry.Column.kind.rawValue)
            }
            .pickerStyle(.inline)
            Picker(String(localized: "Order", bundle: .module), selection: $ascending) {
                Text(String(localized: "Ascending", bundle: .module)).tag(true)
                Text(String(localized: "Descending", bundle: .module)).tag(false)
            }
            .pickerStyle(.inline)
            Divider()
            Button(String(localized: "Refresh", bundle: .module), action: model.refresh)
        }
        if let openInTerminal {
            Button(String(localized: "Open in Terminal", bundle: .module), systemImage: "terminal") {
                model.perform { try openInTerminal(selected.map { $0.isDirectory ? $0.url : model.directory } ?? model.directory) }
            }
            .help(String(localized: "Open in Terminal", bundle: .module))
            .disabled(model.entries == nil)
        }
        Button(String(localized: "Show in Finder", bundle: .module), systemImage: "folder") { model.reveal([selected?.url ?? model.directory]) }
            .help(String(localized: "Show in Finder", bundle: .module))
            .disabled(model.entries == nil)
    }

    /// A way back up, then the path from the top folder, every folder but the last going back to it.
    private var pathBar: some View {
        HStack(spacing: 10) {
            Button(String(localized: "Enclosing Folder", bundle: .module), systemImage: "chevron.left", action: goUp)
                .buttonStyle(.circle(size: Metrics.rowControl))
                .help(String(localized: "Enclosing Folder", bundle: .module))
                .keyboardShortcut(.upArrow, modifiers: .command)
                .disabled(atRoot)
            FilePath(root: root, directory: model.directory, navigate: model.navigate)
            Spacer(minLength: 0)
        }
        .frame(height: Metrics.rowControl)
    }

    @ViewBuilder private var content: some View {
        if let failure = model.failure {
            switch failure {
            case .missing:
                EmptyState(
                    title: Text(String(localized: "Files Unavailable", bundle: .module)), systemImage: "folder.badge.questionmark", message: unavailableMessage,
                    actionTitle: Text(String(localized: "Try Again", bundle: .module)), action: model.refresh)
            case .permission:
                EmptyState(
                    title: Text(String(localized: "Permission Denied", bundle: .module)), systemImage: "lock",
                    message: Text(String(localized: "You do not have permission to read this folder.", bundle: .module)),
                    actionTitle: Text(String(localized: "Try Again", bundle: .module)), action: model.refresh)
            case .other(let message):
                EmptyState(
                    title: Text(String(localized: "Cannot Read Folder", bundle: .module)), systemImage: "exclamationmark.triangle", message: Text(message),
                    actionTitle: Text(String(localized: "Try Again", bundle: .module)), action: model.refresh)
            }
        } else if model.entries == nil {
            LoadingState(title: Text(String(localized: "Reading Files", bundle: .module)))
        } else if entries.isEmpty, !query.isEmpty {
            EmptyState(
                title: Text(String(localized: "No Matches", bundle: .module)), systemImage: "magnifyingglass",
                message: Text(String(localized: "Nothing in this folder matches \u{201C}\(query)\u{201D}.", bundle: .module)))
        } else if entries.isEmpty {
            EmptyState(
                title: Text(String(localized: "Empty Folder", bundle: .module)), systemImage: "folder",
                message: Text(String(localized: "This folder has no files.", bundle: .module)))
        } else {
            list
        }
    }

    private var list: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                        FileRow(entry: entry, selected: entry.url == selection, focused: focused)
                            .id(entry.url)
                            .onTapGesture(count: 2) { activate(entry) }
                            .simultaneousGesture(
                                TapGesture().onEnded {
                                    selection = entry.url
                                    focused = true
                                }
                            )
                            .contextMenu { menu(for: entry) }
                            .draggable(entry.url)
                        if index < entries.count - 1 {
                            Rectangle().fill(.hairline).frame(height: 1).padding(.horizontal, 12)
                        }
                    }
                }
                .padding(2)
                .background(.groupFill, in: .rect(cornerRadius: Metrics.groupRadius, style: .continuous))
                .padding(.horizontal, Metrics.pageInset)
                .padding(.bottom, 24)
            }
            .scrollBounceBehavior(.basedOnSize)
            .focusable()
            .focused($focused)
            .focusEffectDisabled()
            .onKeyPress(.downArrow) {
                move(1, proxy); return .handled
            }
            .onKeyPress(.upArrow, phases: .down) { press in
                if press.modifiers.contains(.command) { goUp(); return .handled }
                move(-1, proxy)
                return .handled
            }
            .onKeyPress(.return) {
                guard let selected else { return .ignored }
                activate(selected)
                return .handled
            }
            .onKeyPress(.space) {
                guard let selected, !selected.isDirectory else { return .ignored }
                preview = preview == nil ? selected.url : nil
                return .handled
            }
            .onKeyPress(.delete, phases: .down) { press in
                guard press.modifiers.contains(.command), let selected, selected.isWritable else { return .ignored }
                model.trashTargets = [selected]
                return .handled
            }
        }
    }

    @ViewBuilder private func menu(for entry: FileBrowserEntry) -> some View {
        Button(entry.isDirectory ? "Open Folder" : "Open") { activate(entry) }
        if !entry.isDirectory {
            let apps = NSWorkspace.shared.urlsForApplications(toOpen: entry.url)
            if !apps.isEmpty {
                Menu("Open With") {
                    ForEach(apps, id: \.self) { app in
                        Button(FileManager.default.displayName(atPath: app.path)) { model.open(entry, with: app) }
                    }
                }
            }
            Button(String(localized: "Quick Look", bundle: .module)) { preview = entry.url }
        }
        Divider()
        Button(String(localized: "Show in Finder", bundle: .module)) { model.reveal([entry.url]) }
        if let openInTerminal, entry.isDirectory {
            Button(String(localized: "Open in Terminal", bundle: .module)) { model.perform { try openInTerminal(entry.url) } }
        }
        Button(String(localized: "Copy Path", bundle: .module)) { Clipboard.copy(entry.url.path, toast: String(localized: "Copied path", bundle: .module)) }
        Divider()
        Button(String(localized: "Move to Trash", bundle: .module), role: .destructive) { model.trashTargets = [entry] }
            .disabled(!entry.isWritable)
    }

    private func activate(_ entry: FileBrowserEntry) {
        if entry.isDirectory { model.navigate(entry.url) } else { model.open(entry) }
    }

    private func goUp() {
        guard model.directory.standardizedFileURL != root.standardizedFileURL else { return }
        let parent = model.directory.deletingLastPathComponent()
        let child = model.directory
        model.navigate(parent)
        selection = child
    }

    private func move(_ step: Int, _ proxy: ScrollViewProxy) {
        guard !entries.isEmpty else { return }
        let current = entries.firstIndex { $0.url == selection }
        let next = current.map { min(max($0 + step, 0), entries.count - 1) } ?? (step > 0 ? 0 : entries.count - 1)
        selection = entries[next].url
        proxy.scrollTo(entries[next].url)
        if preview != nil, !entries[next].isDirectory { preview = entries[next].url }
    }
}

/// One entry: its Finder icon, its name over its size, kind and date, and a chevron when it is a folder that opens in place.
private struct FileRow: View {
    let entry: FileBrowserEntry
    let selected: Bool
    let focused: Bool
    @State private var hovering = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var meta: String {
        let date = entry.modified.formatted(
            Calendar.current.isDate(entry.modified, equalTo: .now, toGranularity: .year)
                ? .dateTime.month(.abbreviated).day().hour().minute()
                : .dateTime.year().month(.abbreviated).day())
        let size = FileBrowserEntry.formattedSize(entry.size)
        return [size.isEmpty ? nil : size, entry.kind, date].compactMap { $0 }.joined(separator: " · ")
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: entry.url.path))
                .resizable()
                .interpolation(.high)
                .frame(width: 26, height: 26)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(meta)
                    .font(.rowMeta)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            if entry.isDirectory {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, 10)
        .frame(minHeight: Metrics.listRowHeight - 6)
        .background(background, in: .rect(cornerRadius: 10))
        .contentShape(.rect(cornerRadius: 10))
        .onHover { hovering = $0 }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: hovering)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    }

    private var background: Color {
        if selected { return Color.accentColor.opacity(focused ? 0.18 : 0.1) }
        return hovering ? Color.primary.opacity(0.045) : .clear
    }
}

/// The path from the browsed root to the open folder; every folder but the last goes back to it.
private struct FilePath: View {
    let root: URL
    let directory: URL
    let navigate: (URL) -> Void

    private var steps: [URL] {
        let base = root.standardizedFileURL.pathComponents.count
        let parts = directory.standardizedFileURL.pathComponents
        guard parts.count >= base else { return [root] }
        return (0...(parts.count - base)).map { depth in
            parts.prefix(base + depth).dropFirst().reduce(URL(filePath: "/")) { $0.appending(path: $1, directoryHint: .isDirectory) }
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, url in
                let last = index == steps.count - 1
                if index > 0 {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.tertiary)
                        .accessibilityHidden(true)
                }
                Button {
                    navigate(url)
                } label: {
                    Text(index == 0 ? root.lastPathComponent : url.lastPathComponent)
                        .fontWeight(last ? .medium : .regular)
                        .foregroundStyle(last ? .primary : .secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .buttonStyle(.plain)
                .disabled(last)
                .layoutPriority(last ? 1 : 0)
                .help(url.lastPathComponent)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(String(localized: "Folder path", bundle: .module))
    }
}

@MainActor @Observable
final class FileBrowserModel {
    enum Failure: Equatable {
        case missing, permission, other(String)
    }

    var root = URL(filePath: "/")
    var directory = URL(filePath: "/")
    var entries: [FileBrowserEntry]?
    var failure: Failure?
    var trashTargets: [FileBrowserEntry] = []
    var actionFailure: String?
    private var cache: [URL: [FileBrowserEntry]] = [:]
    private var task: Task<Void, Never>?

    func appear(root: URL) {
        if self.root != root {
            self.root = root
            directory = root
            cache = [:]
        }
        refresh()
    }

    func refresh() { load(directory) }

    func cancel() {
        task?.cancel()
        task = nil
    }

    func navigate(_ url: URL) {
        guard url.standardizedFileURL.pathComponents.starts(with: root.standardizedFileURL.pathComponents) else { return }
        directory = url
        load(url)
    }

    private func load(_ url: URL) {
        cancel()
        entries = cache[url]
        failure = nil
        let root = root
        task = Task { [weak self] in
            do {
                let read = try await FileBrowserDirectory.read(root: root, directory: url)
                guard let self, !Task.isCancelled, directory == url else { return }
                cache[url] = read
                entries = read
            } catch {
                guard let self, !Task.isCancelled, directory == url else { return }
                entries = nil
                failure = Self.classify(error as NSError)
            }
        }
    }

    private static func classify(_ error: NSError) -> Failure {
        if error.domain == NSPOSIXErrorDomain && [EACCES, EPERM, ELOOP].contains(Int32(error.code))
            || error.domain == NSCocoaErrorDomain && error.code == NSFileReadNoPermissionError
        {
            return .permission
        }
        if error.domain == NSPOSIXErrorDomain && [ENOENT, ENOTDIR, ESTALE, ENXIO].contains(Int32(error.code))
            || error.domain == NSCocoaErrorDomain && error.code == NSFileNoSuchFileError
        {
            return .missing
        }
        return .other(error.localizedDescription)
    }

    func open(_ entry: FileBrowserEntry, with application: URL? = nil) {
        perform {
            try FileBrowserDirectory.validate(root: root, url: entry.url)
            if let application {
                NSWorkspace.shared.open([entry.url], withApplicationAt: application, configuration: .init()) { [weak self] _, error in
                    if let error { Task { @MainActor in self?.actionFailure = error.localizedDescription } }
                }
            } else if !NSWorkspace.shared.open(entry.url) {
                throw CocoaError(.fileReadUnknown, userInfo: [NSFilePathErrorKey: entry.url.path])
            }
        }
    }

    func reveal(_ urls: [URL]) {
        NSWorkspace.shared.activateFileViewerSelecting(urls)
    }

    func trash() {
        let targets = trashTargets
        trashTargets = []
        Task {
            do { try await FileBrowserDirectory.trash(root: root, entries: targets) } catch { actionFailure = error.localizedDescription }
            refresh()
        }
    }

    func perform(_ operation: () throws -> Void) {
        do { try operation() } catch { actionFailure = error.localizedDescription }
    }
}
