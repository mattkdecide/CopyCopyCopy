import Foundation

/// Holds the accumulated clipboard text, segment count, and separator
/// preference. Mirrors the Chrome extension's chrome.storage.local model,
/// persisted here via UserDefaults so it survives relaunches.
final class ClipboardBuffer {
    static let blankLineSeparator = "\n\n"
    static let newLineSeparator = "\n"
    static let spaceSeparator = " "

    private enum Keys {
        static let buffer = "ccc_buffer"
        static let count = "ccc_count"
        static let separator = "ccc_separator"
    }

    private let defaults = UserDefaults.standard

    /// Called after buffer, count, or separator changes so the UI can refresh.
    var onChange: (() -> Void)?

    private(set) var text: String {
        didSet { defaults.set(text, forKey: Keys.buffer) }
    }

    private(set) var count: Int {
        didSet { defaults.set(count, forKey: Keys.count) }
    }

    var separator: String {
        didSet {
            defaults.set(separator, forKey: Keys.separator)
            onChange?()
        }
    }

    init() {
        text = defaults.string(forKey: Keys.buffer) ?? ""
        count = defaults.integer(forKey: Keys.count)
        separator = defaults.string(forKey: Keys.separator) ?? Self.blankLineSeparator
    }

    /// Appends newly copied text onto the buffer and returns the combined
    /// string the caller should write back to the pasteboard.
    @discardableResult
    func append(_ segment: String) -> String {
        text = text.isEmpty ? segment : text + separator + segment
        count += 1
        onChange?()
        return text
    }

    func clear() {
        guard count > 0 else { return }
        text = ""
        count = 0
        onChange?()
    }
}
