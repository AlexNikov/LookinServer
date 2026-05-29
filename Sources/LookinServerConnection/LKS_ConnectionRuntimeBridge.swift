#if SHOULD_COMPILE_LOOKIN_SERVER

import Foundation
import UIKit

@objc(LKS_ConnectionRuntimeBridge)
public final class LKS_ConnectionRuntimeBridge: NSObject {

    private static let setHiddenSelector = NSSelectorFromString("setHidden:")
    private static let setOpacitySelector = NSSelectorFromString("setOpacity:")

    public static func handleInbuiltAttrModification(
        _ modification: LookinAttributeModification?,
        completion: @escaping (LookinDisplayItemDetail?, Error?) -> Void
    ) {
        guard let modification else {
            completion(nil, lookinInnerError())
            return
        }

        guard let receiver = NSObject.lks_object(withOid: modification.targetOid) else {
            LookinDiagLog.log(
                "inbuilt FAIL objNotFound targetOid=\(modification.targetOid) attr=\(modification.attrIdentifier ?? "?") sel=\(NSStringFromSelector(modification.setterSelector))"
            )
            completion(nil, lookinErrObjNotFound())
            return
        }

        let visibilityOnly = isVisibilityOnlyModification(modification)
        LookinDiagLog.log(
            "inbuilt recv oid=\(modification.targetOid) class=\(NSStringFromClass(type(of: receiver))) visibilityOnly=\(visibilityOnly) attr=\(modification.attrIdentifier ?? "?") sel=\(NSStringFromSelector(modification.setterSelector))"
        )

        // Never main.sync when hopping threads — Peertalk may already be on main; sync deadlocks (client timeout).
        // Run immediately when already on main so visibility replies are not stuck behind a backed-up main queue.
        let work: () -> Void = {
            if visibilityOnly {
                var invokeError: NSError?
                if let applyError = applyVisibilityModification(modification, to: receiver) as NSError? {
                    if applyError.code == LookinSharedErrCode.exception.rawValue {
                        invokeError = applyError
                    } else {
                        completion(nil, applyError)
                        return
                    }
                }
                if let detail = makeVisibilityDetail(for: modification, receiver: receiver) {
                    LookinDiagLog.log(
                        "inbuilt OK visibility detailOid=\(detail.displayItemOid) hidden=\(detail.hiddenValue?.boolValue ?? false)"
                    )
                    completion(detail, invokeError)
                } else {
                    LookinDiagLog.log("inbuilt FAIL visibility detail nil oid=\(modification.targetOid)")
                    completion(nil, lookinErrObjNotFound())
                }
                return
            }

            var invokeError: NSError?
            if let validationError = LKS_InvocationRuntimeHelper.applySetter(
                for: modification,
                receiver: receiver
            ) as NSError? {
                if validationError.code == LookinSharedErrCode.exception.rawValue {
                    invokeError = validationError
                } else {
                    completion(nil, validationError)
                    return
                }
            }

            guard let layer = layer(for: receiver) else {
                completion(nil, lookinErrObjNotFound())
                return
            }

            let detail = LookinDisplayItemDetail()
            detail.displayItemOid = Self.preferredDisplayItemOid(for: receiver, fallback: modification.targetOid)
            detail.frameValue = NSValue(cgRect: layer.frame)
            detail.boundsValue = NSValue(cgRect: layer.bounds)
            fillVisibilityFields(in: detail, layer: layer)

            detail.attributesGroupList = LKS_AttrGroupsMaker.attrGroups(for: layer) as? [LookinAttributesGroup]

            if let version = modification.clientReadableVersion,
               !version.isEmpty,
               version.lookin_numbericOSVersion() >= 10004 {
                let maker = LKS_CustomAttrGroupsMaker(layer: layer)
                maker.execute()
                detail.customAttrGroupList = maker.getGroups() as? [LookinAttributesGroup]
            }

            LookinDiagLog.log(
                "inbuilt OK full path detailOid=\(detail.displayItemOid) attrGroups=\(detail.attributesGroupList?.count ?? 0)"
            )
            completion(detail, invokeError)
        }
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async(execute: work)
        }
    }

    /// Hidden/Opacity: skip attr-group rebuild; assign properties directly (no invokeSetter — avoids UIView layout hangs).
    private static func isVisibilityOnlyModification(_ modification: LookinAttributeModification) -> Bool {
        if let attrID = modification.attrIdentifier {
            if attrID == LookinAttr_ViewLayer_Visibility_Hidden || attrID == LookinAttr_ViewLayer_Visibility_Opacity {
                return true
            }
        }
        let sel = NSStringFromSelector(modification.setterSelector)
        if sel.contains("setHidden") || sel.contains("setOpacity") {
            return true
        }
        if modification.setterSelector == setHiddenSelector || modification.setterSelector == setOpacitySelector {
            return true
        }
        if modification.attrType == .BOOL, modification.setterSelector == setHiddenSelector {
            return true
        }
        if modification.attrType == .float || modification.attrType == .double,
           modification.setterSelector == setOpacitySelector || sel == "setOpacity:" {
            return true
        }
        return false
    }

    /// Hierarchy / dashboard key items by `viewObject.oid` when a hosted UIView exists.
    private static func preferredDisplayItemOid(for receiver: NSObject, fallback: UInt) -> UInt {
        if let view = receiver as? UIView,
           let obj = LKS_ObjCRuntimeBridge.lookinObject(for: view) as? LKObject,
           obj.oid != 0 {
            return obj.oid
        }
        if let layer = receiver as? CALayer,
           let hostView = layer.lks_hostView,
           let obj = LKS_ObjCRuntimeBridge.lookinObject(for: hostView) as? LKObject,
           obj.oid != 0 {
            return obj.oid
        }
        return fallback
    }

    private static func layer(for receiver: NSObject) -> CALayer? {
        if let calayer = receiver as? CALayer { return calayer }
        if let view = receiver as? UIView { return view.layer }
        return nil
    }

    private static func fillVisibilityFields(in detail: LookinDisplayItemDetail, layer: CALayer) {
        if let hostView = layer.lks_hostView {
            detail.hiddenValue = NSNumber(value: hostView.isHidden)
            detail.alphaValue = NSNumber(value: hostView.alpha)
        } else {
            detail.hiddenValue = NSNumber(value: layer.isHidden)
            detail.alphaValue = NSNumber(value: layer.opacity)
        }
    }

    private static func makeVisibilityDetail(
        for modification: LookinAttributeModification,
        receiver: NSObject
    ) -> LookinDisplayItemDetail? {
        guard let layer = layer(for: receiver) else { return nil }
        let detail = LookinDisplayItemDetail()
        detail.displayItemOid = preferredDisplayItemOid(for: receiver, fallback: modification.targetOid)
        fillVisibilityFields(in: detail, layer: layer)
        return detail
    }

    private static func applyVisibilityModification(_ modification: LookinAttributeModification, to receiver: NSObject) -> NSError? {
        let sel = NSStringFromSelector(modification.setterSelector)
        if sel == "setHidden:" || modification.setterSelector == setHiddenSelector {
            guard case .bool(let hidden) = modification.value else { return lookinInnerError() }
            do {
                try LookinObjCExceptionBridge.tryExecute {
                    if let layer = receiver as? CALayer {
                        if let hostView = layer.lks_hostView {
                            hostView.isHidden = hidden
                        } else {
                            layer.isHidden = hidden
                        }
                    } else if let view = receiver as? UIView {
                        view.isHidden = hidden
                    }
                }
                return nil
            } catch {
                return lookinExceptionError(recoverySuggestion: (error as NSError).localizedDescription)
            }
        }
        if sel == "setOpacity:" || modification.setterSelector == setOpacitySelector {
            let opacity: Float
            switch modification.value {
            case .float(let v): opacity = v
            case .double(let v): opacity = Float(v)
            default: return lookinInnerError()
            }
            do {
                try LookinObjCExceptionBridge.tryExecute {
                    if let layer = receiver as? CALayer {
                        if let hostView = layer.lks_hostView {
                            hostView.alpha = CGFloat(opacity)
                        } else {
                            layer.opacity = opacity
                        }
                    } else if let view = receiver as? UIView {
                        view.alpha = CGFloat(opacity)
                    }
                }
                return nil
            } catch {
                return lookinExceptionError(recoverySuggestion: (error as NSError).localizedDescription)
            }
        }
        return lookinInnerError()
    }

    @objc(handlePatchWithTasks:block:)
    public static func handlePatch(with tasks: [LookinStaticAsyncUpdateTask], block: @escaping (LookinDisplayItemDetail) -> Void) {
        for task in tasks {
            let itemDetail = LookinDisplayItemDetail()
            itemDetail.displayItemOid = task.oid

            guard let object = NSObject.lks_object(withOid: task.oid) as? CALayer else {
                block(itemDetail)
                continue
            }

            switch task.taskType {
            case .soloScreenshot:
                itemDetail.soloScreenshot = object.lks_soloScreenshot(withLowQuality: false)
            case .groupScreenshot:
                itemDetail.groupScreenshot = object.lks_groupScreenshot(withLowQuality: false)
            default:
                break
            }
            block(itemDetail)
        }
    }

    @objc(methodNameListForClass:hasArg:)
    public static func methodNameList(for aClass: AnyClass, hasArg: Bool) -> [String] {
        let prefixesToVoid: Set<String> = [
            "_", "CA_", "cpl", "mf_", "vs_", "pep_", "isNS", "avkit_", "PG_", "px_", "pl_", "nsli_", "pu_", "pxg_",
        ]
        var array: [String] = []

        var currentClass: AnyClass? = aClass
        while currentClass != nil {
            guard let klass = currentClass else { break }
            let className = NSStringFromClass(klass)
            let isSystemClass = className.hasPrefix("UI") || className.hasPrefix("CA") || className.hasPrefix("NS")

            var methodCount: UInt32 = 0
            if let methods = class_copyMethodList(klass, &methodCount) {
                defer { free(methods) }
                for index in 0..<Int(methodCount) {
                    let selName = NSStringFromSelector(method_getName(methods[index]))
                    if !hasArg, selName.contains(":") { continue }

                    if isSystemClass {
                        let invalid = (prefixesToVoid as NSSet).lookin_any { prefix in
                            (prefix as? String).map { selName.hasPrefix($0) } ?? false
                        }
                        if invalid { continue }
                    }

                    if !selName.isEmpty, !array.contains(selName) {
                        array.append(selName)
                    }
                }
            }
            currentClass = class_getSuperclass(klass)
        }

        return (array as NSArray).lookin_sortedArrayByStringLength() as? [String] ?? array
    }

    @objc(handleInvokeWithObject:selector:resultDescription:resultObject:error:)
    public static func handleInvoke(
        with obj: NSObject,
        selector: Selector,
        resultDescription: AutoreleasingUnsafeMutablePointer<NSString?>?,
        resultObject: AutoreleasingUnsafeMutablePointer<LookinObject?>?,
        error: AutoreleasingUnsafeMutablePointer<NSError?>?
    ) {
        LKS_InvocationRuntimeHelper.handleInvoke(
            with: obj,
            selector: selector,
            resultDescription: resultDescription,
            resultObject: resultObject,
            error: error
        )
    }
}

#endif
