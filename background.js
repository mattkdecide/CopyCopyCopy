// CopyCopyCopy background service worker.
// Keeps the toolbar icon badge in sync with how many segments are
// currently appended to the buffer.
const COUNT_KEY = "ccc_count";

function updateBadge(count) {
  chrome.action.setBadgeText({ text: count > 0 ? String(count) : "" });
  chrome.action.setBadgeBackgroundColor({ color: "#2563eb" });
}

chrome.storage.local.get([COUNT_KEY], (res) => {
  updateBadge(res[COUNT_KEY] || 0);
});

chrome.storage.onChanged.addListener((changes, area) => {
  if (area !== "local") return;
  if (changes[COUNT_KEY]) {
    updateBadge(changes[COUNT_KEY].newValue || 0);
  }
});
