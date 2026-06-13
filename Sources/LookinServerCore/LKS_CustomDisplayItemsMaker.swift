#if canImport(LookinShared)
import LookinShared
#endif
#if SHOULD_COMPILE_LOOKIN_SERVER

import Foundation
import UIKit

@objc(LKS_CustomDisplayItemsMaker)
public final class LKS_CustomDisplayItemsMaker: NSObject {
    private weak var layer: CALayer?
    private let saveAttrSetter: Bool
    private var allSubitems: [LKDisplayItem] = []

    @objc(initWithLayer:saveAttrSetter:)
    public init(layer: CALayer, saveAttrSetter: Bool) {
        self.layer = layer
        self.saveAttrSetter = saveAttrSetter
        super.init()
    }

    @objc public func make() -> [LKDisplayItem]? {
        guard let layer else {
            assertionFailure()
            return nil
        }

        for name in LKS_CustomDebugInfoSelectors.selectorNames {
            makeSubitems(for: layer, selectorName: name)
            if let view = layer.lks_hostView {
                makeSubitems(for: view, selectorName: name)
            }
        }

        return allSubitems.isEmpty ? nil : allSubitems
    }

    private func makeSubitems(for viewOrLayer: AnyObject, selectorName: String) {
        guard let rawData = LKS_ObjCRuntimeBridge.invokeNoArgMethod(on: viewOrLayer, selectorName: selectorName) as? [String: Any] else {
            return
        }
        makeSubitems(fromRawData: rawData)
    }

    private func makeSubitems(fromRawData data: [String: Any]) {
        guard let rawSubviews = data["subviews"] as? [[String: Any]] else { return }
        let newSubitems = displayItems(fromRawArray: rawSubviews)
        allSubitems.append(contentsOf: newSubitems)
    }

    private func displayItems(fromRawArray rawArray: [[String: Any]]) -> [LKDisplayItem] {
        rawArray.compactMap { displayItem(fromRawDict: $0) }
    }

    private func displayItem(fromRawDict dict: [String: Any]) -> LKDisplayItem? {
        guard let title = dict["title"] as? String else { return nil }

        let newItem = LKDisplayItem()
        if let subviews = dict["subviews"] as? [[String: Any]] {
            newItem.subitems = displayItems(fromRawArray: subviews)
        }
        newItem.isHidden = false
        newItem.alpha = 1

        var customInfo = LookinCustomDisplayItemInfo()
        customInfo.title = title
        customInfo.subtitle = dict["subtitle"] as? String
        if let frameValue = dict["frameInWindow"] as? NSValue {
            customInfo.frameInWindow = frameValue.cgRectValue
        } else if let rect = dict["frameInWindow"] as? CGRect {
            customInfo.frameInWindow = rect
        }
        customInfo.danceuiSource = dict["lookin_source"] as? String
        newItem.customInfo = customInfo

        if let properties = dict["properties"] as? [[String: Any]] {
            newItem.customAttrGroupList = LKS_CustomAttrGroupsMaker.makeGroups(fromRawProperties: properties, saveCustomSetter: saveAttrSetter)
        }

        return newItem
    }
}

#endif
