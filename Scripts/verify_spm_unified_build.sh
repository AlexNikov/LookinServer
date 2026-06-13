#!/usr/bin/env bash
# Build unified SPM targets locally (not remote git package).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="${DEST:-platform=iOS Simulator,name=iPhone 17 Pro}"
FAIL=0

echo "==> LookinShared (macOS)"
cd "$ROOT"
if ! swift build --target LookinShared -c debug; then
  echo "FAIL: LookinShared macOS build" >&2
  FAIL=1
fi

echo "==> LookinServer (iOS Simulator via Xcode scheme)"
if ! xcodebuild -scheme LookinServer \
  -destination "$DEST" \
  -configuration Debug \
  build -quiet; then
  echo "FAIL: LookinServer iOS Simulator build" >&2
  FAIL=1
fi

if [[ "$FAIL" -ne 0 ]]; then
  echo "RESULT: FAIL — verify_spm_unified_build" >&2
  exit 1
fi

echo "RESULT: PASS — verify_spm_unified_build (LookinShared macOS + LookinServer iOS)"
