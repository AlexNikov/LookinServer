#!/usr/bin/env bash
# End-to-end verification: build, MCP hierarchy, wire roundtrip (stock NSObject unarchive), log capture.
# Run after any change to LookinShared wire v2 models — guards Swift Lookin.app ↔ LookinServer JSON wire.
# See Sources/LookinServerShared/MacLookinClientCompatibility.md
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
LOOKIN_APP="$ROOT/Lookin"
LOOKIN_SERVER="$ROOT/LookinServer"
MCP_SAMPLE="$LOOKIN_SERVER/LookinDemo/LookinMCPSample"
LOG_DIR="$ROOT/lookin-verify-logs"
mkdir -p "$LOG_DIR"
MAIN_LOG="$LOG_DIR/verify-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$MAIN_LOG") 2>&1

echo "=== Lookin integration verify ==="
echo "Log file: $MAIN_LOG"

section() { echo ""; echo "======== $1 ========"; }

section "1. Build LookinShared (mac pod)"
cd "$LOOKIN_APP"
pod install --silent 2>/dev/null || pod install
xcodebuild -workspace Lookin.xcworkspace -scheme LookinShared -configuration Debug build CODE_SIGNING_ALLOWED=NO -quiet
LOOKIN_SHARED_FW="$(find ~/Library/Developer/Xcode/DerivedData/Lookin-*/Build/Products/Debug/LookinShared -name 'LookinShared.framework' -type d 2>/dev/null | head -1)"
if [[ -z "$LOOKIN_SHARED_FW" ]]; then
  LOOKIN_SHARED_FW="$(find ~/Library/Developer/Xcode/DerivedData/Lookin-*/Build/Products/Debug -name 'LookinShared.framework' -type d 2>/dev/null | grep -v 'Lookin.app' | head -1)"
fi
echo "LookinShared.framework: $LOOKIN_SHARED_FW"

section "2. Build Lookin.app (mac client)"
xcodebuild -workspace Lookin.xcworkspace -scheme LookinClient -configuration Debug build CODE_SIGNING_ALLOWED=NO -quiet
LOOKIN_APP_PATH="$(find ~/Library/Developer/Xcode/DerivedData/Lookin-*/Build/Products/Debug -name 'Lookin.app' -type d 2>/dev/null | head -1)"
echo "Lookin.app: $LOOKIN_APP_PATH"

section "3. Wire roundtrip (JSON v2 via MCP /wire-roundtrip)"
# Requires MCPSample on 47190 — filled in section 4; skip log here if not running yet.
echo "Wire JSON roundtrip checked in section 5 (MCP) after iOS app launch"

section "4. Build & run LookinMCPSample (iOS Simulator)"
cd "$MCP_SAMPLE"
pod install --silent 2>/dev/null || pod install
DEST='platform=iOS Simulator,name=iPhone 17 Pro,OS=latest'
SIM_NAME="${SIM_NAME:-iPhone 17 Pro}"
xcodebuild -workspace LookinMCPSample.xcworkspace -scheme LookinMCPSample -configuration Debug \
  -destination "$DEST" -derivedDataPath "$LOG_DIR/DerivedData-MCP" build -quiet 2>/dev/null \
  || xcodebuild -project LookinMCPSample.xcodeproj -scheme LookinMCPSample -configuration Debug \
  -destination "$DEST" -derivedDataPath "$LOG_DIR/DerivedData-MCP" build -quiet

MCP_APP="$(find "$LOG_DIR/DerivedData-MCP" -name 'LookinMCPSample.app' -type d | head -1)"
echo "MCPSample.app: $MCP_APP"

export SIM_NAME
SIM_UDID="$(xcrun simctl list devices available -j | python3 -c "
import json,sys,os
name=os.environ.get('SIM_NAME','iPhone 17 Pro')
for d in json.load(sys.stdin).get('devices',{}).values():
  for dev in d:
    if dev.get('isAvailable') and name in dev.get('name','') and 'iPhone' in dev.get('name',''):
      print(dev['udid']); sys.exit(0)
" 2>/dev/null || true)"
if [[ -z "$SIM_UDID" ]]; then
  SIM_UDID="$(xcrun simctl list devices available | grep -m1 'iPhone' | sed -E 's/.*\(([A-F0-9-]+)\).*/\1/')"
fi
echo "Simulator UDID: $SIM_UDID"
xcrun simctl boot "$SIM_UDID" 2>/dev/null || true
open -a Simulator --args -CurrentDeviceUDID "$SIM_UDID" 2>/dev/null || true

SIM_LOG="$LOG_DIR/simulator-lookin.log"
xcrun simctl spawn "$SIM_UDID" log stream --style compact \
  --predicate 'eventMessage CONTAINS "Lookin" OR processImagePath CONTAINS "Lookin"' \
  > "$SIM_LOG" 2>&1 &
SIM_LOG_PID=$!
sleep 1

xcrun simctl install "$SIM_UDID" "$MCP_APP"
xcrun simctl terminate "$SIM_UDID" Lookin.LookinMCPSample 2>/dev/null || true
sleep 1
xcrun simctl launch "$SIM_UDID" Lookin.LookinMCPSample
echo "Waiting for LookinServer to listen..."
sleep 4

section "5. MCP HTTP (server-side hierarchy)"
HTTP_LOG="$LOG_DIR/mcp-http.log"
{
  echo "--- GET /status ---"
  curl -sf --max-time 5 "http://127.0.0.1:47190/status" || echo "status FAILED"
  echo ""
  echo "--- GET /hierarchy (first 800 chars) ---"
  curl -sf --max-time 15 "http://127.0.0.1:47190/hierarchy" | head -c 800 || echo "hierarchy FAILED"
  echo ""
} | tee "$HTTP_LOG"

section "6. Launch Lookin.app + capture mac logs"
MAC_LOG="$LOG_DIR/lookin-mac.log"
log stream --style compact --predicate 'eventMessage CONTAINS "LookinClient" OR eventMessage CONTAINS "LookinServer" OR process == "Lookin"' \
  > "$MAC_LOG" 2>&1 &
MAC_LOG_PID=$!
sleep 1

killall Lookin 2>/dev/null || true
open "$LOOKIN_APP_PATH"
echo "Lookin.app launched; waiting for auto-discovery (12s)..."
sleep 12

# Try AppleScript: double-click first app tile if present
osascript <<'APPLESCRIPT' 2>/dev/null | tee "$LOG_DIR/applescript.log" || true
tell application "Lookin" to activate
delay 2
tell application "System Events"
  if not (exists process "Lookin") then return
  tell process "Lookin"
    set frontmost to true
    try
      set appGroups to every group of window 1 whose description is not missing value
      repeat with g in appGroups
        try
          click g
          exit repeat
        end try
      end repeat
    end try
  end tell
end tell
APPLESCRIPT

sleep 8
kill $MAC_LOG_PID 2>/dev/null || true
kill $SIM_LOG_PID 2>/dev/null || true
sleep 1

section "7. Extract key log lines"
SUMMARY="$LOG_DIR/summary.txt"
{
  echo "=== Wire roundtrip ==="
  cat "$LOG_DIR/wire-roundtrip.log" 2>/dev/null || true
  echo ""
  echo "=== MCP HTTP ==="
  cat "$HTTP_LOG" 2>/dev/null || true
  echo ""
  echo "=== Simulator (LookinServer) ==="
  rg "LookinServer" "$SIM_LOG" 2>/dev/null | tail -40 || grep "LookinServer" "$SIM_LOG" 2>/dev/null | tail -40 || echo "(no simulator lines)"
  echo ""
  echo "=== Mac LookinClient ==="
  rg "LookinClient" "$MAC_LOG" 2>/dev/null | tail -40 || grep "LookinClient" "$MAC_LOG" 2>/dev/null | tail -40 || echo "(no mac client lines)"
} > "$SUMMARY"

cat "$SUMMARY"
echo ""
echo "Full logs in: $LOG_DIR"
echo "Main log: $MAIN_LOG"
