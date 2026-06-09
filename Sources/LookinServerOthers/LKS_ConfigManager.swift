#if SHOULD_COMPILE_LOOKIN_SERVER

import Foundation
import UIKit

public final class LKSConfigManager: NSObject {

    public static func collapsedClassList() -> [String]? {
        if let result = queryCollapsedClassList(with: NSObject.self, selectorName: "lookin_collapsedClassList") {
            return result
        }

        guard let configClass = NSClassFromString("LookinConfig") else {
            return nil
        }
        return queryCollapsedClassList(with: configClass, selectorName: "collapsedClasses")
    }

    private static func queryCollapsedClassList(with classType: AnyClass, selectorName: String) -> [String]? {
        let selector = NSSelectorFromString(selectorName)
        guard classType.responds(to: selector) else { return nil }
        guard let classList = (classType as AnyObject).perform(selector)?.takeUnretainedValue() as? [Any] else {
            return nil
        }
        return classList.lookin_filter { $0 is String }.compactMap { $0 as? String }
    }

    public static func colorAlias() -> NSDictionary? {
        if let result = queryColorAlias(with: NSObject.self, selectorName: "lookin_colorAlias") {
            return result
        }

        guard let configClass = NSClassFromString("LookinConfig") else {
            return nil
        }
        return queryColorAlias(with: configClass, selectorName: "colors")
    }

    private static func queryColorAlias(with classType: AnyClass, selectorName: String) -> NSDictionary? {
        let selector = NSSelectorFromString(selectorName)
        guard classType.responds(to: selector) else { return nil }
        guard let colorAlias = (classType as AnyObject).perform(selector)?.takeUnretainedValue() as? [AnyHashable: Any] else {
            return nil
        }

        let validDictionary = NSMutableDictionary()
        for (key, value) in colorAlias {
            guard let stringKey = key as? String else { continue }
            if value is UIColor {
                validDictionary[stringKey] = value
            } else if let subDict = value as? [AnyHashable: Any] {
                let isValidSubDict = subDict.allSatisfy { subKey, subValue in
                    subKey is String && subValue is UIColor
                }
                if isValidSubDict {
                    validDictionary[stringKey] = value
                }
            }
        }
        return validDictionary.count > 0 ? validDictionary : nil
    }

    public static func shouldCaptureScreenshot(of layer: CALayer?) -> Bool {
        guard let layer else { return true }
        if !shouldCaptureImage(of: layer) {
            return false
        }
        guard let view = layer.lks_hostView else { return true }
        return shouldCaptureImage(of: view)
    }

    private static func shouldCaptureImage(of layer: CALayer?) -> Bool {
        guard let layer else { return true }

        let classSelector = NSSelectorFromString("lookin_shouldCaptureImageOfLayer:")
        if NSObject.responds(to: classSelector),
           let number = (NSObject.self as AnyObject).perform(classSelector, with: layer)?.takeUnretainedValue() as? NSNumber,
           !number.boolValue {
            return false
        }

        let instanceSelector = NSSelectorFromString("lookin_shouldCaptureImage")
        if layer.responds(to: instanceSelector),
           let number = (layer as AnyObject).perform(instanceSelector)?.takeUnretainedValue() as? NSNumber,
           !number.boolValue {
            return false
        }

        return true
    }

    private static func shouldCaptureImage(of view: UIView?) -> Bool {
        guard let view else { return true }

        let classSelector = NSSelectorFromString("lookin_shouldCaptureImageOfView:")
        if NSObject.responds(to: classSelector),
           let number = (NSObject.self as AnyObject).perform(classSelector, with: view)?.takeUnretainedValue() as? NSNumber,
           !number.boolValue {
            return false
        }

        let instanceSelector = NSSelectorFromString("lookin_shouldCaptureImage")
        if view.responds(to: instanceSelector),
           let number = (view as AnyObject).perform(instanceSelector)?.takeUnretainedValue() as? NSNumber,
           !number.boolValue {
            return false
        }

        return true
    }
}

#endif
