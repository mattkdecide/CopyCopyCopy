// CopyCopyCopy content script.
// Listens for every "copy" event on the page and, instead of letting the
// browser replace the clipboard, appends the newly selected text onto a
// running buffer kept in chrome.storage.local.
(function () {
  const BUFFER_KEY = "ccc_buffer";
  const COUNT_KEY = "ccc_count";
  const SEPARATOR_KEY = "ccc_separator";
  const DEFAULT_SEPARATOR = "\n\n";

  let cachedBuffer = "";
  let cachedCount = 0;
  let cachedSeparator = DEFAULT_SEPARATOR;

  chrome.storage.local.get([BUFFER_KEY, COUNT_KEY, SEPARATOR_KEY], (res) => {
    cachedBuffer = res[BUFFER_KEY] || "";
    cachedCount = res[COUNT_KEY] || 0;
    cachedSeparator = res[SEPARATOR_KEY] ?? DEFAULT_SEPARATOR;
  });

  chrome.storage.onChanged.addListener((changes, area) => {
    if (area !== "local") return;
    if (changes[BUFFER_KEY]) cachedBuffer = changes[BUFFER_KEY].newValue || "";
    if (changes[COUNT_KEY]) cachedCount = changes[COUNT_KEY].newValue || 0;
    if (changes[SEPARATOR_KEY]) {
      cachedSeparator = changes[SEPARATOR_KEY].newValue ?? DEFAULT_SEPARATOR;
    }
  });

  document.addEventListener(
    "copy",
    (event) => {
      const selection = window.getSelection ? window.getSelection().toString() : "";
      if (!selection) return; // e.g. copying an image — let the browser do its default thing

      event.preventDefault();

      const newBuffer = cachedBuffer ? cachedBuffer + cachedSeparator + selection : selection;
      const newCount = cachedCount + 1;
      cachedBuffer = newBuffer;
      cachedCount = newCount;

      chrome.storage.local.set({ [BUFFER_KEY]: newBuffer, [COUNT_KEY]: newCount });

      navigator.clipboard.writeText(newBuffer).then(
        () => showToast(`Segment ${newCount} appended (${newBuffer.length} chars total)`),
        (err) => console.error("CopyCopyCopy: clipboard write failed", err)
      );
    },
    true
  );

  // Auto-clear: once the accumulated buffer has been pasted somewhere in the
  // browser, start the next copy chain fresh instead of appending to it.
  // Note: this only fires for pastes made inside a browser tab — a paste into
  // another app (Word, Terminal, etc.) is invisible to the extension, so the
  // buffer there won't auto-clear until the next in-browser paste or a manual
  // "Clear buffer" in the popup.
  document.addEventListener(
    "paste",
    () => {
      if (!cachedCount) return; // nothing accumulated, nothing to clear
      cachedBuffer = "";
      cachedCount = 0;
      chrome.storage.local.set({ [BUFFER_KEY]: "", [COUNT_KEY]: 0 });
      showToast("Buffer cleared — next copy starts a new chain");
    },
    true
  );

  function showToast(message) {
    let el = document.getElementById("__ccc_toast__");
    if (!el) {
      el = document.createElement("div");
      el.id = "__ccc_toast__";
      el.style.cssText =
        "position:fixed;bottom:16px;right:16px;z-index:2147483647;" +
        "background:#1f2937;color:#fff;padding:8px 12px;border-radius:8px;" +
        "font:12px -apple-system,system-ui,sans-serif;box-shadow:0 2px 8px rgba(0,0,0,.3);" +
        "opacity:0;transition:opacity .15s ease;pointer-events:none;";
      document.documentElement.appendChild(el);
    }
    el.textContent = `CopyCopyCopy: ${message}`;
    el.style.opacity = "1";
    clearTimeout(el._cccHideTimer);
    el._cccHideTimer = setTimeout(() => {
      el.style.opacity = "0";
    }, 1400);
  }
})();
