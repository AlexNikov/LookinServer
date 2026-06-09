import Foundation

public final class LookinTwoTuple {
    public var first: Any?
    public var second: Any?

    public init() {}

    public var hash: Int {
        (lookinHash(first) ^ lookinHash(second))
    }

    public func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? LookinTwoTuple else { return false }
        if self === other { return true }
        return lookinEqual(first, other.first) && lookinEqual(second, other.second)
    }

    private func lookinHash(_ value: Any?) -> Int {
        if let obj = value as? NSObject { return obj.hash }
        if let value { return String(describing: value).hashValue }
        return 0
    }

    private func lookinEqual(_ lhs: Any?, _ rhs: Any?) -> Bool {
        if let lhsObj = lhs as? NSObject, let rhsObj = rhs as? NSObject {
            return lhsObj.isEqual(rhsObj)
        }
        if lhs == nil && rhs == nil { return true }
        if let lhs, let rhs { return String(describing: lhs) == String(describing: rhs) }
        return false
    }
}

public struct LookinStringTwoTuple: Hashable {
    public var first: String?
    public var second: String?

    public static func tuple(withFirst firstString: String?, second secondString: String?) -> LookinStringTwoTuple {
        LookinStringTwoTuple(first: firstString, second: secondString)
    }

    public init(first: String? = nil, second: String? = nil) {
        self.first = first
        self.second = second
    }
}
