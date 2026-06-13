#if canImport(LookinShared)
import LookinShared
#endif
#if SHOULD_COMPILE_LOOKIN_SERVER

import Foundation

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
