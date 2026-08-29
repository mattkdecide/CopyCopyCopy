import AppKit

/// Owns the menu bar (NSStatusItem) icon and its dropdown menu: a live
/// segment-count badge, a truncated preview of the buffer, the separator
/// picker, and a manual "Clear buffer" item. Auto-clear-on-paste also runs,
/// but pasting outside the browser/app sandbox this watches, or without
/// Input Monitoring permission granted, won't trigger it — the menu item is
/// the reliable fallback.
final class StatusMenuController {
    private static let previewCharacterLimit = 200

    private let statusItem: NSStatusItem
    private let buffer: ClipboardBuffer
    private let onClearBuffer: () -> Void

    init(buffer: ClipboardBuffer, onClearBuffer: @escaping () -> Void) {
        self.buffer = buffer
        self.onClearBuffer = onClearBuffer
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = NSImage(
            systemSymbolName: "doc.on.clipboard",
            accessibilityDescription: "CopyCopyCopy"
        )
        statusItem.button?.imagePosition = .imageLeft
        rebuildMenu()
    }

    func refresh() {
        updateStatusTitle()
        rebuildMenu()
    }

    private func updateStatusTitle() {
        statusItem.button?.title = buffer.count > 0 ? " \(buffer.count)" : ""
    }

    private func rebuildMenu() {
        let menu = NSMenu()

        let statsItem = NSMenuItem(
            title: "\(buffer.count) segment\(buffer.count == 1 ? "" : "s") · \(buffer.text.count) chars",
            action: nil,
            keyEquivalent: ""
        )
        statsItem.isEnabled = false
        menu.addItem(statsItem)

        let previewItem = NSMenuItem(title: previewText(), action: nil, keyEquivalent: "")
        previewItem.isEnabled = false
        menu.addItem(previewItem)

        menu.addItem(.separator())

        let separatorMenu = NSMenu()
        for option in separatorOptions {
            let item = NSMenuItem(
                title: option.title,
                action: #selector(selectSeparator(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = option.value
            item.state = buffer.separator == option.value ? .on : .off
            separatorMenu.addItem(item)
        }
        let separatorItem = NSMenuItem(title: "Join segments with", action: nil, keyEquivalent: "")
        separatorItem.submenu = separatorMenu
        menu.addItem(separatorItem)

        menu.addItem(.separator())
        let clearItem = NSMenuItem(title: "Clear buffer", action: #selector(clearBuffer), keyEquivalent: "")
        clearItem.target = self
        menu.addItem(clearItem)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit CopyCopyCopy", action: #selector(quit), keyEquivalent: "q"))

        menu.items.last?.target = self
        statusItem.menu = menu
        updateStatusTitle()
    }

    private func previewText() -> String {
        guard !buffer.text.isEmpty else { return "Copy something anywhere on your Mac to start." }
        let collapsed = buffer.text.replacingOccurrences(of: "\n", with: " ⏎ ")
        if collapsed.count <= Self.previewCharacterLimit { return collapsed }
        return String(collapsed.prefix(Self.previewCharacterLimit)) + "…"
    }

    private var separatorOptions: [(title: String, value: String)] {
        [
            ("Blank line", ClipboardBuffer.blankLineSeparator),
            ("New line", ClipboardBuffer.newLineSeparator),
            ("Space", ClipboardBuffer.spaceSeparator),
        ]
    }

    @objc private func selectSeparator(_ sender: NSMenuItem) {
        guard let value = sender.representedObject as? String else { return }
        buffer.separator = value
    }

    @objc private func clearBuffer() {
        onClearBuffer()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
