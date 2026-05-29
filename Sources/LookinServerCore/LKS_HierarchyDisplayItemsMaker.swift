#if SHOULD_COMPILE_LOOKIN_SERVER

import Foundation
import UIKit

private typealias LKMultiplatformAdapter = LKS_MultiplatformAdapter

@objc(LKS_HierarchyDisplayItemsMaker)
public final class LKS_HierarchyDisplayItemsMaker: NSObject {

    @objc(itemsWithScreenshots:attrList:lowImageQuality:readCustomInfo:saveCustomSetter:)
    public static func items(
        withScreenshots hasScreenshots: Bool,
        attrList hasAttrList: Bool,
        lowImageQuality lowQuality: Bool,
        readCustomInfo: Bool,
        saveCustomSetter: Bool
    ) -> [LKDisplayItem] {
        LKS_TraceManager.sharedInstance().reload()

        let windows = LKMultiplatformAdapter.allWindows() as? [UIWindow] ?? []
        var result: [LKDisplayItem] = []
        result.reserveCapacity(windows.count)

        for window in windows {
            guard let item = displayItem(
                with: window.layer,
                screenshots: hasScreenshots,
                attrList: hasAttrList,
                lowImageQuality: lowQuality,
                readCustomInfo: readCustomInfo,
                saveCustomSetter: saveCustomSetter
            ) else { continue }
            item.representedAsKeyWindow = window.isKeyWindow
            result.append(item)
        }
        return result
    }

    @objc(subitemsOfLayer:)
    public static func subitems(of layer: CALayer) -> [LKDisplayItem] {
        guard let sublayers = layer.sublayers, !sublayers.isEmpty else { return [] }

        LKS_TraceManager.sharedInstance().reload()

        var resultSubitems: [LKDisplayItem] = []
        for sublayer in sublayers {
            guard let sublayerItem = displayItem(
                with: sublayer,
                screenshots: false,
                attrList: false,
                lowImageQuality: false,
                readCustomInfo: true,
                saveCustomSetter: true
            ) else { continue }
            resultSubitems.append(sublayerItem)
        }

        let customMaker = LKS_CustomDisplayItemsMaker(layer: layer, saveAttrSetter: true)
        if let customSubitems = customMaker.make() {
            resultSubitems.append(contentsOf: customSubitems)
        }
        return resultSubitems
    }

    private static func displayItem(
        with layer: CALayer,
        screenshots hasScreenshots: Bool,
        attrList hasAttrList: Bool,
        lowImageQuality lowQuality: Bool,
        readCustomInfo: Bool,
        saveCustomSetter: Bool
    ) -> LKDisplayItem? {
        let item = LKDisplayItem()
        var layerFrame = layer.frame

        if let hostView = layer.lks_hostView, let superview = hostView.superview {
            layerFrame = superview.convert(layerFrame, to: nil)
        }

        if validateFrame(layerFrame) {
            item.frame = layer.frame
        } else {
            NSLog(
                "LookinServer - The layer frame(%@) seems really weird. Lookin will ignore it to avoid potential render error in Lookin.",
                NSCoder.string(for: layer.frame)
            )
            item.frame = .zero
        }
        item.bounds = layer.bounds

        if hasScreenshots {
            item.soloScreenshot = layer.lks_soloScreenshot(withLowQuality: lowQuality)
            item.groupScreenshot = layer.lks_groupScreenshot(withLowQuality: lowQuality)
            item.screenshotEncodeType = LookinDisplayItemImageEncodeType.nsData
        }

        if hasAttrList {
            item.attributesGroupList = LKS_AttrGroupsMaker.attrGroups(for: layer)
            let maker = LKS_CustomAttrGroupsMaker(layer: layer)
            maker.execute()
            item.customAttrGroupList = maker.getGroups()
            item.customDisplayTitle = maker.getCustomDisplayTitle()
            item.danceuiSource = maker.getDanceUISource()
        } else if readCustomInfo {
            item.customDisplayTitle = customDisplayTitle(for: layer)
        }

        item.layerObject = LKS_ObjCRuntimeBridge.lookinObject(for: layer) as! LKObject
        item.shouldCaptureImage = LKSConfigManager.shouldCaptureScreenshot(of: layer)

        if let view = layer.lks_hostView {
            item.isHidden = view.isHidden
            item.alpha = Float(view.alpha)
            item.viewObject = LKS_ObjCRuntimeBridge.lookinObject(for: view) as! LKObject
            item.eventHandlers = LKS_EventHandlerMaker.make(for: view)
            item.backgroundColor = view.backgroundColor
                ?? UIColor.lks_colorWithCGColor(view.layer.backgroundColor)
            if let viewController = view.lks_findHostViewController() {
                item.hostViewControllerObject = LKS_ObjCRuntimeBridge.lookinObject(for: viewController) as! LKObject
            }
        } else {
            item.isHidden = layer.isHidden
            item.alpha = Float(layer.opacity)
            item.backgroundColor = UIColor.lks_colorWithCGColor(layer.backgroundColor)
        }

        if let sublayers = layer.sublayers, !sublayers.isEmpty {
            var allSubitems: [LKDisplayItem] = []
            allSubitems.reserveCapacity(sublayers.count)
            for sublayer in sublayers {
                guard let sublayerItem = displayItem(
                    with: sublayer,
                    screenshots: hasScreenshots,
                    attrList: hasAttrList,
                    lowImageQuality: lowQuality,
                    readCustomInfo: readCustomInfo,
                    saveCustomSetter: saveCustomSetter
                ) else { continue }
                allSubitems.append(sublayerItem)
            }
            item.subitems = allSubitems
        }

        if readCustomInfo {
            let customMaker = LKS_CustomDisplayItemsMaker(layer: layer, saveAttrSetter: saveCustomSetter)
            if let customSubitems = customMaker.make(), !customSubitems.isEmpty {
                if let existing = item.subitems {
                    item.subitems = existing + customSubitems
                } else {
                    item.subitems = customSubitems
                }
            }
        }

        return item
    }

    private static func validateFrame(_ frame: CGRect) -> Bool {
        !frame.isNull && !frame.isInfinite && !cgRectIsNaN(frame) && !cgRectIsInf(frame) && !cgRectIsUnreasonable(frame)
    }

    private static func customDisplayTitle(for layer: CALayer) -> String? {
        for name in LKS_CustomDebugInfoSelectors.selectorNames {
            if let title = customDisplayTitle(from: layer, selectorName: name) {
                return title
            }
            if let view = layer.lks_hostView,
               let title = customDisplayTitle(from: view, selectorName: name) {
                return title
            }
        }
        return nil
    }

    private static func customDisplayTitle(from object: AnyObject, selectorName: String) -> String? {
        guard let rawData = LKS_ObjCRuntimeBridge.invokeNoArgMethod(on: object, selectorName: selectorName) as? [String: Any],
              let title = rawData["title"] as? String,
              !title.isEmpty else {
            return nil
        }
        return title
    }

    private static func cgRectIsNaN(_ rect: CGRect) -> Bool {
        rect.origin.x.isNaN || rect.origin.y.isNaN || rect.size.width.isNaN || rect.size.height.isNaN
    }

    private static func cgRectIsInf(_ rect: CGRect) -> Bool {
        rect.origin.x.isInfinite || rect.origin.y.isInfinite || rect.size.width.isInfinite || rect.size.height.isInfinite
    }

    private static func cgRectIsUnreasonable(_ rect: CGRect) -> Bool {
        abs(rect.origin.x) > 100_000
            || abs(rect.origin.y) > 100_000
            || rect.size.width < 0
            || rect.size.height < 0
            || rect.size.width > 100_000
            || rect.size.height > 100_000
    }
}

#endif
