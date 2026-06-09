#if SHOULD_COMPILE_LOOKIN_SERVER

import Foundation
import ObjectiveC
import UIKit
#if canImport(LookinServerShared)
import LookinServerShared
#endif

@_silgen_name("LookinObjectGetIvarSELName")
private func lookinObjectGetIvarSELName(_ object: AnyObject, _ ivar: Ivar) -> UnsafePointer<CChar>?

@objc(LKS_GestureTargetActionsSearcher)
public final class LKS_GestureTargetActionsSearcher: NSObject {

    public static func getTargetActions(from recognizer: UIGestureRecognizer?) -> [LookinTwoTuple] {
        guard let recognizer else { return [] }

        var result: [LookinTwoTuple] = []
        let exception = LookinObjCExceptionBridge.catchException {
            guard let targetsList = recognizer.value(forKey: "_targets") as? [AnyObject],
                  !targetsList.isEmpty else {
                return
            }

            result = targetsList.lookin_map { _, targetBox in
                guard let targetObj = targetBox.value(forKey: "_target") else {
                    return nil
                }

                let actionString: String
                if let actionIvar = class_getInstanceVariable(object_getClass(targetBox), "_action"),
                   let actionNamePtr = lookinObjectGetIvarSELName(targetBox, actionIvar) {
                    let actionName = String(cString: actionNamePtr)
                    actionString = actionName.isEmpty ? "NULL" : actionName
                } else {
                    actionString = "NULL"
                }

                let tuple = LookinTwoTuple()
                tuple.first = LookinWeakContainer.container(with: targetObj)
                tuple.second = actionString as NSString
                return tuple
            }
        }

        if exception != nil {
            return []
        }
        return result
    }
}

#endif
