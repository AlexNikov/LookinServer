# LookinServerMCP

Swift HTTP server в iOS debug-приложении: `127.0.0.1:47190`.

Реализация: `MCPHTTPServer.swift`, `MCPHTTPHandler.swift`, `MCPHTTPModels.swift`. Старт из `LKS_ConnectionManager` через `NSClassFromString("LKS_MCPHTTPServer")`.

## Cursor / AI agents

HTTP API **не** подключается к AI-агенту напрямую. Нужен MCP-мост **[lookin-ios-mcp/](../../lookin-ios-mcp/)**.

Полная инструкция (Cursor, Qwen Code): [docs/CURSOR_MCP_SETUP.md](../../docs/CURSOR_MCP_SETUP.md).

## HTTP routes

| Method | Path | Description |
|--------|------|-------------|
| GET | `/status` | App name, bundle id, screen metrics, Peertalk state |
| GET | `/hierarchy` | View/layer tree |
| GET | `/tap-targets` | Tappable views (oid, frame, title) |
| GET | `/view/:oid/attributes` | Attribute groups |
| POST | `/view/:oid/attributes` | Modify attribute |
| GET | `/view/:oid/screenshot` | PNG base64 |
| POST | `/tap` | Synthetic tap by `oid` or `x`+`y` |
| POST | `/swipe` | Synthetic swipe by `oid`+`direction` or coordinates |
| GET | `/wire-roundtrip` | Wire v2 diagnostics |
| GET | `/wire-v2-selftest` | Wire v2 self-test |
| POST | `/relisten-peertalk` | Restart Peertalk listen (mac client reconnect) |

Ответы: `{ "success": true, "data": ... }` или `{ "success": false, "error": "..." }`.

## curl examples

```bash
# Status
curl -sf http://127.0.0.1:47190/status

# Hierarchy
curl -sf http://127.0.0.1:47190/hierarchy

# Tap by coordinates (window space)
curl -sf -X POST http://127.0.0.1:47190/tap \
  -H 'Content-Type: application/json' \
  -d '{"x": 195, "y": 400}'

# Tap by view oid (center of bounds)
curl -sf -X POST http://127.0.0.1:47190/tap \
  -H 'Content-Type: application/json' \
  -d '{"oid": 4393842944}'

# Swipe up within view bounds
curl -sf -X POST http://127.0.0.1:47190/swipe \
  -H 'Content-Type: application/json' \
  -d '{"oid": 4393842944, "direction": "up", "duration": 0.3}'

# Swipe by explicit coordinates
curl -sf -X POST http://127.0.0.1:47190/swipe \
  -H 'Content-Type: application/json' \
  -d '{"fromX": 195, "fromY": 600, "toX": 195, "toY": 200}'
```

`direction` для swipe с `oid`: `up` (default), `down`, `left`, `right`.
