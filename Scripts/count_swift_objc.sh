#!/usr/bin/env bash
# Inventory @objc / @objcMembers / legacy .h; fail if above baseline (G6/G7).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO="$(cd "$ROOT/.." && pwd)"
BASELINE="$ROOT/Scripts/objc_legacy_baseline.env"

if [[ ! -f "$BASELINE" ]]; then
  echo "count_swift_objc: FAIL — missing $BASELINE" >&2
  exit 1
fi
# shellcheck source=/dev/null
source "$BASELINE"

count_rg() {
  local pattern="$1"
  local path="$2"
  shift 2
  rg -c "$pattern" "$path" "$@" 2>/dev/null | awk -F: '{s+=$2} END {print s+0}'
  true
}

SHARED_LOOKIN=$(count_rg '@objc\(Lookin' "$ROOT/Sources/LookinServerShared" --glob '*.swift')
BASE_H=$(find "$ROOT/Sources/LookinServerBase" -name '*.h' 2>/dev/null | wc -l | tr -d ' ')
SOURCES_OBJC=$(count_rg '@objc\(' "$ROOT/Sources" --glob '*.swift')
SOURCES_OBJCMEMBERS=$(count_rg '@objcMembers' "$ROOT/Sources" --glob '*.swift')
MAC_CLIENT_OBJC=$(count_rg '@objc\(' "$REPO/Lookin/LookinClient" --glob '*.swift')

# G6: @objc( outside AppKit UI dirs and ShortCocoa/Connection wrappers
LOOKINCLIENT_NON_UI=$(rg -c '@objc\(' "$REPO/Lookin/LookinClient" --glob '*.swift' 2>/dev/null | awk -F: '
{
  f = $1; c = $2
  if (f ~ /\/Base\// || f ~ /\/Dashboard\// || f ~ /\/Static\// || f ~ /\/Connection\//) next
  s += c
}
END { print s+0 }')

LOG_DIR="$REPO/lookin-verify-logs"
mkdir -p "$LOG_DIR"
STAMP="$(date +%Y%m%d-%H%M%S)"
INVENTORY="$LOG_DIR/objc-inventory-${STAMP}.txt"

{
  echo "RESULT: swift_objc_inventory"
  echo "  LookinServerShared @objc(Lookin*: $SHARED_LOOKIN (baseline <= $SHARED_LOOKIN_OBJC_ATOBJC)"
  echo "  LookinServerBase *.h count:      $BASE_H (baseline <= $LOOKINBASE_H_COUNT)"
  echo "  LookinClient non-UI @objc(:       $LOOKINCLIENT_NON_UI (baseline <= $LOOKINCLIENT_NON_UI_OBJC_ATOBJC)"
  echo "  Sources @objc( total:            $SOURCES_OBJC"
  echo "  Sources @objcMembers total:      $SOURCES_OBJCMEMBERS"
  echo "  LookinClient @objc( total:       $MAC_CLIENT_OBJC (G12 baseline <= ${LOOKINCLIENT_TOTAL_OBJC_ATOBJC:-297})"
  echo ""
  echo "Top 10 files by @objc( in LookinServerShared:"
  rg -c '@objc\(' "$ROOT/Sources/LookinServerShared" --glob '*.swift' 2>/dev/null \
    | sort -t: -k2 -nr | head -10 || true
} | tee "$INVENTORY"

STATUS=0
if [[ "$SHARED_LOOKIN" -gt "$SHARED_LOOKIN_OBJC_ATOBJC" ]]; then
  echo "FAIL G7: LookinServerShared @objc(Lookin* $SHARED_LOOKIN exceeds baseline $SHARED_LOOKIN_OBJC_ATOBJC" >&2
  STATUS=1
fi
if [[ "$BASE_H" -gt "$LOOKINBASE_H_COUNT" ]]; then
  echo "FAIL: LookinServerBase *.h count $BASE_H exceeds baseline $LOOKINBASE_H_COUNT" >&2
  STATUS=1
fi
if [[ "$LOOKINCLIENT_NON_UI" -gt "$LOOKINCLIENT_NON_UI_OBJC_ATOBJC" ]]; then
  echo "FAIL G6: LookinClient non-UI @objc( $LOOKINCLIENT_NON_UI exceeds baseline $LOOKINCLIENT_NON_UI_OBJC_ATOBJC" >&2
  STATUS=1
fi
if [[ "$MAC_CLIENT_OBJC" -gt "${LOOKINCLIENT_TOTAL_OBJC_ATOBJC:-297}" ]]; then
  echo "FAIL G12: LookinClient total @objc( $MAC_CLIENT_OBJC exceeds baseline ${LOOKINCLIENT_TOTAL_OBJC_ATOBJC:-297}" >&2
  STATUS=1
fi

if [[ "$STATUS" -eq 0 ]]; then
  echo "count_swift_objc: PASS (inventory: $INVENTORY)"
fi
exit "$STATUS"
