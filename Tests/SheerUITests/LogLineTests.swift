import Foundation
import Testing
@testable import SheerUI

@Suite struct LogLineTests {
    @Test(arguments: [
        ("2026/11/20 02:43:11 [notice] 1#1: start worker process 30", LogLine.Level.normal),
        ("2026/11/20 02:43:11 [error] 7#7: open() failed", .error),
        ("level=warn msg=\"slow request\"", .warning),
        ("WARNING: deprecated flag", .warning),
        ("panic: runtime error: index out of range", .error),
        ("ERROR 2026-11-20 something broke", .error),
        ("terror and errorless words stay normal", .normal)
    ])
    func level(_ message: String, _ expected: LogLine.Level) {
        #expect(LogLine.level(of: message) == expected)
    }

    @Test func failedOverridesTheMessage() {
        let line = LogLine(id: 0, message: "exited with status 1.", timestamp: "", date: .now, source: "", failed: true)
        #expect(line.level == .error)
    }
}
