#!/usr/bin/env bash
# Roundtrip wire JSON Codable models (no device required).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOOKIN_ROOT="$(cd "$ROOT/.." && pwd)"
# shellcheck source=../../Lookin/Scripts/lookin_wire_version.sh
source "$LOOKIN_ROOT/Lookin/Scripts/lookin_wire_version.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

export LOOKIN_WIRE_VERSION
swift - <<'SWIFT' "$TMP"
import Foundation

let wireVersion = Int(ProcessInfo.processInfo.environment["LOOKIN_WIRE_VERSION"] ?? "") ?? 0
precondition(wireVersion > 0, "LOOKIN_WIRE_VERSION not set")

// Minimal copy of wire types for script-only verify when SwiftPM target unavailable.
struct WireRect: Codable { var x,y,w,h: Double }
struct WireDisplayItem: Codable {
    var oid: UInt
    var frame, bounds: WireRect
    var isHidden: Bool
    var alpha: Float
    var shouldCaptureImage: Bool
}
struct WireHierarchyPayload: Codable {
    var wireVersion: Int
    var serverVersion: Int32
    var displayItems: [WireDisplayItem]
}
let item = WireDisplayItem(
    oid: 42,
    frame: WireRect(x: 0, y: 0, w: 100, h: 200),
    bounds: WireRect(x: 0, y: 0, w: 100, h: 200),
    isHidden: false,
    alpha: 1,
    shouldCaptureImage: true
)
let payload = WireHierarchyPayload(wireVersion: wireVersion, serverVersion: 10004, displayItems: [item])
let data = try JSONEncoder().encode(payload)
let decoded = try JSONDecoder().decode(WireHierarchyPayload.self, from: data)
precondition(decoded.wireVersion == wireVersion)
precondition(decoded.displayItems.first?.oid == 42)
print("RESULT: PASS wire JSON roundtrip (inline script, wireVersion=\(wireVersion))")
SWIFT

echo "For full module roundtrip, build LookinServerShared and run integration verify."
