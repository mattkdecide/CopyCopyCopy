const BUFFER_KEY = "ccc_buffer";
const COUNT_KEY = "ccc_count";
const SEPARATOR_KEY = "ccc_separator";
const DEFAULT_SEPARATOR = "\n\n";

const preview = document.getElementById("preview");
const stats = document.getElementById("stats");
const separatorSelect = document.getElementById("separator");
const customSeparator = document.getElementById("customSeparator");
const clearBuffer = document.getElementById("clearBuffer");

const KNOWN_SEPARATORS = ["\n\n", "\n", " "];

function render() {
  chrome.storage.local.get([BUFFER_KEY, COUNT_KEY, SEPARATOR_KEY], (res) => {
    const buffer = res[BUFFER_KEY] || "";
    const count = res[COUNT_KEY] || 0;
    const separator = res[SEPARATOR_KEY] ?? DEFAULT_SEPARATOR;

    preview.value = buffer;
    stats.textContent = `${count} segment${count === 1 ? "" : "s"} · ${buffer.length} chars`;

    if (KNOWN_SEPARATORS.includes(separator)) {
      separatorSelect.value = separator;
      customSeparator.hidden = true;
    } else {
      separatorSelect.value = "custom";
      customSeparator.hidden = false;
      customSeparator.value = separator;
    }
  });
}

separatorSelect.addEventListener("change", () => {
  if (separatorSelect.value === "custom") {
    customSeparator.hidden = false;
    customSeparator.focus();
    chrome.storage.local.set({ [SEPARATOR_KEY]: customSeparator.value });
  } else {
    customSeparator.hidden = true;
    chrome.storage.local.set({ [SEPARATOR_KEY]: separatorSelect.value });
  }
});

customSeparator.addEventListener("input", () => {
  chrome.storage.local.set({ [SEPARATOR_KEY]: customSeparator.value });
});

clearBuffer.addEventListener("click", () => {
  chrome.storage.local.set({ [BUFFER_KEY]: "", [COUNT_KEY]: 0 });
  navigator.clipboard.writeText("").catch((err) => {
    console.error("CopyCopyCopy: failed to purge clipboard", err);
  });
});

chrome.storage.onChanged.addListener((changes, area) => {
  if (area === "local") render();
});

render();
