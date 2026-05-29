#if SHOULD_COMPILE_LOOKIN_SERVER

import ObjectiveC
import UIKit

extension UIBlurEffect {
#if LOOKIN_SERVER_DISABLE_HOOK
    @objc var lks_effectStyleNumber: NSNumber? {
        get { nil }
        set { }
    }
#else
    @objc(lks_effectWithStyle:)
    public class func lks_effect(withStyle style: UIBlurEffect.Style) -> UIBlurEffect {
        let effect = lks_effect(withStyle: style)
        effect.lks_effectStyleNumber = NSNumber(value: style.rawValue)
        return effect
    }

    @objc var lks_effectStyleNumber: NSNumber? {
        get { lookin_getBindObject(forKey: "lks_effectStyleNumber") as? NSNumber }
        set { lookin_bindObject(newValue, forKey: "lks_effectStyleNumber") }
    }

#endif
}

#if !LOOKIN_SERVER_DISABLE_HOOK
private enum LookinUIBlurEffectSwizzleBootstrap {
    static let run: Void = {
        let original = class_getClassMethod(UIBlurEffect.self, Selector(("effectWithStyle:")))
        let swizzled = class_getClassMethod(UIBlurEffect.self, Selector(("lks_effectWithStyle:")))
        if let original, let swizzled {
            method_exchangeImplementations(original, swizzled)
        }
        return ()
    }()
}

private let _lookinUIBlurEffectBootstrap = LookinUIBlurEffectSwizzleBootstrap.run
#endif

#endif
