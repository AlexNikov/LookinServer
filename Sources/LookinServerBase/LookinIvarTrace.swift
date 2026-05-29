import Foundation

public let lookinIvarTraceRelationValueSelf = "self"

@objc(LookinIvarTrace)
public class LookinIvarTrace: NSObject, NSCopying {
    @objc public var relation: String?
    @objc public var hostClassName: String?
    @objc public var ivarName: String?

    @objc public weak var hostObject: AnyObject?

    public override init() {
        super.init()
    }

    public override var hash: Int {
        (hostClassName?.hash ?? 0) ^ (ivarName?.hash ?? 0)
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? LookinIvarTrace else { return false }
        if self === other { return true }
        return hostClassName == other.hostClassName && ivarName == other.ivarName
    }

    // MARK: - NSCopying

    public func copy(with zone: NSZone? = nil) -> Any {
        let trace = LookinIvarTrace()
        trace.relation = relation
        trace.hostClassName = hostClassName
        trace.ivarName = ivarName
        return trace
    }

}
