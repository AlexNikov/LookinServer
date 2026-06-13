#if canImport(LookinShared)
import LookinShared
#endif
#if SHOULD_COMPILE_LOOKIN_SERVER

import Foundation

/// Host-app hooks `lookin_customDebugInfos` / `lookin_customDebugInfos_0` … `_5` (see demo README).
enum LKS_CustomDebugInfoSelectors {
    static let selectorNames: [String] = ["lookin_customDebugInfos"]
        + (0..<5).map { "lookin_customDebugInfos_\($0)" }
}

#endif
