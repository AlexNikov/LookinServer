#if canImport(LookinShared)
import LookinShared
#endif
#if SHOULD_COMPILE_LOOKIN_SERVER

import UIKit

extension UIImageView {
    @objc(lks_imageSourceName)
    public func lks_imageSourceName() -> String? {
        image?.lks_imageSourceName
    }

    @objc(lks_imageViewOidIfHasImage)
    public func lks_imageViewOidIfHasImage() -> NSNumber? {
        guard image != nil else { return nil }
        return NSNumber(value: lks_registerOid())
    }
}

#endif
