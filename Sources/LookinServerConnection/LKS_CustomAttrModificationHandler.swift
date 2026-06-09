#if SHOULD_COMPILE_LOOKIN_SERVER

import Foundation
import UIKit

#if canImport(LookinServerShared)
import LookinServerShared
#endif
#if canImport(LookinServerCoreSwift)
import LookinServerCoreSwift
#endif
#if canImport(LookinServerCategories)
import LookinServerCategories
#endif
#if canImport(LookinServerOthers)
import LookinServerOthers
#endif
#if canImport(LookinServerPeertalk)
import LookinServerPeertalk
#endif
public final class LKS_CustomAttrModificationHandler: NSObject {

    public static func handleModification(_ modification: LookinCustomAttrModification?) -> Bool {
        guard let modification else { return false }
        guard let customSetterID = modification.customSetterID, !customSetterID.isEmpty else {
            return false
        }

        let manager = LKS_CustomAttrSetterManager.sharedInstance()

        switch modification.value {
        case .string(let v):
            guard let setter = manager.getStringSetter(withID: customSetterID) else { return false }
            setter(v)
            return true

        case .double(let v):
            guard let setter = manager.getNumberSetter(withID: customSetterID) else { return false }
            setter(NSNumber(value: v))
            return true

        case .float(let v):
            guard let setter = manager.getNumberSetter(withID: customSetterID) else { return false }
            setter(NSNumber(value: v))
            return true

        case .int(let v):
            guard let setter = manager.getNumberSetter(withID: customSetterID) else { return false }
            setter(NSNumber(value: v))
            return true

        case .long(let v):
            guard let setter = manager.getNumberSetter(withID: customSetterID) else { return false }
            setter(NSNumber(value: v))
            return true

        case .bool(let v):
            guard let setter = manager.getBoolSetter(withID: customSetterID) else { return false }
            setter(v)
            return true

        case .color(let rgba):
            guard let setter = manager.getColorSetter(withID: customSetterID) else { return false }
            setter(UIColor.lks_color(fromRGBAComponents: rgba.map { NSNumber(value: $0) }))
            return true

        case .cgRect(let v):
            guard let setter = manager.getRectSetter(withID: customSetterID) else { return false }
            setter(v)
            return true

        case .cgSize(let v):
            guard let setter = manager.getSizeSetter(withID: customSetterID) else { return false }
            setter(v)
            return true

        case .cgPoint(let v):
            guard let setter = manager.getPointSetter(withID: customSetterID) else { return false }
            setter(v)
            return true

        case .edgeInsets(let v):
            guard let setter = manager.getInsetsSetter(withID: customSetterID) else { return false }
            setter(v)
            return true

        case nil:
            if modification.attrType == .UIColor {
                guard let setter = manager.getColorSetter(withID: customSetterID) else { return false }
                setter(nil)
                return true
            }
            return false

        default:
            return false
        }
    }
}

#endif
