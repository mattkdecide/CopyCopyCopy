import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let buffer = ClipboardBuffer()
    private var statusMenu: StatusMenuController?
    private var clipboardWatcher: ClipboardWatcher?
    private var pasteWatcher: PasteWatcher?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory) // menu bar only, no Dock icon

        statusMenu = StatusMenuController(buffer: buffer, onClearBuffer: { [weak self] in self?.performClearBuffer() })
        buffer.onChange = { [weak self] in self?.statusMenu?.refresh() }

        clipboardWatcher = ClipboardWatcher { [weak self] copiedText in
            guard let self else { return }
            let combined = self.buffer.append(copiedText)
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(combined, forType: .string)
            self.clipboardWatcher?.recordSelfWrite()
        }
        clipboardWatcher?.start()

        pasteWatcher = PasteWatcher { [weak self] in
            self?.performClearBuffer()
        }
        pasteWatcher?.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        clipboardWatcher?.stop()
        pasteWatcher?.stop()
    }

    /// Resets the buffer's internal state AND purges the real system
    /// clipboard. Clearing only `buffer` (as the paste-triggered path used
    /// to do) left the last combined text sitting in NSPasteboard forever —
    /// this is the single place both the menu item and auto-clear-on-paste
    /// route through now, so neither one can drift out of sync again.
    private func performClearBuffer() {
        buffer.clear()
        NSPasteboard.general.clearContents()
        clipboardWatcher?.recordSelfWrite()
    }
}
