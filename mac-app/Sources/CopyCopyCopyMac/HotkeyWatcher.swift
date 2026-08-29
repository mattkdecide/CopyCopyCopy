import AppKit
import IOKit.hid

/// Watches system-wide keyboard events for exactly two things: a paste
/// combo (Cmd+V, including Shift/Option variants) and the pause/resume
/// toggle combo (Ctrl+Cmd+C). It never inspects, logs, or stores any other
/// key. Detecting these requires macOS's Input Monitoring permission,
/// because they're read-only observations of physical keydowns — pasting
/// reads the clipboard rather than writing to it, so there's no pasteboard
/// signal to poll for either combo.
final class HotkeyWatcher {
    private var monitor: Any?
    private let onPaste: () -> Void
    private let onToggle: () -> Void

    init(onPaste: @escaping () -> Void, onToggle: @escaping () -> Void) {
        self.onPaste = onPaste
        self.onToggle = onToggle
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
        guard let key = event.charactersIgnoringModifiers?.lowercased() else { return }
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        if flags.contains(.command), key == "v" {
            onPaste()
            return
        }

        if flags == [.control, .command], key == "c" {
            onToggle()
        }
    }

    private func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "CopyCopyCopy needs Input Monitoring access"
        alert.informativeText =
            "To auto-clear the buffer on paste and toggle pause/resume with Ctrl+Cmd+C, " +
            "grant Input Monitoring access in System Settings → Privacy & Security → " +
            "Input Monitoring, then relaunch CopyCopyCopy. It only watches for the Cmd+V " +
            "and Ctrl+Cmd+C combinations — no keystrokes are logged or stored."
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Later")
        if alert.runModal() == .alertFirstButtonReturn {
            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")!
            NSWorkspace.shared.open(url)
        }
    }
}
