#!/usr/bin/env bash
# Build and launch LookinCustomInfoDemo on the iOS Simulator.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE="$ROOT/LookinCustomInfoDemo.xcworkspace"
SCHEME="LookinCustomInfoDemo"
BUNDLE_ID="Lookin.LookinCustomInfoDemoSwift"
SIM_NAME="${SIM_NAME:-iPhone 17 Pro}"

fail() { echo "run_demo: FAIL — $1" >&2; exit 1; }

[[ -d "$WORKSPACE" ]] || fail "Missing $WORKSPACE — run: cd \"$ROOT\" && pod install"

if [[ ! -d "$ROOT/Pods" ]]; then
  echo "run_demo: pod install..."
  (cd "$ROOT" && pod install)
fi

SIM_UDID="$(xcrun simctl list devices available -j | python3 -c "
import json, os, sys
name = os.environ.get('SIM_NAME', 'iPhone 17 Pro')
for d in json.load(sys.stdin).get('devices', {}).values():
  for dev in d:
    if dev.get('isAvailable') and name in dev.get('name', '') and 'iPhone' in dev.get('name', ''):
      print(dev['udid']); sys.exit(0)
sys.exit(1)
" 2>/dev/null)" || fail "Simulator not found: $SIM_NAME"

DD="${DERIVED_DATA:-/tmp/LookinCustomInfoDemo-DD}"
echo "run_demo: build (workspace required for CocoaPods)..."
xcodebuild -workspace "$WORKSPACE" -scheme "$SCHEME" -configuration Debug \
  -destination "id=$SIM_UDID" -derivedDataPath "$DD" build -quiet

APP="$DD/Build/Products/Debug-iphonesimulator/LookinCustomInfoDemo.app"
[[ -d "$APP" ]] || fail "Missing $APP after build"

xcrun simctl boot "$SIM_UDID" 2>/dev/null || true
open -a Simulator --args -CurrentDeviceUDID "$SIM_UDID" 2>/dev/null || true
xcrun simctl install "$SIM_UDID" "$APP"
xcrun simctl launch "$SIM_UDID" "$BUNDLE_ID"
echo "run_demo: launched $BUNDLE_ID on $SIM_NAME ($SIM_UDID)"
