#!/usr/bin/env bash
# Decodes a /wire-roundtrip JSON payload (wire v2) — same shape as Peertalk LKJS hierarchy response.
set -euo pipefail

B64="${1:-}"

if [[ -z "$B64" ]]; then
  echo "Usage: $0 <wirePayloadBase64>"
  echo "  curl -s http://127.0.0.1:47190/wire-roundtrip | python3 -c \"import sys,json; print(json.load(sys.stdin)['data']['wirePayloadBase64'])\" | xargs $0"
  exit 1
fi

python3 -c "
import json, base64, sys
b64 = sys.argv[1].strip()
doc = json.loads(base64.b64decode(b64))
h = doc.get('hierarchy') or {}
items = h.get('displayItems') or []
roots = len(items)
print(f'mac decode roots: {roots} wireFormat={doc.get(\"wireFormat\", \"unknown\")}')
sys.exit(0 if roots > 0 else 1)
" "$B64"
