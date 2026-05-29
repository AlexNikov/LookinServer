#if SHOULD_COMPILE_LOOKIN_SERVER

import ObjectiveC
import UIKit

extension UIImage {
#if LOOKIN_SERVER_DISABLE_HOOK
    @objc var lks_imageSourceName: String? {
        get { nil }
        set { }
    }
#else
    @objc(lks_imageNamed:inBundle:withConfiguration:)
    public class func lks_imageNamed(
        _ name: String,
        in bundle: Bundle?,
        with configuration: UIImage.Configuration?
    ) -> UIImage? {
        let image = lks_imageNamed(name, in: bundle, with: configuration)
        image?.lks_imageSourceName = name
        return image
    }

    @objc(lks_imageNamed:inBundle:compatibleWithTraitCollection:)
    public class func lks_imageNamed(
        _ name: String,
        in bundle: Bundle?,
        compatibleWith traitCollection: UITraitCollection?
    ) -> UIImage? {
        let image = lks_imageNamed(name, in: bundle, compatibleWith: traitCollection)
        image?.lks_imageSourceName = name
        return image
    }

    @objc(lks_imageNamed:)
    public class func lks_imageNamed(_ name: String) -> UIImage? {
        let image = lks_imageNamed(name)
        image?.lks_imageSourceName = name
        return image
    }

    @objc(lks_imageWithContentsOfFile:)
    public class func lks_imageWithContentsOfFile(_ path: String) -> UIImage? {
        let image = lks_imageWithContentsOfFile(path)
        let fileName = path.split(separator: "/").last?
            .split(separator: ".")
            .first
            .map(String.init)
        image?.lks_imageSourceName = fileName
        return image
    }

    @objc var lks_imageSourceName: String? {
        get { lookin_getBindObject(forKey: "lks_imageSourceName") as? String }
        set { lookin_bindObject(newValue?.copy() as? String, forKey: "lks_imageSourceName") }
    }

#endif

    @objc(lookin_data)
    public func lookin_data() -> Data? {
        pngData()
    }
}

#if !LOOKIN_SERVER_DISABLE_HOOK
private enum LookinUIImageSwizzleBootstrap {
    static let run: Void = {
        exchangeClassMethod(Selector(("imageNamed:")), Selector(("lks_imageNamed:")))
        exchangeClassMethod(Selector(("imageWithContentsOfFile:")), Selector(("lks_imageWithContentsOfFile:")))
        exchangeClassMethod(
            Selector(("imageNamed:inBundle:compatibleWithTraitCollection:")),
            Selector(("lks_imageNamed:inBundle:compatibleWithTraitCollection:"))
        )
        exchangeClassMethod(
            Selector(("imageNamed:inBundle:withConfiguration:")),
            Selector(("lks_imageNamed:inBundle:withConfiguration:"))
        )
        return ()
    }()

    private static func exchangeClassMethod(_ original: Selector, _ swizzled: Selector) {
        guard let originalMethod = class_getClassMethod(UIImage.self, original),
              let swizzledMethod = class_getClassMethod(UIImage.self, swizzled) else { return }
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}

private let _lookinUIImageBootstrap = LookinUIImageSwizzleBootstrap.run
#endif

#endif
