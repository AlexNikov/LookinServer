# LookinCollectionLayoutDemo (Swift baseline)

Эталонное Swift-демо для сравнения иерархии UI: `UICollectionView` с compositional layout, ячейки на Auto Layout / frame / mixed, левая панель на frame layout.

Пары для verify:
- **Baseline (эталон):** `LookinServer-baseline+mcp` — этот проект, bundle `Lookin.LookinCollectionLayoutDemoBaseline`, display name **CollLayout Baseline**
- **Swift refactor:** `LookinServer/LookinDemo/LookinCollectionLayoutDemo` — bundle `Lookin.LookinCollectionLayoutDemo`, display name **CollLayout Swift**

## CocoaPods

```bash
cd LookinServer-baseline+mcp/LookinDemo/LookinCollectionLayoutDemo
pod install
open LookinCollectionLayoutDemo.xcworkspace
```

Подключает `LookinServer` (Swift + MCP) из `LookinServer/` через CocoaPods path `../../../LookinServer`.

## Сборка

```bash
xcodebuild -workspace LookinCollectionLayoutDemo.xcworkspace \
  -scheme LookinCollectionLayoutDemo \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -configuration Debug build
```

## Accessibility IDs (для MCP / verify)

| ID | Описание |
|----|----------|
| `collectionLayoutRoot` | корневой view |
| `leftRailFrameLayout` | левая панель (frame) |
| `mainCollectionView` | collection view |
| `cell_constraint_N` | Auto Layout ячейки |
| `cell_frame_N` | frame ячейки |
| `cell_mixed_N` | mixed ячейки |
| `section_header_N` | заголовки секций |
