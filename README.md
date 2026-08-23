# CopyCopyCopy

A free, tiny Chrome/Edge extension: every `Ctrl+C` (or `Cmd+C`) on a web page
appends to one growing clipboard buffer instead of replacing it. Copy several
things in a row, then paste the combined result wherever you want. No account,
no tracking, no cost — just a `copy` event listener and `chrome.storage.local`.

Want this system-wide instead of just in the browser? See the
**[macOS menu bar app](mac-app/README.md)** — same idea, but works in every
Mac app.

By Matt Kain.

## Download & install

1. Download this repository — click the green **Code** button on GitHub and
   choose **Download ZIP**, then unzip it (or `git clone` it if you prefer).
2. Open `chrome://extensions` (or `edge://extensions`).
3. Turn on **Developer mode** (top right).
4. Click **Load unpacked** and select the unzipped `CopyCopyCopy` folder.
5. Pin the CopyCopyCopy icon in the toolbar if you want to see the running
   segment count as a badge.

## Use it

- Select text on any page and copy it as usual — it's appended to the buffer
  and the combined text is written back to your system clipboard.
- Click the toolbar icon to see a live preview and change the separator
  between segments (blank line / newline / space / custom).
- Paste (`Ctrl+V`/`Cmd+V`) anywhere, any time — it's a normal clipboard paste.
- Once you paste **inside a browser tab**, the buffer auto-clears so your next
  copy starts a fresh chain instead of tacking onto the old one.
- If you paste somewhere the extension can't see (see below), click
  **Clear buffer** in the toolbar popup to start fresh manually.

## Known limitations

- **Browser-only.** It only intercepts copies (and paste-triggered clears)
  made inside the browser. Copying from Finder, Terminal, Word, a PDF viewer,
  etc. won't append — it'll replace the clipboard as normal, since those apps
  are outside what a browser extension can see.
- **Auto-clear is also browser-only.** If you paste into another app (which
  is the whole point, most of the time), the extension never sees that paste,
  so the buffer keeps growing and the *next* in-browser copy will append onto
  whatever's still there. Use the **Clear buffer** button in the popup to
  reset it manually when that happens.
- **Selection-based.** It hooks the page's `copy` event and reads the current
  text selection, so it works on ordinary web text. It won't work on
  canvas/WebGL-rendered editors (e.g. Google Docs) or on copying non-text
  content like images.
- **Always on.** There's no off switch by design (per the current spec).

## Files

- `manifest.json` — MV3 extension manifest.
- `content.js` — runs on every page, intercepts `copy` (appends to
  `chrome.storage.local`, writes the combined text to the clipboard) and
  `paste` (clears the buffer).
- `background.js` — service worker, keeps the toolbar badge count in sync.
- `popup.html` / `popup.css` / `popup.js` — the toolbar popup UI (live
  preview + separator setting).

## License

[MIT](LICENSE) — free to use, copy, modify, and redistribute.
