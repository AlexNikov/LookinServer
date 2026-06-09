#if SHOULD_COMPILE_LOOKIN_SERVER

import Foundation

public final class LKS_Helper: NSObject {

    private static let resourceBundle: Bundle = {
        #if SPM_RESOURCE_BUNDLE_IDENTIFITER
        if let bundle = Bundle(identifier: SPM_RESOURCE_BUNDLE_IDENTIFITER) {
            return bundle
        }
        #endif
        return Bundle(for: LKS_Helper.self)
    }()

    public static func description(of object: Any?) -> String {
        guard let object else { return "nil" }
        let className = NSStringFromClass(type(of: object as AnyObject))
        return "(\(className) *)"
    }

    public static func bundle() -> Bundle {
        resourceBundle
    }
}

public func lksLocalized(_ stringKey: String) -> String {
    NSLocalizedString(stringKey, tableName: nil, bundle: LKS_Helper.bundle(), comment: "")
}

#endif
