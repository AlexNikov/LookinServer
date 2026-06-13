#if canImport(LookinShared)
import LookinShared
#endif
#if SHOULD_COMPILE_LOOKIN_SERVER

import UIKit

extension UILabel {
    @objc var lks_fontSize: CGFloat {
        get { font.pointSize }
        set { font = font.withSize(newValue) }
    }

    @objc(lks_fontName)
    public func lks_fontName() -> String {
        font.fontName
    }
}

#endif
