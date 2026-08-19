"use strict";

// ---------------------------------------------------------------------------
// Backend bridge: Wails bindings when available, otherwise HTTP /api/*.
// ---------------------------------------------------------------------------
const isWails = typeof window.go !== "undefined";

const api = {
  call(method, ...args) {
    if (isWails) {
      const fn = window.go.main.App[method];
      if (!fn) return Promise.reject(new Error("Unknown method: " + method));
      return fn(...args);
    }
    return fetch("/api/" + method, { method: "POST", body: JSON.stringify(args) })
      .then((r) => r.json())
      .then((r) => {
        if (r.error) throw new Error(r.error);
        return r.result;
      });
  },
};

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------
const state = {
  worlds: [],
  selected: null,
};

const $ = (id) => document.getElementById(id);

function showStatus(text, cls) {
  const el = $("status");
  el.textContent = text;
  el.className = cls || "";
}

// ---------------------------------------------------------------------------
// Rendering
// ---------------------------------------------------------------------------
function refreshWorlds() {
  api.call("Worlds").then((worlds) => {
    state.worlds = worlds || [];
    const ul = $("worlds");
    ul.innerHTML = "";
    state.worlds.forEach((w) => {
      const li = document.createElement("li");
      if (state.selected === w.Name) li.classList.add("selected");

      const grass = document.createElement("span");
      grass.className = "grass";
      li.appendChild(grass);

      const radio = document.createElement("input");
      radio.type = "radio";
      radio.name = "world";
      radio.checked = state.selected === w.Name;
      radio.addEventListener("change", () => selectWorld(w.Name));
      li.appendChild(radio);

      const name = document.createElement("span");
      name.className = "w-name";
      name.textContent = w.Name;
      li.appendChild(name);

      li.addEventListener("click", () => {
        radio.checked = true;
        selectWorld(w.Name);
      });
      ul.appendChild(li);
    });
    $("empty").hidden = state.worlds.length > 0;
    updateButtons();
  }).catch((e) => showStatus(String(e), "error"));
}

function selectWorld(name) {
  state.selected = name;
  document.querySelectorAll("#worlds li").forEach((li) => {
    const radio = li.querySelector('input[type="radio"]');
    li.classList.toggle("selected", radio && radio.checked);
  });
  updateButtons();
}

function updateButtons() {
  const hasSel = state.selected !== null;
  $("play").disabled = !hasSel;
  $("delete").disabled = !hasSel;
}

// ---------------------------------------------------------------------------
// Dialogs
// ---------------------------------------------------------------------------
function showOverlay(id) { $(id).hidden = false; }
function hideOverlay(id) { $(id).hidden = true; }

function openCreate() {
  $("world-name").value = "";
  $("world-seed").value = "";
  showOverlay("dialog-overlay");
  $("world-name").focus();
}

function openDelete() {
  if (!state.selected) return;
  $("confirm-text").innerHTML = "Delete &laquo;" + state.selected + "&raquo;?";
  showOverlay("confirm-overlay");
}

function doCreate() {
  const name = $("world-name").value.trim();
  const seed = $("world-seed").value.trim();
  if (!name) { showStatus("Enter a world name.", "error"); return; }
  api.call("CreateWorld", name, seed)
    .then((created) => {
      hideOverlay("dialog-overlay");
      state.selected = created;
      refreshWorlds();
      showStatus("Ready to launch.");
    })
    .catch((e) => showStatus(String(e), "error"));
}

function doDelete() {
  const name = state.selected;
  if (!name) return;
  api.call("DeleteWorld", name)
    .then(() => {
      hideOverlay("confirm-overlay");
      state.selected = null;
      refreshWorlds();
      showStatus("Ready to launch.");
    })
    .catch((e) => showStatus(String(e), "error"));
}

// ---------------------------------------------------------------------------
// Game launch + status polling
// ---------------------------------------------------------------------------
let pollTimer = null;

function doPlay() {
  if (!state.selected) { showStatus("Select a world first.", "error"); return; }
  const nick = $("nick").value.trim();
  api.call("LaunchGame", state.selected, nick)
    .then(() => {
      showStatus("Launching game\u2026");
      pollGame();
    })
    .catch((e) => showStatus(String(e), "error"));
}

function pollGame() {
  clearInterval(pollTimer);
  pollTimer = setInterval(() => {
    api.call("GameRunning").then((running) => {
      if (!running) {
        clearInterval(pollTimer);
        refreshWorlds();
        showStatus("Ready to launch.");
      } else if (!$("status").classList.contains("running")) {
        showStatus("Game is running.", "running");
      }
    }).catch(() => { /* keep polling */ });
  }, 1000);
}

// ---------------------------------------------------------------------------
// Init
// ---------------------------------------------------------------------------
function init() {
  api.call("Config").then((cfg) => {
    $("nick").value = cfg && cfg.Nick ? cfg.Nick : "";
    if (!$("nick").value) {
      api.call("DefaultNick").then((n) => { if (!$("nick").value) $("nick").value = n; });
    }
    refreshWorlds();
  }).catch((e) => showStatus(String(e), "error"));

  api.call("Logo").then((dataUrl) => {
    if (dataUrl) {
      $("logo").src = dataUrl;
    } else {
      $("logo").style.display = "none";
      $("title").hidden = false;
    }
  });
}

$("nick").addEventListener("change", (e) => api.call("SetNick", e.target.value));
$("create").addEventListener("click", openCreate);
$("delete").addEventListener("click", openDelete);
$("play").addEventListener("click", doPlay);
$("open-folder").addEventListener("click", () => api.call("OpenFolder").catch((e) => showStatus(String(e), "error")));
$("dialog-ok").addEventListener("click", doCreate);
$("dialog-cancel").addEventListener("click", () => hideOverlay("dialog-overlay"));
$("confirm-ok").addEventListener("click", doDelete);
$("confirm-cancel").addEventListener("click", () => hideOverlay("confirm-overlay"));
document.getElementById("dialog-overlay").addEventListener("click", (e) => {
  if (e.target === e.currentTarget) hideOverlay("dialog-overlay");
});
document.getElementById("confirm-overlay").addEventListener("click", (e) => {
  if (e.target === e.currentTarget) hideOverlay("confirm-overlay");
});
$("world-name").addEventListener("keydown", (e) => { if (e.key === "Enter") doCreate(); });
$("world-seed").addEventListener("keydown", (e) => { if (e.key === "Enter") doCreate(); });

init();