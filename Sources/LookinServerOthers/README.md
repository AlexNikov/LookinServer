# LookinServerOthers

Reserved for a future Swift module for `LKS_Helper`, `LKS_MultiplatformAdapter`, and `LKS_CustomAttrSetterManager`.

Phase 6 kept these in **LookinServerCore** (ObjC) because their headers live under `Src/Main/Server/Others/` inside the Core clang module; a separate Swift pod caused duplicate `@objc` type definitions until headers are moved out of Core.

See `Sources/README.md` for the full migration matrix.
