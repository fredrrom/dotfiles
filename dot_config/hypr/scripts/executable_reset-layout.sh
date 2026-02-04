#!/usr/bin/env bash
set -euo pipefail

# Monitors
MAIN_MON="DP-5"
SIDE_MON="DP-4"

# Workspace pairs (mode -> main/side)
WS_PROD_MAIN=1
WS_PROD_SIDE=11
WS_DEV_MAIN=2
WS_DEV_SIDE=12
WS_READ_MAIN=3
WS_READ_SIDE=13

# -------- helpers --------

need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing: $1"; exit 1; }; }
need hyprctl
need jq

clients_json() { hyprctl -j clients; }

# Find first window address matching jq predicate (string)
# Example predicate: '.class=="firefox" and (.title|test("Notion";"i"))'
find_addr() {
  local pred="$1"
  clients_json | jq -r ".[] | select($pred) | .address" | head -n 1
}

wait_addr() {
  local pred="$1"
  local tries="${2:-80}"   # ~8s at 0.1s
  local i=0
  while (( i < tries )); do
    local addr
    addr="$(find_addr "$pred" || true)"
    if [[ -n "${addr:-}" && "${addr}" != "null" ]]; then
      echo "$addr"
      return 0
    fi
    sleep 0.1
    ((i++))
  done
  echo "Timed out waiting for window: $pred" >&2
  return 1
}

# Move window by address to workspace + monitor
place() {
  local addr="$1"
  local ws="$2"
  local mon="$3"
  # move to workspace
  hyprctl dispatch movetoworkspace "$ws,address:$addr" >/dev/null
  # move to monitor (forces it onto the correct output)
  hyprctl dispatch movewindowtomonitor "$mon,address:$addr" >/dev/null
}

# Launch if not running (process-level)
run_if_not_running() {
  local proc_pat="$1"; shift
  if ! pgrep -f "$proc_pat" >/dev/null 2>&1; then
    "$@" &
  fi
}

# -------- launch apps (no placement assumptions) --------

# Productivity
run_if_not_running "thunderbird" thunderbird
run_if_not_running "^todoist$" todoist
# Notion via Firefox window (no PWA required)
run_if_not_running "firefox.*notion" firefox --new-window "https://www.notion.so"

# Development
run_if_not_running "^kitty$" kitty
run_if_not_running "^firefox$" firefox

# Reading
run_if_not_running "^zotero$" zotero
run_if_not_running "^kitty$" kitty

# -------- wait for windows, then place them --------
# NOTE: predicates below are best-effort. If any app reports a different class/app_id/title
# on your system, we’ll adjust the predicate after checking `hyprctl -j clients`.

# Notion (Firefox window whose title contains Notion)
NOTION_ADDR="$(wait_addr '.class=="firefox" and (.title|test("notion";"i"))')"
place "$NOTION_ADDR" "$WS_PROD_MAIN" "$MAIN_MON"

# Todoist (official app usually has class OR initialTitle containing Todoist)
TODOIST_ADDR="$(wait_addr '(.class|test("todoist";"i")) or (.initialTitle|test("todoist";"i"))')"
place "$TODOIST_ADDR" "$WS_PROD_SIDE" "$SIDE_MON"

# Thunderbird
TB_ADDR="$(wait_addr '(.class|test("thunderbird";"i"))')"
place "$TB_ADDR" "$WS_PROD_SIDE" "$SIDE_MON"

# Dev Firefox (a Firefox window that is NOT the Notion one)
DEV_FF_ADDR="$(wait_addr '.class=="firefox" and (.title|test("notion";"i")|not)')"
place "$DEV_FF_ADDR" "$WS_DEV_SIDE" "$SIDE_MON"

# Dev Kitty (first kitty window)
DEV_KITTY_ADDR="$(wait_addr '.class=="kitty"')"
place "$DEV_KITTY_ADDR" "$WS_DEV_MAIN" "$MAIN_MON"

# Zotero
ZOT_ADDR="$(wait_addr '(.class|test("zotero";"i"))')"
place "$ZOT_ADDR" "$WS_READ_MAIN" "$MAIN_MON"

# Reading terminal: we’ll place another kitty (if you only have one kitty window, it will get moved)
# Try to find a second kitty window different from DEV_KITTY_ADDR
READ_KITTY_ADDR="$(clients_json | jq -r --arg dev "$DEV_KITTY_ADDR" '.[] | select(.class=="kitty" and .address!=$dev) | .address' | head -n 1)"
if [[ -n "${READ_KITTY_ADDR:-}" && "${READ_KITTY_ADDR}" != "null" ]]; then
  place "$READ_KITTY_ADDR" "$WS_READ_SIDE" "$SIDE_MON"
fi

# Final: go to Productivity mode
hyprctl dispatch workspace "$WS_PROD_MAIN" >/dev/null
hyprctl dispatch workspace "$WS_PROD_SIDE" >/dev/null

