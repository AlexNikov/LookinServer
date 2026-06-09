#if SHOULD_COMPILE_LOOKIN_SERVER

import Foundation
import UIKit

public final class LKS_AttrModificationPatchHandler: NSObject {

    public static func handleLayerOids(
        _ oids: [NSNumber],
        lowImageQuality: Bool,
        block: @escaping (LookinDisplayItemDetail?, UInt, Error?) -> Void
    ) {
        guard Optional(block) != nil else {
            assertionFailure()
            return
        }
        guard oids is NSArray else {
            block(nil, 1, LookinConnectionErrors.inner)
            return
        }

        for (idx, obj) in oids.enumerated() {
            let oid = obj.uintValue
            var detail = LookinDisplayItemDetail()
            detail.displayItemOid = oid

            guard let layer = NSObject.lks_object(withOid: oid) as? CALayer else {
                block(nil, UInt(idx + 1), LookinConnectionErrors.objectNotFound)
                return
            }

            if idx == 0 {
                detail.soloScreenshot = layer.lks_soloScreenshot(withLowQuality: lowImageQuality)
                detail.groupScreenshot = layer.lks_groupScreenshot(withLowQuality: lowImageQuality)
            } else {
                detail.groupScreenshot = layer.lks_groupScreenshot(withLowQuality: lowImageQuality)
            }
            block(detail, UInt(oids.count), nil)
        }
    }
}

#endif
