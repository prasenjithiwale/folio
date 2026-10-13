// folio — copy buttons, terminal tabs and release details. Pages work without it.

// Copy buttons: <button class="copy" data-copy="#id-of-code">
for (const button of document.querySelectorAll("button.copy")) {
  button.addEventListener("click", async () => {
    const text = document.querySelector(button.dataset.copy).textContent.trim();
    try {
      await navigator.clipboard.writeText(text);
      button.textContent = "Copied";
      button.dataset.state = "done";
    } catch {
      button.textContent = "Select and copy";
    }
    setTimeout(() => {
      button.textContent = "Copy";
      delete button.dataset.state;
    }, 2000);
  });
}

// Tabs: a [role=tablist] whose tabs control [role=tabpanel] elements.
for (const list of document.querySelectorAll('[role="tablist"]')) {
  const tabs = [...list.querySelectorAll('[role="tab"]')];
  const select = (tab, focus) => {
    for (const other of tabs) {
      const selected = other === tab;
      other.setAttribute("aria-selected", String(selected));
      other.tabIndex = selected ? 0 : -1;
      document.getElementById(other.getAttribute("aria-controls")).hidden = !selected;
    }
    if (focus) tab.focus();
  };
  for (const tab of tabs) {
    tab.addEventListener("click", () => select(tab, false));
    tab.addEventListener("keydown", (event) => {
      const i = tabs.indexOf(tab);
      const next = { ArrowRight: i + 1, ArrowLeft: i - 1, Home: 0, End: tabs.length - 1 }[event.key];
      if (next === undefined) return;
      event.preventDefault();
      select(tabs[(next + tabs.length) % tabs.length], true);
    });
  }
}

// Release details: elements with data-release="version|date|size|download|sha256"
// inside a container with data-releases="<url of the releases folder>/".
for (const root of document.querySelectorAll("[data-releases]")) {
  const base = root.dataset.releases;
  fetch(base + "latest.json", { cache: "no-cache" })
    .then((response) => (response.ok ? response.json() : Promise.reject(response.status)))
    .then((release) => {
      const asset = release.assets[0];
      const date = new Date(release.published_at).toLocaleDateString(undefined, {
        year: "numeric", month: "short", day: "numeric",
      });
      const values = {
        version: release.version,
        date,
        size: `${(asset.size / 1048576).toFixed(1)} MB`,
        sha256: asset.sha256,
      };
      for (const el of root.querySelectorAll("[data-release]")) {
        const key = el.dataset.release;
        if (key === "download") el.href = base + asset.url;
        else if (key in values) el.textContent = values[key];
      }
      root.dataset.loaded = "true";
    })
    .catch(() => {
      root.dataset.loaded = "false";
    });
}
