import Foundation

public final class LookinWeakContainer {
    public weak var object: AnyObject?

    public static func container(with object: Any?) -> LookinWeakContainer {
        let container = LookinWeakContainer()
        container.object = object as AnyObject?
        return container
    }

    public init() {}

    public var hash: Int {
        object?.hash ?? 0
    }

    public func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? LookinWeakContainer else { return false }
        if self === other { return true }
        if let lhs = self.object, let rhs = other.object {
            return lhs.isEqual(rhs)
        }
        return self.object == nil && other.object == nil
    }
}
