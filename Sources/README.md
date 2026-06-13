# Sources/ — Swift source folders (LookinServer + LookinShared)

All runtime code lives under `Sources/**`, including ivar trace and the ObjC exception bridge.

**CocoaPods:** iOS apps integrate a single pod — [`LookinServer.podspec`](../LookinServer.podspec) (`LOOKIN_UNIFIED_MODULE=1`). Folders below are source layout, not separate pods. macOS Lookin client uses [`LookinShared.podspec`](../LookinShared.podspec).

**Swift Package Manager:** same layout — products `LookinServer` (full iOS/tvOS server) and `LookinShared` (wire/models subset for macOS client). SPM splits shared vs server-only sources because a `.swift` file can belong to only one target; server code uses `#if canImport(LookinShared) import LookinShared #endif` for CocoaPods parity. ObjC exception catch (`.m`) is target `LookinServerObjCBridge`.

| Folder | Role |
|--------|------|
| `LookinServerBase/` | `LookinIvarTrace` (`.h` + `.swift`) |
| `LookinServerOthers/LookinObjCExceptionCatch.m` | единственный ObjC: `@try/@catch` для `NSException` |
| `LookinServerShared/LookinObjCExceptionBridge.swift` | Swift API (`tryExecute` / `catchException`) |
| `LookinServerShared/` | Wire v2 (`Wire/`), `.lookin` codec (`LKWireCodec`), models, Peertalk helpers |
| `LookinServerCategories/` | UIKit/Foundation categories (Swift) |
| `LookinServerCore/` | Hierarchy makers, blueprint, invocation (Swift) |
| `LookinServerConnection/` | Peertalk connection + request handlers |
| `LookinServerPeertalk/` | Peertalk transport (Swift) |
| `LookinServerMCP/` | MCP HTTP `127.0.0.1:47190` |
| `LookinServerOthers/` | Config, trace, export, helpers |
| `LookinServerConnectionBootstrap/` | Server auto-start (Swift) |

Pod source lists for bridge + base: [`Scripts/lookin_src_manifest.rb`](../Scripts/lookin_src_manifest.rb).

## Wire protocol (production)

| Format | Role |
|--------|------|
| **Wire v2** | JSON `WireRequestEnvelope` / `WireResponseEnvelope` (`LKJS`) + PNG screenshot frames (`LKPG`) on Peertalk |
| **`.lookin` files** | `LKJ2` magic + JSON (`WireLookinFileCodec`) |

NSSecureCoding / wire v1 is **not** supported in Swift Lookin or Swift LookinServer. For historical ObjC wire behavior, compare against `Lookin-baseline+mcp` manually.

See [MacLookinClientCompatibility.md](LookinServerShared/MacLookinClientCompatibility.md).

## ObjC exception catch

| File | Purpose |
|------|---------|
| `LookinServerOthers/LookinObjCExceptionCatch.m` | `LookinCatchObjCException` (`@try/@catch`) |
| `LookinServerShared/LookinObjCExceptionBridge.swift` | Swift wrapper; `LookinObjectGetIvarSELName` in `.m` for gesture KVC |

ObjC cannot be removed entirely (Swift does not catch `NSException`). Validate:

```bash
bash LookinServer/Scripts/verify_src_manifest.sh
```

## CI inventory

```bash
bash LookinServer/Scripts/count_objc_legacy.sh
```

## Verify

| Symptom | Script |
|---------|--------|
| Custom info | `bash Lookin/Scripts/verify_custom_info_client.sh` |
| Inspector tree | `bash Lookin/Scripts/verify_ui_hierarchy_mcp.sh` (default: Swift + golden) |
| Tap | `bash Lookin/Scripts/verify_ui_tap_mcp.sh` (default: Swift + golden) |
| Wire v2 | `bash Lookin/Scripts/verify_wire_v2_ping.sh` |
| ObjC parity (manual/nightly) | `SKIP_OBJC_BASELINE=0` on hierarchy/tap/custom_info scripts |

Deprecated (wire v1, archived): `bash LookinServer/Scripts/archive/verify_qmui_wire_baseline.sh` — baseline-only, not CI. Use `verify_wire_v2_ping.sh`.
