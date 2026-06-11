#if SHOULD_COMPILE_LOOKIN_SERVER

import Foundation
#if canImport(LookinServerBase)
import LookinServerBase
#endif
#if canImport(LookinServerShared)
import LookinServerShared
#endif

extension NSObject {
    @objc(lks_registerOid)
    public func lks_registerOid() -> UInt {
        if lks_oid == 0 {
            let oid = LKS_ObjectRegistry.sharedInstance.addObject(self)
            lks_oid = oid
        }
        return lks_oid
    }

    @objc var lks_oid: UInt {
        get {
            let number = lookin_getBindObject(forKey: "lks_oid") as? NSNumber
            return number?.uintValue ?? 0
        }
        set {
            lookin_bindObject(NSNumber(value: newValue), forKey: "lks_oid")
        }
    }

    @objc(lks_objectWithOid:)
    public static func lks_object(withOid oid: UInt) -> NSObject? {
        LKS_ObjectRegistry.sharedInstance.objectWithOid(oid)
    }

    public var lks_ivarTraces: [LookinIvarTrace]? {
        get { lookin_getBindObject(forKey: "lks_ivarTraces") as? [LookinIvarTrace] }
        set {
            lookin_bindObject(newValue, forKey: "lks_ivarTraces")
            if newValue != nil {
                Self.allObjectsWithTraces().addPointer(Unmanaged.passUnretained(self).toOpaque())
            }
        }
    }

    @objc public var lks_specialTrace: String? {
        get { lookin_getBindObject(forKey: "lks_specialTrace") as? String }
        set {
            lookin_bindObject(newValue, forKey: "lks_specialTrace")
            if newValue != nil {
                Self.allObjectsWithTraces().addPointer(Unmanaged.passUnretained(self).toOpaque())
            }
        }
    }

    @objc(lks_clearAllObjectsTraces)
    public static func lks_clearAllObjectsTraces() {
        for case let obj as NSObject in allObjectsWithTraces().allObjects {
            obj.lks_ivarTraces = nil
            obj.lks_specialTrace = nil
        }
        allObjectsWithTraces().compact()
    }

    private static func allObjectsWithTraces() -> NSPointerArray {
        enum Storage {
            static let array: NSPointerArray = {
                NSPointerArray.weakObjects()
            }()
        }
        return Storage.array
    }

    @objc(lks_classChainList)
    public func lks_classChainList() -> [String] {
        var classChainList: [String] = []
        var currentClass: AnyClass? = type(of: self)
        while let cls = currentClass {
            classChainList.append(NSStringFromClass(cls))
            currentClass = class_getSuperclass(cls)
        }
        return classChainList
    }
}

#endif
