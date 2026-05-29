import Foundation
#if canImport(UIKit)
import UIKit
#endif

#if os(iOS) || os(tvOS) || os(visionOS)

extension LookinObject {
    @objc(instanceWithObject:)
    public class func instance(with object: NSObject) -> LookinObject {
        let lookinObj = LookinObject()
        lookinObj.oid = object.lks_registerOid()
        lookinObj.memoryAddress = String(format: "%p", object)
        lookinObj.classChainList = object.lks_classChainList()
        lookinObj.specialTrace = object.lks_specialTrace
        lookinObj.ivarTraces = object.lks_ivarTraces
        return lookinObj
    }
}

#endif
