#if SHOULD_COMPILE_LOOKIN_SERVER

import UIKit

extension UIVisualEffectView {
    @objc var lks_blurEffectStyleNumber: NSNumber? {
        get {
            guard let blurEffect = effect as? UIBlurEffect else { return nil }
            return blurEffect.lks_effectStyleNumber
        }
        set {
            guard let styleNumber = newValue else { return }
            let style = UIBlurEffect.Style(rawValue: styleNumber.intValue) ?? .regular
            effect = UIBlurEffect(style: style)
        }
    }
}

#endif
