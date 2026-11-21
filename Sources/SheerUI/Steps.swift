import SwiftUI

/// Where one step of a longer job stands.
public enum StepState: Equatable, Sendable {
    case waiting, active, complete, failed

    var title: String {
        switch self {
        case .waiting: String(localized: "Waiting", bundle: .module)
        case .active: String(localized: "In progress", bundle: .module)
        case .complete: String(localized: "Done", bundle: .module)
        case .failed: String(localized: "Failed", bundle: .module)
        }
    }
}

/// One step of a job the person is watching: its state as a mark in a fixed leading column (an empty ring, live dots, a check, or an exclamation mark), so every title stays on one line as the steps advance; then the title over an optional detail, the seconds it has taken, and at most one trailing command, which a failed step uses to offer its retry.
public struct StepRow<Action: View>: View {
    let title: Text
    var detail: Text?
    let state: StepState
    @ViewBuilder let action: Action
    @State private var started: Date?
    @State private var finished: Date?

    public init(title: Text, detail: Text? = nil, state: StepState, @ViewBuilder action: () -> Action) {
        self.title = title
        self.detail = detail
        self.state = state
        self.action = action()
    }

    public var body: some View {
        HStack(spacing: 12) {
            mark
                .frame(width: Self.markColumn, height: Self.markColumn)
            VStack(alignment: .leading, spacing: 3) {
                title
                    .font(.rowTitle)
                    .foregroundStyle(state == .waiting ? .secondary : .primary)
                    .lineLimit(1)
                if let detail {
                    detail
                        .font(.rowMeta)
                        .foregroundStyle(state == .failed ? AnyShapeStyle(.red) : AnyShapeStyle(.secondary))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 8)
            HStack(spacing: 10) {
                elapsed
                action
                    .buttonStyle(.capsule)
            }
        }
        .padding(.horizontal, 10)
        .frame(minHeight: detail == nil ? Metrics.nestedRowHeight : Metrics.listRowHeight)
        .onChange(of: state, initial: true) { _, state in
            switch state {
            case .active:
                started = Date()
                finished = nil
            case .complete, .failed:
                if started != nil, finished == nil { finished = Date() }
            case .waiting:
                started = nil
                finished = nil
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue(Text(state.title))
    }

    /// Wide enough for the live dots, so the dot, check and ring marks center in the same column.
    static var markColumn: CGFloat { 14 }

    @ViewBuilder private var mark: some View {
        switch state {
        case .waiting:
            Image(systemName: "circle")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        case .active:
            DotMatrix()
        case .complete:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 13))
                .foregroundStyle(.green)
        case .failed:
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 13))
                .foregroundStyle(.red)
        }
    }

    @ViewBuilder private var elapsed: some View {
        if let started {
            Group {
                if let finished {
                    Text(Self.seconds(from: started, to: finished))
                } else {
                    TimelineView(.periodic(from: started, by: 1)) { context in
                        Text(Self.seconds(from: started, to: context.date))
                    }
                }
            }
            .font(.rowMeta)
            .monospacedDigit()
            .foregroundStyle(.secondary)
        }
    }

    private static func seconds(from start: Date, to end: Date) -> String {
        String(localized: "\(max(0, Int(end.timeIntervalSince(start))))s", bundle: .module)
    }
}

extension StepRow {
    public init(title: LocalizedStringKey, detail: LocalizedStringKey? = nil, state: StepState, @ViewBuilder action: () -> Action) {
        self.init(title: Text(title), detail: detail.map { Text($0) }, state: state, action: action)
    }
}

extension StepRow where Action == EmptyView {
    public init(title: Text, detail: Text? = nil, state: StepState) {
        self.init(title: title, detail: detail, state: state) { EmptyView() }
    }

    public init(title: LocalizedStringKey, detail: LocalizedStringKey? = nil, state: StepState) {
        self.init(title: Text(title), detail: detail.map { Text($0) }, state: state) { EmptyView() }
    }
}
