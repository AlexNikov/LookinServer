#if SHOULD_COMPILE_LOOKIN_SERVER

import Foundation

extension NSSet {
    @objc(lookin_map:)
    public func lookin_map(_ block: (Any) -> Any?) -> NSSet {
        let newSet = NSMutableSet(capacity: count)
        for obj in self {
            if let mapped = block(obj) {
                newSet.add(mapped)
            }
        }
        return newSet.copy() as! NSSet
    }

    @objc(lookin_firstFiltered:)
    public func lookin_firstFiltered(_ block: (Any) -> Bool) -> Any? {
        for obj in self {
            if block(obj) {
                return obj
            }
        }
        return nil
    }

    @objc(lookin_filter:)
    public func lookin_filter(_ block: (Any) -> Bool) -> NSSet {
        let result = NSMutableSet()
        for obj in self {
            if block(obj) {
                result.add(obj)
            }
        }
        return result.copy() as! NSSet
    }

    @objc(lookin_any:)
    public func lookin_any(_ block: (Any) -> Bool) -> Bool {
        for obj in self {
            if block(obj) {
                return true
            }
        }
        return false
    }
}

#endif
