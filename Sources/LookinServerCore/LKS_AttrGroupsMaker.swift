#if canImport(LookinShared)
import LookinShared
#endif
#if SHOULD_COMPILE_LOOKIN_SERVER

import Foundation
import UIKit

public final class LKS_AttrGroupsMaker: NSObject {

    public static func attrGroups(for layer: CALayer?) -> [LKAttributesGroup]? {
        guard let layer else {
            assertionFailure()
            return nil
        }

        let groupIDs = LookinDashboardBlueprint.groupIDs()
        let groups: [LKAttributesGroup] = groupIDs.compactMap { groupID in
            var group = LKAttributesGroup()
            group.identifier = groupID

            let secIDs = LookinDashboardBlueprint.sectionIDs(forGroupID: groupID)
            let sections: [LKAttributesSection] = secIDs.compactMap { secID in
                var sec = LKAttributesSection()
                sec.identifier = secID

                let attrIDs = LookinDashboardBlueprint.attrIDs(forSectionID: secID)
                let attributes: [LKAttribute] = attrIDs.compactMap { attrID in
                    let minVersion = LookinDashboardBlueprint.minAvailableOSVersion(withAttrID: attrID)
                    if minVersion > 0,
                       ProcessInfo.processInfo.operatingSystemVersion.majorVersion < minVersion {
                        return nil
                    }

                    let targetObj: AnyObject?
                    if LookinDashboardBlueprint.isUIViewProperty(withAttrID: attrID) {
                        targetObj = layer.lks_hostView
                    } else {
                        targetObj = layer
                    }
                    guard let targetObj else { return nil }

                    if let className = LookinDashboardBlueprint.className(withAttrID: attrID),
                       let targetClass = NSClassFromString(className),
                       !targetObj.isKind(of: targetClass) {
                        return nil
                    }

                    return LKS_ObjCRuntimeBridge.attribute(withIdentifier: attrID, targetObject: targetObj)
                }

                guard !attributes.isEmpty else { return nil }
                sec.attributes = attributes
                return sec
            }

            if groupID == LookinSharedAttrID.groupAutoLayout {
                let hasConstraints = sections.contains { $0.identifier == LookinSharedAttrID.secAutoLayoutConstraints }
                if !hasConstraints { return nil }
            }

            guard !sections.isEmpty else { return nil }
            group.attrSections = sections
            return group
        }

        return groups
    }
}

#endif
