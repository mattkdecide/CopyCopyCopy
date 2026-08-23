import AppKit

/// Polls NSPasteboard.general.changeCount to detect copies system-wide.
/// No special permission is required for this: it only reads a value the
/// OS already exposes to every app. It ignores changes it caused itself
/// (writing the combined buffer back to the pasteboard after an append).
final class ClipboardWatcher {
    private static let pollInterval: TimeInterval = 0.3

    private let pasteboard = NSPasteboard.general
    private var lastSeenChangeCount: Int
    private var timer: Timer?
    private let onExternalCopy: (String) -> Void

    init(onExternalCopy: @escaping (String) -> Void) {
        self.lastSeenChangeCount = NSPasteboard.general.changeCount
        self.onExternalCopy = onExternalCopy
    }

    func start() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: Self.pollInterval, repeats: true) { [weak self] _ in
            self?.poll()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    /// Call this right after CopyCopyCopy writes its own combined buffer to
    /// the pasteboard, so that write isn't mistaken for a new external copy.
    func recordSelfWrite() {
        lastSeenChangeCount = pasteboard.changeCount
    }

    private func poll() {
        let current = pasteboard.changeCount
        guard current != lastSeenChangeCount else { return }
        lastSeenChangeCount = current

        guard let copied = pasteboard.string(forType: .string), !copied.isEmpty else { return }
        onExternalCopy(copied)
    }
}
