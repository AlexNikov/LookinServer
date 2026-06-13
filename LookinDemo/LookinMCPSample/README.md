# LookinMCPSample

Minimal UIKit app for LookinServer MCP smoke tests (label, text field, button, colored view).

## SPM (local package)

Use `LookinMCPSample.xcodeproj` **without** CocoaPods:

```bash
cp LookinMCPSample.xcodeproj/project.spm.pbxproj LookinMCPSample.xcodeproj/project.pbxproj
xcodebuild -project LookinMCPSample.xcodeproj -scheme LookinMCPSample \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug build
```

## CocoaPods

Restore the Pods project file, then use the workspace:

```bash
cp LookinMCPSample.xcodeproj/project.pods.pbxproj LookinMCPSample.xcodeproj/project.pbxproj
pod install
open LookinMCPSample.xcworkspace
```

## Cursor / Qwen Code MCP

Full setup: [docs/CURSOR_MCP_SETUP.md](../../docs/CURSOR_MCP_SETUP.md).

**Lookin monorepo** — from repo root:

```bash
cd lookin-ios-mcp && npm install
```

- **Cursor:** enable `lookin-ios` in Settings → MCP (`LookinServer/.cursor/mcp.json` или monorepo `.cursor/mcp.json`)
- **Qwen Code:** `LookinServer/.qwen/settings.json` or `qwen mcp add lookin-ios node lookin-ios-mcp/index.mjs -s project`

Run the app in Debug on simulator, then use tools:

- `lookin_get_hierarchy`
- `lookin_get_attributes`
- `lookin_get_screenshot`
- `lookin_tap`
- `lookin_swipe`
- `lookin_type_text`
- `lookin_keyboard`
- `lookin_long_press`

Smoke without Cursor:

```bash
curl -sf http://127.0.0.1:47190/status
```
