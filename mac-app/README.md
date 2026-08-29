# CopyCopyCopy — macOS menu bar app

The system-wide sibling of the [CopyCopyCopy Chrome extension](../README.md).
Every `Cmd+C`, in *any* Mac app (not just the browser), appends to one
growing clipboard buffer. Paste (`Cmd+V`) anywhere and the buffer
auto-clears, ready for the next chain.

By Matt Kain. Free, unsigned, open source.

## How it works

- **Copy detection:** polls `NSPasteboard.general.changeCount` a few times
  a second. This needs no special permission — any app can read that value.
- **Paste detection:** pasting *reads* the clipboard, it doesn't write to
  it, so there's no pasteboard signal to poll for. The app uses a tiny
  global key watcher that recognizes only the `Cmd+V` combination (and its
  Shift/Option variants) to trigger the auto-clear. It does not log, store,
  or transmit any other keystroke. This requires macOS's **Input
  Monitoring** permission — see below.

## Build

Requires Xcode Command Line Tools (for `swift`), already on most Macs.

```bash
cd mac-app
./build.sh
```

This produces `CopyCopyCopy.app` in this folder.

## Install

1. Drag `CopyCopyCopy.app` into `/Applications`.
2. Double-click it. Because it's unsigned (no Apple Developer account),
   Gatekeeper will block the first launch — **right-click the app → Open →
   Open** instead, once.
3. A clipboard icon appears in the menu bar.
4. To auto-clear on paste, grant Input Monitoring: **System Settings →
   Privacy & Security → Input Monitoring → enable CopyCopyCopy**, then
   relaunch the app. (It'll prompt you toward this the first time it needs
   it.) Without this permission, copies still accumulate normally — you
   just won't get the auto-clear-on-paste behavior.

## Use it

- Copy things as usual, anywhere — Finder filenames, Terminal output,
  Pages, Mail, PDFs, whatever. Each copy appends to the buffer and the
  combined text is written back to your clipboard.
- Click the menu bar icon to see the segment count and a preview, change
  the separator joining segments (blank line / new line / space), or hit
  **Clear buffer** to purge the buffer and the system clipboard immediately.
- Paste anywhere — with Input Monitoring granted, the buffer also clears
  itself automatically. Either way purges the real clipboard, not just the
  segment count.

## Known limitations

- **Text only.** Like the browser extension, it reads the clipboard as
  plain text — copying images or files won't append.
- **Input Monitoring is required for auto-clear.** Without it, the buffer
  only grows on its own — use **Clear buffer** in the menu instead.
- **Unsigned build.** No Apple Developer account was used, so there's a
  one-time Gatekeeper warning on first launch (see Install above).

## Files

- `Package.swift` — Swift Package manifest (executable target, no
  external dependencies).
- `Sources/CopyCopyCopyMac/main.swift` — entry point.
- `AppDelegate.swift` — wires the pieces together on launch.
- `ClipboardBuffer.swift` — buffer/count/separator model, persisted via
  `UserDefaults`.
- `ClipboardWatcher.swift` — polls the pasteboard for copies.
- `PasteWatcher.swift` — the minimal Cmd+V-only global key watcher.
- `StatusMenuController.swift` — the menu bar icon and dropdown menu.
- `Info.plist` — app bundle metadata (menu-bar-only, no Dock icon).
- `build.sh` — builds and assembles `CopyCopyCopy.app`.

## License

[MIT](../LICENSE) — same as the Chrome extension.
