#if SHOULD_COMPILE_LOOKIN_SERVER

import Foundation

#if canImport(LookinServerShared)
import LookinServerShared
#endif
#if canImport(LookinServerCoreSwift)
import LookinServerCoreSwift
#endif
#if canImport(LookinServerCategories)
import LookinServerCategories
#endif
#if canImport(LookinServerOthers)
import LookinServerOthers
#endif
#if canImport(LookinServerPeertalk)
import LookinServerPeertalk
#endif
public enum LKS_InbuiltAttrModificationHandler {

    public static func handleModification(
        _ modification: LookinAttributeModification?
    ) async throws -> LookinDisplayItemDetail {
        guard let modification else {
            throw LookinConnectionErrors.inner
        }
        return try await LKS_ConnectionRuntimeBridge.handleInbuiltAttrModification(modification)
    }
}

#endif
