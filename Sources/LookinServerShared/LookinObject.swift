import Foundation

public class LookinObject: NSObject, NSCopying {
    public var oid: UInt = 0
    public var memoryAddress: String?
    public var classChainList: [String]?
    public var specialTrace: String?
    public var ivarTraces: [LookinIvarTrace]?

    public override init() {
        super.init()
    }

    public func rawClassName() -> String? {
        classChainList?.first
    }

    public func duplicate() -> LookinObject {
        let copy = LookinObject()
        copy.oid = oid
        copy.memoryAddress = memoryAddress
        copy.classChainList = classChainList
        copy.specialTrace = specialTrace
        copy.ivarTraces = ivarTraces
        return copy
    }

    // MARK: - NSCopying

    public func copy(with zone: NSZone? = nil) -> Any {
        duplicate()
    }

}
