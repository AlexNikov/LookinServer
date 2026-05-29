# LookinMCPSample

Minimal UIKit app for LookinServer MCP smoke tests (label, button, colored view).

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

## Cursor MCP

Add to `~/.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "lookin": {
      "command": "npx",
      "args": ["-y", "lookin-mcp-ios"]
    }
  }
}
```

Run the app in Debug, then use tools: `lookin_get_hierarchy`, `lookin_get_attributes`, `lookin_get_screenshot`.
