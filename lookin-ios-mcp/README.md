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

## MCP tools (44)

### App context
`lookin_get_active_app`, `lookin_set_expected_app`, `lookin_clear_expected_app`

All view tools accept optional `expectedBundleId` and attach `_appContext.warning` when the foreground app changed since the last call.

### Inspect
`lookin_get_hierarchy`, `lookin_get_status`, `lookin_get_screen`, `lookin_get_tap_targets`, `lookin_list_text_inputs`, `lookin_get_attributes`, `lookin_get_all_properties`, `lookin_get_screenshot`, `lookin_compare_screenshots`, `lookin_get_custom_info`, `lookin_get_hierarchy_details`, `lookin_get_selectors`, `lookin_find_view`, `lookin_get_view_at_point`, `lookin_wait_for_view`, `lookin_get_orientation`, `lookin_get_appearance`, `lookin_get_logs`

`lookin_get_hierarchy` принимает `includeSystemViews` (по умолчанию всё дерево). `false` убирает контейнеры с именем на `_` и `UITransitionView`, `UIDropShadowView`, `UILayoutContainerView`, `UINavigationTransitionView`, `UIViewControllerWrapperView`, поднимая их детей. `lookin_get_screen` с `outline: true` добавляет дерево без frame и без пустых `children`.

### Gestures / input
`lookin_tap`, `lookin_tap_by_label`, `lookin_double_tap`, `lookin_long_press`, `lookin_swipe`, `lookin_drag`, `lookin_pinch`, `lookin_scroll`, `lookin_toggle`, `lookin_select_row`, `lookin_type_text`, `lookin_clear_text`, `lookin_keyboard`, `lookin_shake`

### Runtime / dev
`lookin_modify_attribute`, `lookin_modify_custom_attr`, `lookin_invoke_method`, `lookin_set_orientation`, `lookin_set_appearance`, `lookin_wire_selftest`, `lookin_relisten_peertalk`

### Device
`lookin_list_devices`, `lookin_connect_device`

## Файлы

| Файл | Назначение |
|------|------------|
| `index.mjs` | MCP server bootstrap |
| `register-tools.mjs` | MCP tool definitions |
| `client.mjs` | HTTP → `:47190` |
| `device-manager.mjs` | USB iproxy / simulator |
| `usbmuxd.mjs` | usbmuxd на Mac |

## Troubleshooting

- **Нет связи** — app не в Debug / не запущен; `curl http://127.0.0.1:47190/status`
- **Порт занят** — `lsof -ti tcp:47190`
- **Несколько устройств** — сначала `lookin_connect_device`
