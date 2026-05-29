# LookinServerCoreSwift

Swift inspect makers (`LKS_*Maker`) that depend on ObjC UI categories in `LookinServerCore`.

SPM: one-way dependency `LookinServerCoreSwift` → `LookinServerCore` (no cycle).  
Core headers import `@LookinServerCoreSwift` when `LOOKIN_CORE_SWIFT_MAKERS` is set.
