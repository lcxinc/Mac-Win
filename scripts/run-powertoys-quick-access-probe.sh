#!/usr/bin/env bash
set -euo pipefail

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  cat <<'EOF'
Usage: run-powertoys-quick-access-probe.sh

Environment overrides:
  MACWIN_POWETOYS_PREFIX=/path/to/prefix
  MACWIN_POWETOYS_EXE=/path/to/PowerToys.exe
  MACWIN_POWETOYS_TIMEOUT=60
  MACWIN_POWETOYS_REQUIRE_RENDERED=1
  MACWIN_POWETOYS_RUN_ID=unique-run-id
EOF
  exit 0
fi

ROOT="${MACWIN_ROOT:-$HOME/Library/Application Support/MacWin}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENGINE_ID="${MACWIN_ENGINE_ID:-wine-11.11-wow64-game}"
ENGINE_MANIFEST="$ROOT/Engines/$ENGINE_ID/manifest.json"
PREFIX="${MACWIN_POWETOYS_PREFIX:-$ROOT/SmokePrefixes/software-smoke-powertoys}"
POWETOYS_EXE="${MACWIN_POWETOYS_EXE:-$PREFIX/drive_c/users/$USER/AppData/Local/PowerToys/PowerToys.exe}"
EVENT_PROBE="${MACWIN_POWETOYS_EVENT_PROBE:-$PROJECT_ROOT/refs/exe-tests/bin/101_named_event_signal_probe.exe}"
WINDOW_PROBE="${MACWIN_POWETOYS_WINDOW_PROBE:-$PROJECT_ROOT/refs/exe-tests/bin/103_window_inventory_probe.exe}"
EVENT_NAME="${MACWIN_POWETOYS_EVENT_NAME:-Local\\PowerToysQuickAccess_32_Show}"
WINDOW_TITLE="${MACWIN_POWETOYS_WINDOW_TITLE:-PowerToys Quick Access}"
TIMEOUT="${MACWIN_POWETOYS_TIMEOUT:-60}"
REQUIRE_RENDERED="${MACWIN_POWETOYS_REQUIRE_RENDERED:-0}"
RUN_ID="${MACWIN_POWETOYS_RUN_ID:-powertoys-quick-access-$(date -u +%Y%m%dT%H%M%SZ)}"
LOG_DIR="$ROOT/Logs/SoftwareSmokeRuns/$RUN_ID"
RESULT_JSON="$LOG_DIR/quick-access-result.json"
CAPTURE_PNG="$LOG_DIR/quick-access.png"
ANALYSIS_JSON="$LOG_DIR/quick-access-analysis.json"

require_file() {
  if [ ! -f "$1" ]; then
    echo "Missing required file: $1" >&2
    exit 1
  fi
}

require_file "$ENGINE_MANIFEST"
require_file "$POWETOYS_EXE"
require_file "$EVENT_PROBE"
require_file "$WINDOW_PROBE"
mkdir -p "$LOG_DIR"

read_json_field() {
  /usr/bin/python3 - "$ENGINE_MANIFEST" "$1" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    value = json.load(handle)
for part in sys.argv[2].split("."):
    value = value[part]
print(value)
PY
}

WINE="$(read_json_field winePath)"
WINESERVER="$(read_json_field wineserverPath)"
RUNTIME="$(read_json_field runtimePath)"
require_file "$WINE"
require_file "$WINESERVER"

export WINEPREFIX="$PREFIX"
export WINEARCH=win64
export WINE_D3D_CONFIG="${WINE_D3D_CONFIG:-renderer=vulkan,csmt=0x0}"
export WINEDEBUG="${WINEDEBUG:--all}"
export DYLD_LIBRARY_PATH="$RUNTIME/lib64"
export MACWIN_MANAGED_LAUNCH=1
export MACWIN_DOCK_POLICY=managed-app-mode
export WINEDLLOVERRIDES="${WINEDLLOVERRIDES:-winemenubuilder.exe=d}"
WINE_CMD=(/usr/bin/env ALL_PROXY= HTTP_PROXY= HTTPS_PROXY= NO_PROXY= all_proxy= http_proxy= https_proxy= no_proxy= /usr/bin/arch -x86_64 "$WINE")
WINESERVER_CMD=(/usr/bin/env ALL_PROXY= HTTP_PROXY= HTTPS_PROXY= NO_PROXY= all_proxy= http_proxy= https_proxy= no_proxy= /usr/bin/arch -x86_64 "$WINESERVER")

cleanup() {
  "${WINESERVER_CMD[@]}" -k >/dev/null 2>&1 || true
}
trap cleanup EXIT INT TERM
cleanup

"${WINE_CMD[@]}" "$POWETOYS_EXE" >"$LOG_DIR/powertoys.log" 2>&1 &
powertoys_pid="$!"
window_line=""
event_signaled=0
elapsed=0

while kill -0 "$powertoys_pid" 2>/dev/null && [ "$elapsed" -lt "$TIMEOUT" ]; do
  sleep 2
  elapsed=$((elapsed + 2))
  if [ "$event_signaled" -eq 0 ] \
      && "${WINE_CMD[@]}" "$EVENT_PROBE" "$EVENT_NAME" >>"$LOG_DIR/event-probe.log" 2>&1; then
    event_signaled=1
  fi
  window_line="$(/usr/bin/swift "$SCRIPT_DIR/find-macos-window.swift" --discover-smallest wine "$WINDOW_TITLE" 2>/dev/null || true)"
  [ -n "$window_line" ] && break
done

"${WINE_CMD[@]}" "$WINDOW_PROBE" >"$LOG_DIR/window-inventory.log" 2>&1 || true

if [ -z "$window_line" ]; then
  /usr/bin/python3 - "$RESULT_JSON" "$elapsed" "$event_signaled" <<'PY'
import json
import sys

path, elapsed, event_signaled = sys.argv[1:]
with open(path, "w", encoding="utf-8") as handle:
    json.dump({
        "state": "failed",
        "classification": "window-not-found",
        "elapsedSeconds": int(elapsed),
        "eventSignaled": event_signaled == "1",
    }, handle, indent=2)
    handle.write("\n")
PY
  echo "Quick Access window was not found; result: $RESULT_JSON" >&2
  exit 1
fi

IFS=$'\t' read -r window_id window_owner window_name window_x window_y window_width window_height <<<"$window_line"
/usr/bin/swift "$SCRIPT_DIR/capture-macos-window.swift" "$window_id" "$CAPTURE_PNG" >"$LOG_DIR/capture.log"
classification="$(/usr/bin/python3 "$SCRIPT_DIR/analyze-window-image.py" "$CAPTURE_PNG" "$ANALYSIS_JSON")"

/usr/bin/python3 - "$RESULT_JSON" "$ANALYSIS_JSON" "$window_id" "$window_owner" "$window_name" \
  "$window_x" "$window_y" "$window_width" "$window_height" "$elapsed" "$event_signaled" <<'PY'
import json
import sys

(path, analysis_path, window_id, owner, title, x, y, width, height,
 elapsed, event_signaled) = sys.argv[1:]
with open(analysis_path, encoding="utf-8") as handle:
    analysis = json.load(handle)
classification = analysis["classification"]
event_was_signaled = event_signaled == "1"
if classification == "rendered":
    state = "passed" if event_was_signaled else "failed"
else:
    state = "pending"
with open(path, "w", encoding="utf-8") as handle:
    json.dump({
        "state": state,
        "classification": classification,
        "eventSignaled": event_was_signaled,
        "elapsedSeconds": int(elapsed),
        "window": {
            "id": int(window_id),
            "owner": owner,
            "title": title,
            "bounds": [int(x), int(y), int(width), int(height)],
        },
        "analysis": analysis,
    }, handle, ensure_ascii=False, indent=2)
    handle.write("\n")
PY

echo "Quick Access classification: $classification"
echo "Result: $RESULT_JSON"
if [ "$event_signaled" != "1" ] \
    || { [ "$classification" != "rendered" ] && [ "$REQUIRE_RENDERED" = "1" ]; }; then
  exit 1
fi
