#!/usr/bin/env bash
# Ensure legacy ObjC layout: one exception-catch .m, no ObjCBridge folder.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CATCH_M="$ROOT/Sources/LookinServerOthers/LookinObjCExceptionCatch.m"
BASE="$ROOT/Sources/LookinServerBase"
MAX_BASE_H="${MAX_BASE_H:-3}"
OBJC_BRIDGE="$ROOT/Sources/LookinServerCore/ObjCBridge"

fail() {
  echo "verify_src_manifest: FAIL — $1" >&2
  exit 1
}

[[ -f "$CATCH_M" ]] || fail "missing $CATCH_M"
[[ ! -d "$OBJC_BRIDGE" ]] || fail "remove $OBJC_BRIDGE (migrated to LookinObjCExceptionCatch.m)"

legacy_m=$(find "$ROOT/Sources" -name '*.m' ! -path "$CATCH_M" 2>/dev/null | wc -l | tr -d ' ')
[[ "$legacy_m" == "0" ]] || fail "expected only LookinObjCExceptionCatch.m under Sources/, found $legacy_m other .m file(s)"

base_h=$(find "$BASE" -name '*.h' 2>/dev/null | wc -l | tr -d ' ')
if [[ "$base_h" -gt "$MAX_BASE_H" ]]; then
  fail "LookinServerBase *.h count $base_h exceeds max $MAX_BASE_H"
fi

if [[ -d "$ROOT/Src" ]]; then
  stray=$(find "$ROOT/Src" -type f 2>/dev/null | wc -l | tr -d ' ')
  [[ "$stray" == "0" ]] || fail "Src/ should be removed (found $stray file(s))"
fi

echo "RESULT: PASS — LookinObjCExceptionCatch.m + LookinServerBase ($base_h .h)"
