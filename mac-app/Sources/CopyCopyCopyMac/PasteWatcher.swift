import AppKit
import IOKit.hid

/// Watches system-wide keyboard events for exactly one thing: a paste
/// combo (Cmd+V, including Cmd+Shift+V / Cmd+Option+V variants). It never
/// inspects, logs, or stores any other key. Detecting a paste this way
/// requires macOS's Input Monitoring permission, because pasting reads the
/// clipboard rather than writing to it — nothing observable via
/// NSPasteboard.changeCount, which only reflects writes.
final class PasteWatcher {
    private var monitor: Any?
    private let onPaste: () -> Void

    init(onPaste: @escaping () -> Void) {
        self.onPaste = onPaste
    }

    /// Prompts for Input Monitoring access if not already granted, then
    /// starts listening. Safe to call more than once.
    func start() {
        let access = IOHIDCheckAccess(kIOHIDRequestTypeListenEvent)
        if access == kIOHIDAccessTypeDenied {
            showPermissionAlert()
            return
        }
        if access == kIOHIDAccessTypeUnknown {
            IOHIDRequestAccess(kIOHIDRequestTypeListenEvent)
        }

        guard monitor == nil else { return }
        monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handle(event)
        }
    }

    func stop() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
    }

    private func handle(_ event: NSEvent) {
        guard event.modifierFlags.contains(.command) else { return }
        guard event.charactersIgnoringModifiers?.lowercased() == "v" else { return }
        onPaste()
    }

    private func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "CopyCopyCopy needs Input Monitoring access"
        alert.informativeText =
            "To auto-clear the buffer when you paste, grant Input Monitoring access in " +
            "System Settings → Privacy & Security → Input Monitoring, then relaunch " +
            "CopyCopyCopy. It only watches for the Cmd+V combination — no keystrokes are " +
            "logged or stored."
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Later")
        if alert.runModal() == .alertFirstButtonReturn {
            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")!
            NSWorkspace.shared.open(url)
        }
    }
}
