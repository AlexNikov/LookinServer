#!/usr/bin/env bash
# Build all LookinServer iOS demos (CocoaPods workspace + SPM release sample).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
DEST="${DEST:-platform=iOS Simulator,name=iPhone 17 Pro}"
FAIL=0

build_pods_demo() {
  local dir="$1"
  local scheme="$2"
  echo "==> $scheme (CocoaPods)"
  cd "$dir"
  pod install --silent 2>/dev/null || pod install
  xcodebuild -workspace "${scheme}.xcworkspace" -scheme "$scheme" \
    -destination "$DEST" -configuration Debug build -quiet \
    || { echo "FAIL: $scheme" >&2; FAIL=1; }
}

build_pods_demo "$ROOT/LookinMCPSample" LookinMCPSample
build_pods_demo "$ROOT/LookinCustomInfoDemo" LookinCustomInfoDemo
build_pods_demo "$ROOT/LookinCollectionLayoutDemo" LookinCollectionLayoutDemo

echo "==> LookinDemoSwift (SPM remote package reference)"
cd "$ROOT/Swift_SPM_Release"
xcodebuild -project LookinDemoSwift.xcodeproj -scheme LookinDemoSwift \
  -destination "$DEST" -configuration Debug build -quiet \
  || { echo "FAIL: LookinDemoSwift" >&2; FAIL=1; }

if [[ "$FAIL" -ne 0 ]]; then
  echo "build_all_demos: FAIL" >&2
  exit 1
fi
echo "build_all_demos: PASS"
