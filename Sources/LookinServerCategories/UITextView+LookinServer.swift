#if SHOULD_COMPILE_LOOKIN_SERVER

import UIKit

extension UITextView {
    @objc var lks_fontSize: CGFloat {
        get { font?.pointSize ?? 0 }
        set {
            guard let currentFont = font else { return }
            font = currentFont.withSize(newValue)
        }
    }

    @objc(lks_fontName)
    public func lks_fontName() -> String? {
        font?.fontName
    }
}

#endif
