#if SHOULD_COMPILE_LOOKIN_SERVER

import Foundation
import UIKit

@objc(LKS_CustomAttrGroupsMaker)
public final class LKS_CustomAttrGroupsMaker: NSObject {
    private var sectionAndAttrs: [String: [LKAttribute]] = [:]
    private var resolvedCustomDisplayTitle: String?
    private var resolvedDanceUISource: String?
    private var resolvedGroups: [LKAttributesGroup]?
    private weak var layer: CALayer?

    @objc(initWithLayer:)
    public init(layer: CALayer) {
        self.layer = layer
        super.init()
    }

    @objc public func execute() {
        guard let layer else {
            assertionFailure()
            return
        }

        for name in LKS_CustomDebugInfoSelectors.selectorNames {
            makeAttrs(for: layer, selectorName: name)
            if let view = layer.lks_hostView {
                makeAttrs(for: view, selectorName: name)
            }
        }

        guard !sectionAndAttrs.isEmpty else { return }

        var groups: [LKAttributesGroup] = []
        for (groupTitle, attrs) in sectionAndAttrs {
            var group = LKAttributesGroup()
            group.userCustomTitle = groupTitle
            group.identifier = LookinSharedAttrID.groupUserCustom

            let sections = attrs.map { attr -> LKAttributesSection in
                var sec = LKAttributesSection()
                sec.identifier = LookinSharedAttrID.secUserCustom
                sec.attributes = [attr]
                return sec
            }
            group.attrSections = sections
            groups.append(group)
        }

        groups.sort { ($0.userCustomTitle ?? "") < ($1.userCustomTitle ?? "") }
        resolvedGroups = groups
    }

    private func makeAttrs(for viewOrLayer: AnyObject, selectorName: String) {
        guard let rawData = LKS_ObjCRuntimeBridge.invokeNoArgMethod(on: viewOrLayer, selectorName: selectorName) as? [String: Any] else {
            return
        }

        if let customTitle = rawData["title"] as? String, !customTitle.isEmpty {
            resolvedCustomDisplayTitle = customTitle
        }
        if let danceSource = rawData["lookin_source"] as? String, !danceSource.isEmpty {
            resolvedDanceUISource = danceSource
        }

        if let rawProperties = rawData["properties"] as? [[String: Any]] {
            makeAttrs(fromRawProperties: rawProperties)
        }
    }

    private func makeAttrs(fromRawProperties rawProperties: [[String: Any]]) {
        for dict in rawProperties {
            var groupTitle: NSString? = "Custom"
            guard let attr = LKS_ObjCRuntimeBridge.customAttribute(fromRawDictionary: dict, saveCustomSetter: true, groupTitle: &groupTitle) as! LKAttribute? else {
                continue
            }
            let key = (groupTitle as String?) ?? "Custom"
            sectionAndAttrs[key, default: []].append(attr)
        }
    }

    public func getGroups() -> [LKAttributesGroup]? { resolvedGroups }
    @objc public func getCustomDisplayTitle() -> String? { resolvedCustomDisplayTitle }
    @objc public func getDanceUISource() -> String? { resolvedDanceUISource }

    public static func makeGroups(fromRawProperties rawProperties: [[String: Any]]?, saveCustomSetter: Bool) -> [LKAttributesGroup]? {
        guard let rawProperties else { return nil }

        var groupTitleAndAttrs: [String: [LKAttribute]] = [:]
        for dict in rawProperties {
            var groupTitle: NSString? = "Custom"
            guard let attr = LKS_ObjCRuntimeBridge.customAttribute(fromRawDictionary: dict, saveCustomSetter: saveCustomSetter, groupTitle: &groupTitle) as! LKAttribute? else {
                continue
            }
            let key = (groupTitle as String?) ?? "Custom"
            groupTitleAndAttrs[key, default: []].append(attr)
        }

        guard !groupTitleAndAttrs.isEmpty else { return nil }

        var groups: [LKAttributesGroup] = []
        for (groupTitle, attrs) in groupTitleAndAttrs {
            var group = LKAttributesGroup()
            group.userCustomTitle = groupTitle
            group.identifier = LookinSharedAttrID.groupUserCustom

            let sections = attrs.map { attr -> LKAttributesSection in
                var sec = LKAttributesSection()
                sec.identifier = LookinSharedAttrID.secUserCustom
                sec.attributes = [attr]
                return sec
            }
            group.attrSections = sections
            groups.append(group)
        }

        groups.sort { ($0.userCustomTitle ?? "") < ($1.userCustomTitle ?? "") }
        return groups
    }
}

#endif
