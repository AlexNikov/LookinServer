# Совместимость со Swift Lookin.app (mac-клиент)

Lookin.app и LookinServer обмениваются данными **только** через wire v2: JSON (`LKJS` / `WireRequestEnvelope`) и бинарные скриншоты (`LKPG`). NSSecureCoding / `NSKeyedArchiver` для Peertalk **не используются**.

## Обязательно сохранять

### 1. Wire v2 маппинг (`WireRequestResponseMapper`, `WireHierarchyMapper`)

Все `LookinRequestType` (200–214) и push (303–304) должны кодироваться/декодироваться через `Wire*` struct и `LKWireCodecV2`.

### 2. `LookinConnectionAttachment` / ответы

Внутренний API mac/iOS по-прежнему использует `LookinConnectionResponseAttachment`; на wire уходит `WireResponseEnvelope`, не keyed archive.

### 3. Ключи и семантика полей wire JSON

Не менять имена полей в `WireCodableModels` без bump версии протокола.

`LookinAttrType.json` → `WireAttrValue.kind == "json"` + `jsonDocument` (UTF-8). Mac dashboard разбирает через `LookinJSONAttributeSupport` (дерево `title` / `desc` / `details`).

`LookinAttrType.customObj` → `WireAttrValue.kind == "custom"` + `customSummary` (или `string` для NSString).

Клиентские запросы: `WireClientRequestPayload` → `WireRequestEnvelope` (без `NSDictionary` в `LKInspectableApp` / `LKAppsManager`).

### 4. `LookinGeometryCoding` / скриншоты

- iOS отдаёт detail JSON + `LKPG` PNG.
- Mac буферизует скриншоты до появления oid в иерархии (`LKConnectionManager+WireV2`).

### 5. `.lookin` на диске

Только `LKJ2` + JSON (`WireLookinFileCodec`). Legacy v1 не открывается.

### 6. Negotiation

Hierarchy-запрос шлёт `minWireVersion: 2`. Сервер всегда отвечает wire v2.

## Проверка после изменений

```bash
Lookin/Scripts/verify_wire_v2_ping.sh
Lookin/Scripts/verify_ui_hierarchy_mcp.sh
LookinServer/Scripts/verify_lookin_integration.sh
```

Stock QMUI Lookin.app (NSSecureCoding Peertalk) **не поддерживается**.

## Swift-only module (legacy `@objc` cleanup)

- **Wire / files:** только Codable JSON (`Wire*`, `LKJ2`); публичный ObjC API pod **не поддерживается**.
- **Снимаем:** `@objc(Lookin*)` на моделях в `LookinServerShared` и transitional `.h` в `Src/Main` (см. план «уход от @objc и .h»).
- **Оставляем:** `@objcMembers` / `#selector` / `init(coder:)` в mac AppKit UI (`LookinClient/Base`, `Dashboard`, `Static`); runtime whitelist (`NSClassFromString("LookinConfig")`, exception bridge `.m`).
- **Gates:** `bash Lookin/Scripts/run_legacy_gates.sh` (`count_swift_objc.sh`, baseline `LookinServer/Scripts/objc_legacy_baseline.env`).

### Ожидаемые остатки `@objc` (после фаз A–F)

Инвентарь: `bash LookinServer/Scripts/count_swift_objc.sh`. Ноль `@objc` в репозитории **невозможен** без отказа от AppKit/Peertalk.

| Категория | Где (примеры) | Зачем | Снимать? |
|-----------|---------------|-------|----------|
| **G7 модели** | `LookinServerShared` | `@objc(Lookin*)` на wire-моделях | **Нет** (baseline = 0, gate) |
| **Peertalk** | `LookinServerPeertalk/LookinPT*.swift` | `@objc(Lookin_PTChannel)`, delegate | **Нет** |
| **Runtime probe** | `LKS_ConnectionManager` | `@objc(Lookin)` для `NSClassFromString("Lookin")` | **Нет** |
| **Runtime handlers** | `LKS_RequestHandler`, `LKS_*Maker`, `LKS_InvocationRuntimeHelper` | `@objc(LKS_*)` + динамические имена классов | **Нет** (Phase E) |
| **Blueprint / constraint** | `LookinDashboardBlueprint`, `LookinAutoLayoutConstraint` | Сгенерированные ObjC-селекторы; dashboard `@objc var` | **Нет** (генератор / AppKit) |
| **Shared helpers** | `NSObject+Lookin`, `Array+Lookin`, `String+Lookin` | `@objc` на extension-методах для runtime | Phase E |
| **File codec** | `LKWireCodec` | Swift `enum`, без `@objc` | **Снято** |
| **Mac AppKit UI** | `LookinClient/Base`, `Dashboard`, `Static` | `@objc(LK*)` + `@objcMembers`, `#selector` | **Нет** |
| **ShortCocoa / Connection** | `ShortCocoa+*.swift`, `LKConnection*.swift` | Layout / Peertalk wrappers | Phase E |

Топ файлов по `@objc(` (типично): Server — `LKS_CustomAttrSetterManager`, `LookinDashboardBlueprint`, `NSObject+Lookin`; Client — `ShortCocoa+Layout`, `LKPreviewView`, `LookinMsgAttribute`.

## Runtime whitelist (`NSClassFromString` / `perform`)

Намеренно оставляем только:

| Symbol | Где | Зачем |
|--------|-----|-------|
| `LookinConfig` | `LKS_ConfigManager` | Опциональный конфиг demo/host app |
| `LKS_MCPHTTPServer` / `LookinServer.MCPHTTPServer` | `LKS_ConnectionManager` | MCP HTTP на iOS (optional subspec) |
| `Lookin` | `LKS_ConnectionManager+Detect` | Probe linked LookinServer |
| Dynamic class names | `LKS_RequestHandler`, `LKS_AttrGroupsMaker`, `LKS_InvocationRuntimeHelper`, `LKS_TraceManager` | Fetch/invoke по имени класса из wire |

Peertalk (`Lookin_PTChannel`, delegates) — `@objc` на протоколе/delegate-методах; wire v2 не использует keyed archive.
