import Foundation

/// A list page's search: rows match when every word of the query appears in their text.
public struct ListQuery: Equatable {
    public var text = ""

    public init(text: String = "") {
        self.text = text
    }

    public func matches(_ fields: String...) -> Bool {
        let words = text.split(separator: " ").map(String.init)
        guard !words.isEmpty else { return true }
        let haystack = fields.joined(separator: " ")
        return words.allSatisfy { haystack.localizedCaseInsensitiveContains($0) }
    }
}
