#if SHOULD_COMPILE_LOOKIN_SERVER

import Foundation
import UIKit
#if canImport(LookinServerShared)
import LookinServerShared
#endif

#if canImport(LookinServerOthers)
import LookinServerOthers
#endif
@objc(LKS_ObjCRuntimeBridge)
public final class LKS_ObjCRuntimeBridge: NSObject {

    @objc(lookinObjectForObject:)
    public static func lookinObject(for object: NSObject) -> LKObject? {
        LookinObject.instance(with: object)
    }

    @objc(invokeNoArgMethodOnObject:selectorName:)
    public static func invokeNoArgMethod(on object: Any?, selectorName: String?) -> Any? {
        guard let object, let selectorName else { return nil }
        return LKS_InvocationRuntimeHelper.invokeNoArgMethod(on: object, selectorName: selectorName)
    }

    @objc(attributeWithIdentifier:targetObject:)
    public static func attribute(withIdentifier identifier: String, targetObject target: Any?) -> LKAttribute? {
        guard let target else {
            assertionFailure()
            return nil
        }
        return LKS_InvocationRuntimeHelper.attribute(withIdentifier: identifier, targetObject: target)
    }

    @objc(customAttributeFromRawDictionary:saveCustomSetter:groupTitle:)
    public static func customAttribute(
        fromRawDictionary dict: [AnyHashable: Any],
        saveCustomSetter: Bool,
        groupTitle inoutGroupTitle: AutoreleasingUnsafeMutablePointer<NSString?>?
    ) -> LKAttribute? {
        let attr = LKAttribute()
        attr.identifier = LookinAttr_UserCustom

        let title = dict["title"]
        let type = dict["valueType"]
        let section = dict["section"]
        let value = dict["value"]

        guard let title = title as? String else {
            NSLog("LookinServer - Wrong title")
            return nil
        }
        guard let type = type as? String else {
            NSLog("LookinServer - Wrong valueType")
            return nil
        }
        if let section = section as? String, !section.isEmpty {
            inoutGroupTitle?.pointee = section as NSString
        } else {
            inoutGroupTitle?.pointee = "Custom"
        }

        attr.displayTitle = title
        let fixedType = type.lowercased()

        if fixedType == "string" {
            if value != nil, !(value is String) {
                NSLog("LookinServer - Wrong value type.")
                return nil
            }
            attr.attrType = .NSString
            attr.value = (value as? String).map { .string($0) }

            if saveCustomSetter, let setter = dict["retainedSetter"] {
                let uniqueID = UUID().uuidString
                LKS_CustomAttrSetterManager.sharedInstance().saveSetter(setter, uniqueID: uniqueID)
                attr.customSetterID = uniqueID
            }
            return attr
        }

        if fixedType == "number" {
            guard let value else {
                NSLog("LookinServer - No value.")
                return nil
            }
            guard let number = value as? NSNumber else {
                NSLog("LookinServer - Wrong value type.")
                return nil
            }
            attr.attrType = .double
            attr.value = .double(number.doubleValue)

            if saveCustomSetter, let setter = dict["retainedSetter"] {
                let uniqueID = UUID().uuidString
                LKS_CustomAttrSetterManager.sharedInstance().saveSetter(setter, uniqueID: uniqueID)
                attr.customSetterID = uniqueID
            }
            return attr
        }

        if fixedType == "bool" {
            guard let value else {
                NSLog("LookinServer - No value.")
                return nil
            }
            guard value is NSNumber else {
                NSLog("LookinServer - Wrong value type.")
                return nil
            }
            attr.attrType = .BOOL
            attr.value = .bool((value as? NSNumber)?.boolValue ?? false)

            if saveCustomSetter, let setter = dict["retainedSetter"] {
                let uniqueID = UUID().uuidString
                LKS_CustomAttrSetterManager.sharedInstance().saveSetter(setter, uniqueID: uniqueID)
                attr.customSetterID = uniqueID
            }
            return attr
        }

        if fixedType == "color" {
            if value != nil, !(value is UIColor) {
                NSLog("LookinServer - Wrong value type.")
                return nil
            }
            attr.attrType = .UIColor
            attr.value = (value as? UIColor).map { .color($0.lks_rgbaComponents().map(\.doubleValue)) }

            if saveCustomSetter, let setter = dict["retainedSetter"] {
                let uniqueID = UUID().uuidString
                LKS_CustomAttrSetterManager.sharedInstance().saveSetter(setter, uniqueID: uniqueID)
                attr.customSetterID = uniqueID
            }
            return attr
        }

        if fixedType == "rect" {
            guard let value else {
                NSLog("LookinServer - No value.")
                return nil
            }
            guard value is NSValue else {
                NSLog("LookinServer - Wrong value type.")
                return nil
            }
            attr.attrType = .CGRect
            attr.value = .cgRect((value as? NSValue)?.cgRectValue ?? .zero)

            if saveCustomSetter, let setter = dict["retainedSetter"] {
                let uniqueID = UUID().uuidString
                LKS_CustomAttrSetterManager.sharedInstance().saveSetter(setter, uniqueID: uniqueID)
                attr.customSetterID = uniqueID
            }
            return attr
        }

        if fixedType == "size" {
            guard let value else {
                NSLog("LookinServer - No value.")
                return nil
            }
            guard value is NSValue else {
                NSLog("LookinServer - Wrong value type.")
                return nil
            }
            attr.attrType = .CGSize
            attr.value = .cgSize((value as? NSValue)?.cgSizeValue ?? .zero)

            if saveCustomSetter, let setter = dict["retainedSetter"] {
                let uniqueID = UUID().uuidString
                LKS_CustomAttrSetterManager.sharedInstance().saveSetter(setter, uniqueID: uniqueID)
                attr.customSetterID = uniqueID
            }
            return attr
        }

        if fixedType == "point" {
            guard let value else {
                NSLog("LookinServer - No value.")
                return nil
            }
            guard value is NSValue else {
                NSLog("LookinServer - Wrong value type.")
                return nil
            }
            attr.attrType = .CGPoint
            attr.value = .cgPoint((value as? NSValue)?.cgPointValue ?? .zero)

            if saveCustomSetter, let setter = dict["retainedSetter"] {
                let uniqueID = UUID().uuidString
                LKS_CustomAttrSetterManager.sharedInstance().saveSetter(setter, uniqueID: uniqueID)
                attr.customSetterID = uniqueID
            }
            return attr
        }

        if fixedType == "insets" {
            guard let value else {
                NSLog("LookinServer - No value.")
                return nil
            }
            guard value is NSValue else {
                NSLog("LookinServer - Wrong value type.")
                return nil
            }
            attr.attrType = .UIEdgeInsets
            attr.value = .edgeInsets((value as? NSValue)?.uiEdgeInsetsValue ?? .zero)

            if saveCustomSetter, let setter = dict["retainedSetter"] {
                let uniqueID = UUID().uuidString
                LKS_CustomAttrSetterManager.sharedInstance().saveSetter(setter, uniqueID: uniqueID)
                attr.customSetterID = uniqueID
            }
            return attr
        }

        if fixedType == "shadow" {
            guard let value else {
                NSLog("LookinServer - No value.")
                return nil
            }
            guard let shadowInfo = value as? [AnyHashable: Any] else {
                NSLog("LookinServer - Wrong value type.")
                return nil
            }
            guard shadowInfo["offset"] is NSValue else {
                NSLog("LookinServer - Wrong value. No offset.")
                return nil
            }
            guard shadowInfo["opacity"] is NSNumber else {
                NSLog("LookinServer - Wrong value. No opacity.")
                return nil
            }
            guard shadowInfo["radius"] is NSNumber else {
                NSLog("LookinServer - Wrong value. No radius.")
                return nil
            }

            var checkedShadowInfo: [AnyHashable: Any] = [
                "offset": shadowInfo["offset"] as Any,
                "opacity": shadowInfo["opacity"] as Any,
                "radius": shadowInfo["radius"] as Any,
            ]
            if let color = shadowInfo["color"] as? UIColor {
                checkedShadowInfo["color"] = color.lks_rgbaComponents()
            }

            attr.attrType = .shadow
            let offsetSize = (checkedShadowInfo["offset"] as? NSValue)?.cgSizeValue ?? .zero
            var rgba: [Double]?
            if let color = checkedShadowInfo["color"] as? [NSNumber] {
                rgba = color.map(\.doubleValue)
            }
            attr.value = .shadow(ShadowComponents(
                offsetWidth: offsetSize.width,
                offsetHeight: offsetSize.height,
                opacity: (checkedShadowInfo["opacity"] as? NSNumber)?.floatValue ?? 0,
                radius: CGFloat((checkedShadowInfo["radius"] as? NSNumber)?.doubleValue ?? 0),
                colorRGBA: rgba
            ))
            return attr
        }

        if fixedType == "enum" {
            guard let value else {
                NSLog("LookinServer - No value.")
                return nil
            }
            guard let enumValue = value as? String else {
                NSLog("LookinServer - Wrong value type.")
                return nil
            }
            attr.attrType = .enumString
            attr.value = .string(enumValue)

            if let allEnumCases = dict["allEnumCases"] as? [String] {
                attr.extraValue = .customObject(allEnumCases)
            }

            if saveCustomSetter, let setter = dict["retainedSetter"] {
                let uniqueID = UUID().uuidString
                LKS_CustomAttrSetterManager.sharedInstance().saveSetter(setter, uniqueID: uniqueID)
                attr.customSetterID = uniqueID
            }
            return attr
        }

        if fixedType == "json" {
            guard let jsonValue = value as? String else {
                NSLog("LookinServer - Wrong value type.")
                return nil
            }
            attr.attrType = .json
            attr.value = .json(jsonValue)
            return attr
        }

        NSLog("LookinServer - Unsupported value type.")
        return nil
    }
}

#endif
