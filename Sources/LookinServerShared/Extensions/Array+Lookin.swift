import Foundation

extension Array {
    public func lookin_map<T>(_ transform: (UInt, Element) -> T?) -> [T] {
        var result: [T] = []
        result.reserveCapacity(count)
        for (index, element) in enumerated() {
            if let mapped = transform(UInt(index), element) {
                result.append(mapped)
            }
        }
        return result
    }

    public func lookin_filter(_ isIncluded: (Element) -> Bool) -> [Element] {
        filter(isIncluded)
    }

    func lookin_safeObject(at index: Int) -> Element? {
        guard index != NSNotFound, index >= 0, index < count else { return nil }
        return self[index]
    }
}

extension NSArray {
    @objc(lookin_map:)
    public func lookin_map(_ block: @escaping (UInt, Any) -> Any?) -> NSArray {
        var result: [Any] = []
        result.reserveCapacity(count)
        for idx in 0..<count {
            if let mapped = block(UInt(idx), self[idx]) {
                result.append(mapped)
            }
        }
        return result as NSArray
    }

    @objc(lookin_arrayWithCount:block:)
    public static func lookin_arrayWithCount(_ count: UInt, block: (UInt) -> Any?) -> NSArray {
        var array: [Any] = []
        array.reserveCapacity(Int(count))
        for idx in 0..<count {
            if let obj = block(idx) {
                array.append(obj)
            }
        }
        return array as NSArray
    }

    @objc(lookin_hasIndex:)
    public func lookin_hasIndex(_ index: Int) -> Bool {
        guard index != NSNotFound, index >= 0 else { return false }
        return count > index
    }

    @objc(lookin_filter:)
    public func lookin_filter(_ block: (Any) -> Bool) -> NSArray {
        var filtered: [Any] = []
        filtered.reserveCapacity(count)
        for idx in 0..<count {
            let obj = self[idx]
            if block(obj) { filtered.append(obj) }
        }
        return filtered as NSArray
    }

    @objc(lookin_firstFiltered:)
    public func lookin_firstFiltered(_ block: (Any) -> Bool) -> Any? {
        for obj in self {
            if block(obj) { return obj }
        }
        return nil
    }

    @objc(lookin_lastFiltered:)
    public func lookin_lastFiltered(_ block: (Any) -> Bool) -> Any? {
        for idx in stride(from: count - 1, through: 0, by: -1) {
            let obj = self[idx]
            if block(obj) { return obj }
        }
        return nil
    }

    @objc(lookin_any:)
    public func lookin_any(_ block: (Any) -> Bool) -> Bool {
        for obj in self {
            if block(obj) { return true }
        }
        return false
    }

    @objc(lookin_all:)
    public func lookin_all(_ block: (Any) -> Bool) -> Bool {
        for obj in self {
            if !block(obj) { return false }
        }
        return true
    }

    @objc(lookin_reduceInteger:initialAccumlator:)
    public func lookin_reduceInteger(
        _ block: (Int, UInt, Any) -> Int,
        initialAccumlator: Int
    ) -> Int {
        var accumulator = initialAccumlator
        for (idx, obj) in (self as [AnyObject]).enumerated() {
            accumulator = block(accumulator, UInt(idx), obj)
        }
        return accumulator
    }

    @objc(lookin_sortedArrayByStringLength)
    public func lookin_sortedArrayByStringLength() -> NSArray {
        let sorted = (self as [AnyObject]).sorted { lhs, rhs in
            let left = (lhs as? String)?.count ?? (lhs as? NSString)?.length ?? 0
            let right = (rhs as? String)?.count ?? (rhs as? NSString)?.length ?? 0
            if left == right { return false }
            return left < right
        }
        return sorted as NSArray
    }

    @objc(lookin_safeObjectAtIndex:)
    public func lookin_safeObject(at index: Int) -> Any? {
        guard index != NSNotFound, index >= 0, index < count else { return nil }
        return self[index]
    }
}

enum LookinCodingBridge {
    static func decodedObject(_ object: Any, type: LookinCodingValueType) -> Any? {
        (object as? NSObject)?.lookin_decodedObject(with: type)
    }
}
