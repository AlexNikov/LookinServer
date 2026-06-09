#if SHOULD_COMPILE_LOOKIN_SERVER

import Foundation

public final class LKS_InbuiltAttrModificationHandler: NSObject {

    public static func handleModification(
        _ modification: LookinAttributeModification?,
        completion: @escaping (LookinDisplayItemDetail?, Error?) -> Void
    ) {
        guard let modification else {
            completion(nil, LookinConnectionErrors.inner)
            return
        }
        Task { @MainActor in
            LKS_ConnectionRuntimeBridge.handleInbuiltAttrModification(modification, completion: completion)
        }
    }

    public static func handlePatchWithTasks(
        _ tasks: [LookinStaticAsyncUpdateTask],
        block: @escaping (LookinDisplayItemDetail) -> Void
    ) {
        Task { @MainActor in
            LKS_ConnectionRuntimeBridge.handlePatch(with: tasks, block: block)
        }
    }
}

#endif
