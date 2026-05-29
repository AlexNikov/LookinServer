#!/usr/bin/env bash
# Full automated verification (no user interaction).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
# shellcheck source=../../Lookin/Scripts/lookin_wire_version.sh
source "$ROOT/Lookin/Scripts/lookin_wire_version.sh"
LOOKIN_APP="$ROOT/Lookin"
LOOKIN_SERVER="$ROOT/LookinServer"
MCP_SAMPLE="$LOOKIN_SERVER/LookinDemo/LookinMCPSample"
BUNDLE_ID="Lookin.LookinMCPSample"
MCP_PORT=47190
FAIL=0

pass() { echo "✅ $*"; }
fail() { echo "❌ $*"; FAIL=1; }

section() { echo ""; echo "======== $1 ========"; }

section "A. Source checks (wire v2 only)"
grep -q 'respondWireV2' "$LOOKIN_SERVER/Sources/LookinServerConnection/LKS_ConnectionManager+WireV2.swift" \
  && pass 'respondWireV2 on iOS server' || fail 'missing respondWireV2'
grep -q 'LKWireCodecV2' "$LOOKIN_SERVER/Sources/LookinServerShared/LKWireCodec.swift" \
  || grep -q 'WireLookinFileCodec' "$LOOKIN_SERVER/Sources/LookinServerShared/LKWireCodec.swift" \
  && pass 'LKWireCodec uses file JSON v2' || fail 'LKWireCodec missing v2 file API'

NSKEYED_HITS="$(grep -R --include='*.swift' --include='*.m' --include='*.h' 'NSKeyedArchiver' \
  "$LOOKIN_SERVER/Sources" "$LOOKIN_APP/LookinClient/Connection" 2>/dev/null || true)"
if [[ -z "$NSKEYED_HITS" ]]; then
  pass 'no NSKeyedArchiver in wire sources (LookinServer/Sources + LookinClient/Connection)'
else
  fail "legacy NSKeyedArchiver still present:\n$NSKEYED_HITS"
fi

section "B. MCPSample pod (local path or git AlexNikov)"
cd "$MCP_SAMPLE"
if grep -q "AlexNikov/LookinServer" Podfile || grep -q 'install_lookin_server_pods!' Podfile; then
  pass 'MCPSample LookinServer pod configured'
else
  fail 'Podfile missing LookinServer source (path or git AlexNikov)'
fi
pod install 2>&1 | tail -3
POD_REV="$(grep -A2 'LookinServer' Podfile.lock | head -3)"
echo "$POD_REV"

section "C. Build & launch LookinMCPSample (iOS Simulator)"
DEST="$(xcrun simctl list devices available -j | python3 -c "
import json,sys
d=json.load(sys.stdin)['devices']
for runtime in sorted(d.keys(), reverse=True):
  if 'iOS' not in runtime: continue
  for dev in d[runtime]:
    if dev.get('isAvailable') and 'iPhone' in dev.get('name',''):
      print(dev['udid']); sys.exit(0)
")"
[[ -n "$DEST" ]] || { fail 'no iOS simulator'; exit 1; }
xcrun simctl boot "$DEST" 2>/dev/null || true
open -a Simulator 2>/dev/null || true

DD="$ROOT/lookin-verify-logs/DerivedData-verify-$$"
mkdir -p "$(dirname "$DD")"
xcodebuild -workspace LookinMCPSample.xcworkspace -scheme LookinMCPSample -configuration Debug \
  -destination "id=$DEST" -derivedDataPath "$DD" build CODE_SIGNING_ALLOWED=NO -quiet \
  && pass 'MCPSample build' || { fail 'MCPSample build'; exit 1; }

APP="$(find "$DD/Build/Products" -name 'LookinMCPSample.app' -type d | head -1)"
xcrun simctl install "$DEST" "$APP" 2>/dev/null || true
xcrun simctl terminate "$DEST" "$BUNDLE_ID" 2>/dev/null || true
xcrun simctl launch "$DEST" "$BUNDLE_ID" >/dev/null
sleep 4

section "D. MCP HTTP (wire-roundtrip + hierarchy)"
for i in 1 2 3 4 5 6 7 8 9 10; do
  if curl -sf --connect-timeout 1 "http://127.0.0.1:$MCP_PORT/ping" >/dev/null 2>&1; then break; fi
  sleep 1
done

WIRE_JSON="$(curl -sf --connect-timeout 3 "http://127.0.0.1:$MCP_PORT/wire-roundtrip" 2>/dev/null || echo '{}')"
echo "$WIRE_JSON" | python3 -c "
import sys, json
d = json.load(sys.stdin)
data = d.get('data') or d
pre = data.get('preArchiveRoots', data.get('preArchiveRootCount'))
ios = data.get('iosUnarchiveRoots', data.get('iosUnarchiveRootCount'))
b64 = data.get('wirePayloadBase64', '')
print(f'preArchiveRoots={pre} iosUnarchiveRoots={ios} b64_len={len(b64)}')
if pre and int(pre) > 0 and ios and int(ios) > 0:
    open('/tmp/wire.b64','w').write(b64)
    sys.exit(0)
sys.exit(1)
" && pass 'wire-roundtrip pre>0 ios>0' || fail 'wire-roundtrip failed'

HIER="$(curl -sf --connect-timeout 3 "http://127.0.0.1:$MCP_PORT/hierarchy" 2>/dev/null || echo '{}')"
echo "$HIER" | python3 -c "
import sys, json
d = json.load(sys.stdin)
data = d.get('data') or d
items = data.get('items', [])
print(f'hierarchy top-level items={len(items)} app={data.get(\"appName\",\"\")}')
sys.exit(0 if len(items) > 0 else 1)
" && pass 'MCP /hierarchy items>0' || fail 'MCP hierarchy empty'

section "E. Wire JSON roundtrip shape (MCP payload)"
python3 -c "
import json, base64, os, sys
expected = int(os.environ['LOOKIN_WIRE_VERSION'])
b64 = open('/tmp/wire.b64').read().strip()
doc = json.loads(base64.b64decode(b64))
hierarchy = doc.get('hierarchy') or {}
items = hierarchy.get('displayItems') or []
post = len(items)
wire_version = hierarchy.get('wireVersion') or doc.get('wireVersion')
print(f'wire JSON roots post={post} wireVersion={wire_version} expected={expected}')
sys.exit(0 if post > 0 and wire_version == expected else 1)
" && pass 'wire JSON roundtrip roots>0' || fail 'wire JSON roundtrip'

section "F. AlexNikov mac wire JSON decode"
"$LOOKIN_SERVER/Scripts/verify_ios_mac_wire.sh" "$(cat /tmp/wire.b64)" \
  && pass 'mac wire JSON decode' || fail 'ios_mac_wire decode'

section "Summary"
if [[ "$FAIL" -eq 0 ]]; then
  echo ""
  echo "🎉 ALL CHECKS PASSED"
  exit 0
else
  echo ""
  echo "⚠️  SOME CHECKS FAILED"
  exit 1
fi
