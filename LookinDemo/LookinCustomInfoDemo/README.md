# LookinCustomInfoDemo

## Запуск (обязательно workspace + Pods)

Не открывайте `LookinCustomInfoDemo.xcodeproj` напрямую — без Pods сборка/запуск ломается.

```bash
cd LookinServer/LookinDemo/LookinCustomInfoDemo
pod install
open LookinCustomInfoDemo.xcworkspace   # не .xcodeproj
```

Или одной командой:

```bash
bash LookinServer/LookinDemo/LookinCustomInfoDemo/run_demo.sh
```

Bundle id: `Lookin.LookinCustomInfoDemoSwift`

## Если Xcode ругается на Package.swift (SwiftPM)

Корень `LookinServer/` — это Swift Package для SPM, не iOS-приложение. После правок `Package.swift`:

```bash
cd LookinServer
rm -rf .build
swift package reset
swift package resolve
```

Демо через CocoaPods **не** требует успешного `swift build` на macOS.
