import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let buffer = ClipboardBuffer()
    private var statusMenu: StatusMenuController?
    private var clipboardWatcher: ClipboardWatcher?
    private var pasteWatcher: PasteWatcher?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory) // menu bar only, no Dock icon

        statusMenu = StatusMenuController(buffer: buffer)
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
            self?.buffer.clear()
        }
        pasteWatcher?.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        clipboardWatcher?.stop()
        pasteWatcher?.stop()
    }
}
