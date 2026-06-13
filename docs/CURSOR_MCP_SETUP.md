# Lookin iOS MCP: Cursor, Qwen Code и другие агенты

Источник правды для инспекции iOS UI через LookinServer + **lookin-ios-mcp**.

## Архитектура

Один pod **недостаточен** для AI-агента. Нужны **два слоя**:

```
AI agent (Cursor / Qwen Code / …)
    │  MCP (stdio)
    ▼
lookin-ios-mcp          ← Node-мост: LookinServer/lookin-ios-mcp/
    │  HTTP REST
    ▼
LookinServer (pod MCP)  ← внутри iOS app, 127.0.0.1:47190
    │
    ▼
UIKit / CALayer
```

| Слой | Где | Порт | Роль |
|------|-----|------|------|
| **LookinServer** `subspec MCP` | iOS app (Debug) | `47190` | HTTP API: hierarchy, attributes, screenshot, tap, swipe |
| **lookin-ios-mcp** | `LookinServer/lookin-ios-mcp/` | — | MCP tools; USB port-forward через usbmuxd |

HTTP API в **Lookin.app** (macOS, `:47191` / `:47192`) — отдельный контур; для iOS — `lookin-ios`, для mac inspector verify — `lookin-verify` (только Cursor/monorepo).

---

## Установка

### Шаг 1 — Pod в iOS-проекте

```ruby
pod 'LookinServer', :subspecs => ['Swift', 'MCP'], :configurations => ['Debug']
```

> **Warning:** не подключайте LookinServer в Release.

Subspec `MCP` входит в `default_subspecs` podspec, но явное указание в Podfile снижает риск случайного отключения.

После изменений podspec в monorepo обновите поды mac-клиента при необходимости:

```bash
cd Lookin && pod install
```

### Шаг 2 — Запуск приложения

1. Соберите и запустите demo/app в **Debug** на симуляторе (foreground).
2. Предпочтительные демо: `LookinServer/LookinDemo/LookinMCPSample`, `LookinCustomInfoDemo`.

Smoke-тест HTTP:

```bash
curl -sf http://127.0.0.1:47190/status
curl -sf http://127.0.0.1:47190/hierarchy | head -c 200
```

Ожидается JSON с `"success": true`.

### Шаг 3 — Node-мост (Cursor)

```bash
cd LookinServer/lookin-ios-mcp && npm install
```

**Monorepo Lookin** — [`.cursor/mcp.json`](../../.cursor/mcp.json):

```json
{
  "mcpServers": {
    "lookin-ios": {
      "command": "node",
      "args": ["LookinServer/lookin-ios-mcp/index.mjs"]
    }
  }
}
```

**Только репозиторий LookinServer** — [`.cursor/mcp.json`](../.cursor/mcp.json):

```json
{
  "mcpServers": {
    "lookin-ios": {
      "command": "node",
      "args": ["lookin-ios-mcp/index.mjs"]
    }
  }
}
```

См. также [lookin-ios-mcp/README.md](../lookin-ios-mcp/README.md).

Перезапустите Cursor → **Settings → MCP** → включите `lookin-ios`.

### Шаг 3b — Node-мост (Qwen Code)

Требования: [Qwen Code CLI](https://qwenlm.github.io/qwen-code-docs/) и Node.js 18+.

```bash
cd LookinServer/lookin-ios-mcp && npm install
```

**Monorepo Lookin:** [`.qwen/settings.json`](../../.qwen/settings.json) — путь `LookinServer/lookin-ios-mcp/index.mjs`.

**Только LookinServer:** [`.qwen/settings.json`](../.qwen/settings.json) — путь `lookin-ios-mcp/index.mjs`.

**Вариант B — CLI** (из корня LookinServer):

```bash
qwen mcp add lookin-ios node lookin-ios-mcp/index.mjs -s project
```

Опционально macOS verify-мост (только monorepo Lookin):

```bash
qwen mcp add lookin-verify node .cursor/lookin-verify-mcp/index.mjs -s project
cd .cursor/lookin-verify-mcp && npm install
```

**Вариант C — вручную** в `~/.qwen/settings.json` или `.qwen/settings.json`:

```json
{
  "mcpServers": {
    "lookin-ios": {
      "command": "node",
      "args": ["lookin-ios-mcp/index.mjs"],
      "description": "LookinServer iOS — hierarchy, tap, swipe (:47190)",
      "timeout": 60000
    }
  }
}
```

Пути в `args` — **относительно корня проекта**, если `qwen` запущен из `Lookin/`.

Проверка в сессии Qwen Code:

```
/mcp list
```

Должен появиться `lookin-ios` со статусом connected (при запущенном iOS app).

Документация Qwen Code MCP: [MCP servers](https://qwenlm.github.io/qwen-code-docs/en/developers/tools/mcp-server/).

### Шаг 4 — Использование tools

Типичный workflow:

1. `lookin_get_hierarchy` / `lookin_get_tap_targets` / `lookin_find_view` — найти `oid`
2. `lookin_get_attributes` / `lookin_get_custom_info` — атрибуты
3. `lookin_get_screenshot` — скриншот
4. Жесты: `lookin_tap`, `lookin_tap_by_label`, `lookin_swipe`, `lookin_long_press`, `lookin_pinch`, `lookin_scroll`, …
5. Текст: `lookin_type_text`, `lookin_keyboard`, `lookin_clear_text`

**31 MCP tool** — полный список: [lookin-ios-mcp/README.md](../lookin-ios-mcp/README.md).

---

## MCP tools ↔ HTTP (основные)

| MCP tool | HTTP |
|----------|------|
| `lookin_get_status` | `GET /status` |
| `lookin_get_tap_targets` | `GET /tap-targets` |
| `lookin_find_view` | `POST /find-view` |
| `lookin_modify_attribute` | `POST /view/:oid/attributes` |
| `lookin_get_custom_info` | `GET /view/:oid/custom-info` |
| `lookin_invoke_method` | `POST /invoke-method` |
| `lookin_list_devices` | — (Mac) |
| `lookin_connect_device` | — (Mac iproxy) |

Полная таблица HTTP routes — [Sources/LookinServerMCP/README.md](../Sources/LookinServerMCP/README.md).

---

## USB-устройство

На симуляторе мост ходит на `http://127.0.0.1:47190` напрямую.

На физическом устройстве:

1. `lookin_list_devices` — список USB + booted simulators
2. `lookin_connect_device` с UDID — поднимает iproxy на Mac (`127.0.0.1:47191` → device `:47190`)
3. При нескольких устройствах view-tools (`hierarchy`, `tap`, …) требуют сначала выбрать target через `lookin_connect_device`

Приложение с LookinServer должно быть **в foreground** на устройстве.

---

## Monorepo Lookin vs только LookinServer

| Workspace | Путь в `mcp.json` |
|-----------|-------------------|
| Корень `Lookin/` | `LookinServer/lookin-ios-mcp/index.mjs` |
| Корень `LookinServer/` | `lookin-ios-mcp/index.mjs` |

Мост лежит в **[lookin-ios-mcp/README.md](../lookin-ios-mcp/README.md)** — отдельный README в этой папке.

**Fallback (без tap/swipe):** `npx -y lookin-mcp-ios` — upstream npm, устаревший набор tools.

---

## Troubleshooting

| Симптом | Решение |
|---------|---------|
| `Cannot connect to LookinServer` | App не запущен или не Debug; проверьте `curl http://127.0.0.1:47190/status` |
| Порт `:47190` занят | `lsof -ti tcp:47190` — убейте stale listener; перезапустите app |
| MCP `lookin-ios` не стартует (Cursor) | `cd LookinServer/lookin-ios-mcp && npm install`; Disable/Enable в Cursor |
| MCP `lookin-ios` не в списке (Qwen Code) | Запуск из корня workspace; `/mcp list`; `.qwen/settings.json` |
| `Tool expected a Zod schema` | `cd LookinServer/lookin-ios-mcp && npm install` |
| `multiple_devices` | Вызовите `lookin_connect_device` перед hierarchy/tap |
| IPv4 vs IPv6 | Предпочитайте `127.0.0.1:47190`; некоторые демо слушают `[::1]` |
| Subspec MCP не в сборке | Podfile: `:subspecs => ['Swift', 'MCP']`, только `Debug` |

Verify из monorepo:

```bash
bash Lookin/Scripts/verify_wire_v2_ping.sh
```

---

## Связанные файлы

| Файл | Назначение |
|------|------------|
| [Sources/LookinServerMCP/README.md](../Sources/LookinServerMCP/README.md) | HTTP routes, curl-примеры |
| [LookinDemo/LookinMCPSample/README.md](../LookinDemo/LookinMCPSample/README.md) | Smoke demo |
| [../../.cursor/MCP_SETUP.md](../../.cursor/MCP_SETUP.md) | Monorepo MCP (Cursor + Qwen Code) |
| [../../.qwen/settings.json](../../.qwen/settings.json) | Проектный конфиг Qwen Code |
| [lookin-ios-mcp/README.md](../lookin-ios-mcp/README.md) | MCP-мост: установка и tools |
| [lookin-ios-mcp/index.mjs](../lookin-ios-mcp/index.mjs) | Точка входа Node MCP |
