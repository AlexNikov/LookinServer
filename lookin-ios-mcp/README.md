# lookin-ios-mcp

Node.js MCP-мост для AI-агентов (Cursor, Qwen Code, Claude Code и др.): stdio MCP → HTTP LookinServer в iOS app (`127.0.0.1:47190`).

Полная инструкция (pod + симулятор + USB): [../docs/CURSOR_MCP_SETUP.md](../docs/CURSOR_MCP_SETUP.md).

## Зачем две части

| Часть | Где | Роль |
|-------|-----|------|
| **LookinServer** pod `MCP` | iOS app Debug | HTTP API на `:47190` |
| **lookin-ios-mcp** (эта папка) | Mac, Node 18+ | MCP tools для агента |

Одного pod **недостаточно** — агент не говорит с `:47190` напрямую.

## Установка

### 1. Pod в iOS-проекте

```ruby
pod 'LookinServer', :subspecs => ['Swift', 'MCP'], :configurations => ['Debug']
```

### 2. Зависимости моста

```bash
cd lookin-ios-mcp
npm install
```

### 3. Запуск iOS app

Соберите и запустите приложение в **Debug** на симуляторе (foreground).

```bash
curl -sf http://127.0.0.1:47190/status
```

### 4. Подключение агента

**Cursor** — в `.cursor/mcp.json` (корень monorepo `Lookin/` или этот репозиторий):

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

Из monorepo Lookin путь: `LookinServer/lookin-ios-mcp/index.mjs`.

**Qwen Code** — `.qwen/settings.json`:

```json
{
  "mcpServers": {
    "lookin-ios": {
      "command": "node",
      "args": ["lookin-ios-mcp/index.mjs"],
      "timeout": 60000
    }
  }
}
```

Или CLI:

```bash
qwen mcp add lookin-ios node lookin-ios-mcp/index.mjs -s project
```

Проверка: `/mcp list` → `lookin-ios` connected.

## MCP tools (7)

| Tool | Назначение |
|------|------------|
| `lookin_get_hierarchy` | Дерево UI |
| `lookin_get_attributes` | Атрибуты view |
| `lookin_get_screenshot` | PNG скриншот |
| `lookin_tap` | Синтетический тап |
| `lookin_swipe` | Синтетический свайп |
| `lookin_list_devices` | USB + simulators |
| `lookin_connect_device` | Выбор sim / USB |

## Файлы

| Файл | Назначение |
|------|------------|
| `index.mjs` | MCP server (tools) |
| `client.mjs` | HTTP → `:47190` |
| `device-manager.mjs` | USB iproxy / simulator |
| `usbmuxd.mjs` | usbmuxd на Mac |

## Troubleshooting

- **Нет связи** — app не в Debug / не запущен; `curl http://127.0.0.1:47190/status`
- **Порт занят** — `lsof -ti tcp:47190`
- **Несколько устройств** — сначала `lookin_connect_device`
