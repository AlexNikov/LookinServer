#!/usr/bin/env bash
# CI-friendly regression counters for ObjC legacy cleanup.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO="$(cd "$ROOT/.." && pwd)"

# Only LookinObjCExceptionCatch.m is allowed under Sources/.
MAX_LEGACY_M="${MAX_LEGACY_M:-1}"

count_rg() {
  local pattern="$1"
  local path="$2"
  rg -c "$pattern" "$path" 2>/dev/null | awk -F: '{s+=$2} END {print s+0}'
  true
}

LEGACY_M=$(find "$ROOT/Sources" -name '*.m' 2>/dev/null | wc -l | tr -d ' ')
SOURCES_OBJC=$(count_rg '@objc\(' "$ROOT/Sources")
LOOKIN_SWIFT_FLAGS=$(rg -l 'LOOKIN_.*_SWIFT' "$ROOT" --glob '*.{podspec,swift}' 2>/dev/null | wc -l | tr -d ' ' || true)
LOOKIN_SWIFT_FLAGS=${LOOKIN_SWIFT_FLAGS:-0}
MAC_CLIENT_OBJC=$(count_rg '@objc\(' "$REPO/Lookin/LookinClient")

STATUS=0
if [[ "$LEGACY_M" -gt "$MAX_LEGACY_M" ]]; then
  echo "FAIL: Sources/*.m count $LEGACY_M exceeds max $MAX_LEGACY_M" >&2
  find "$ROOT/Sources" -name '*.m' 2>/dev/null >&2
  STATUS=1
fi

echo "RESULT: objc_legacy_inventory"
echo "  Sources/*.m count:         $LEGACY_M (max $MAX_LEGACY_M)"
echo "  Sources @objc( count:     $SOURCES_OBJC"
echo "  LOOKIN_*_SWIFT refs:      $LOOKIN_SWIFT_FLAGS"
echo "  LookinClient @objc( count: $MAC_CLIENT_OBJC"

exit "$STATUS"
