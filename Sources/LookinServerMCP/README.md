# LookinServerMCP

Swift HTTP server в iOS debug-приложении: `127.0.0.1:47190`.

Реализация: `MCPHTTPServer.swift`, `MCPHTTPHandler.swift`, `MCPHTTPExtendedHandlers.swift`, `MCPHTTPModels.swift`.

## Cursor / AI agents

HTTP API **не** подключается к AI-агенту напрямую. Нужен MCP-мост **[lookin-ios-mcp/](../../lookin-ios-mcp/)**.

Полная инструкция (Cursor, Qwen Code): [docs/CURSOR_MCP_SETUP.md](../../docs/CURSOR_MCP_SETUP.md).

## HTTP routes

| Method | Path | Description |
|--------|------|-------------|
| GET | `/status` | App name, bundle id, screen metrics, Peertalk state |
| GET | `/hierarchy` | View/layer tree |
| GET | `/tap-targets` | Tappable views (oid, frame, title) |
| GET | `/text-inputs` | Typeable text inputs (UITextField, UITextView, UITextInput) |
| GET | `/view/:oid/attributes` | Attribute groups |
| POST | `/view/:oid/attributes` | Modify attribute |
| GET | `/view/:oid/screenshot` | PNG base64 |
| POST | `/tap` | Synthetic tap by `oid` or `x`+`y` |
| POST | `/swipe` | Synthetic swipe by `oid`+`direction` or coordinates |
| POST | `/type-text` | Type into `UITextField`/`UITextView`/`UITextInput` by `oid` or focused field |
| POST | `/keyboard` | Keyboard: `dismiss`, `return`, `insert`, `delete` |
| POST | `/long-press` | Long press by `oid` or `x`+`y`, optional `duration` (0.2–5s) |
| POST | `/find-view` | Search views by class, a11y, title, text |
| POST | `/view-at-point` | Hit-test at `x`+`y` |
| POST | `/tap-by-label` | Find view + tap center |
| POST | `/wait-for-view` | Poll `find-view` until match or timeout |
| POST | `/double-tap` | Double tap by `oid` or `x`+`y` |
| POST | `/drag` | Drag (alias of swipe) |
| POST | `/pinch` | Pinch zoom (`direction` in/out, optional `scale`) |
| POST | `/scroll` | Scroll `UIScrollView` by oid or point |
| POST | `/toggle` | `UISwitch` / `UISegmentedControl` |
| POST | `/select-row` | `UITableView` / `UICollectionView` row |
| POST | `/clear-text` | Clear text field |
| GET | `/view/:oid/custom-info` | Lookin custom attribute groups |
| GET | `/view/:oid/hierarchy-details` | Full inspector detail |
| POST | `/view/:oid/custom-attributes` | Modify custom attribute |
| POST | `/invoke-method` | Invoke parameterless selector on oid |
| POST | `/selectors` | List instance methods for class |
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

# Type text into a text field by oid
curl -sf -X POST http://127.0.0.1:47190/type-text \
  -H 'Content-Type: application/json' \
  -d '{"oid": 4393842944, "text": "hello"}'

# Dismiss keyboard
curl -sf -X POST http://127.0.0.1:47190/keyboard \
  -H 'Content-Type: application/json' \
  -d '{"action": "dismiss"}'

# Long press at coordinates
curl -sf -X POST http://127.0.0.1:47190/long-press \
  -H 'Content-Type: application/json' \
  -d '{"x": 195, "y": 400, "duration": 0.8}'
```

`direction` для swipe с `oid`: `up` (default), `down`, `left`, `right`.
