import Foundation

public let lookinIvarTraceRelationValueSelf = "self"

public struct LookinIvarTrace: Hashable {
    public var relation: String?
    public var hostClassName: String?
    public var ivarName: String?

    public init() {}

    public func hash(into hasher: inout Hasher) {
        hasher.combine(hostClassName)
        hasher.combine(ivarName)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.hostClassName == rhs.hostClassName && lhs.ivarName == rhs.ivarName
    }
}
