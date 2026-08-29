import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private static let enabledKey = "ccc_enabled"

    private let buffer = ClipboardBuffer()
    private var statusMenu: StatusMenuController?
    private var clipboardWatcher: ClipboardWatcher?
    private var hotkeyWatcher: HotkeyWatcher?

    /// Whether new copies are currently being appended. Toggled via the
    /// menu item or Ctrl+Cmd+C; persisted so a pause survives a relaunch.
    private var isEnabled = UserDefaults.standard.object(forKey: AppDelegate.enabledKey) as? Bool ?? true

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory) // menu bar only, no Dock icon

        statusMenu = StatusMenuController(
            buffer: buffer,
            isEnabled: isEnabled,
            onClearBuffer: { [weak self] in self?.performClearBuffer() },
            onToggleEnabled: { [weak self] in self?.toggleEnabled() }
        )
        buffer.onChange = { [weak self] in self?.statusMenu?.refresh() }

        clipboardWatcher = ClipboardWatcher { [weak self] copiedText in
            guard let self, self.isEnabled else { return }
            let combined = self.buffer.append(copiedText)
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(combined, forType: .string)
            self.clipboardWatcher?.recordSelfWrite()
        }
        clipboardWatcher?.start()

        hotkeyWatcher = HotkeyWatcher(
            onPaste: { [weak self] in self?.performClearBuffer() },
            onToggle: { [weak self] in self?.toggleEnabled() }
        )
        hotkeyWatcher?.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        clipboardWatcher?.stop()
        hotkeyWatcher?.stop()
    }

    /// Flips the paused/active state. Pausing only stops new copies from
    /// being appended — it doesn't touch whatever's already in the buffer,
    /// so Clear buffer and auto-clear-on-paste keep working exactly the
    /// same regardless of pause state.
    private func toggleEnabled() {
        isEnabled.toggle()
        UserDefaults.standard.set(isEnabled, forKey: Self.enabledKey)
        statusMenu?.setEnabled(isEnabled)
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
