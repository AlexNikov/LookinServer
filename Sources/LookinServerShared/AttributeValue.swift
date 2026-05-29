import CoreGraphics
import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Typed attribute value. Replaces (LookinAttrType, Any?).
public enum AttributeValue: Equatable {
    // Numeric primitives — exact C-types for IMP dispatch
    case char(Int8)
    case int(Int32)
    case short(Int16)
    case long(Int)
    case longLong(Int64)
    case unsignedChar(UInt8)
    case unsignedInt(UInt32)
    case unsignedShort(UInt16)
    case unsignedLong(UInt)
    case unsignedLongLong(UInt64)
    case float(Float)
    case double(Double)
    case bool(Bool)
    // ObjC reference types
    case selector(Selector)
    case classRef(AnyClass?)
    // Geometry
    case cgPoint(CGPoint)
    case cgVector(CGVector)
    case cgSize(CGSize)
    case cgRect(CGRect)
    case cgAffineTransform(CGAffineTransform)
    case edgeInsets(LookinInsets)
    case offset(CGFloat, CGFloat)
    // High-level types
    case string(String)
    case color([Double])
    case shadow(ShadowComponents)
    case json(String)
    case customObject(Any?)
}

public struct ShadowComponents: Equatable {
    public var offsetWidth: CGFloat
    public var offsetHeight: CGFloat
    public var opacity: Float
    public var radius: CGFloat
    public var colorRGBA: [Double]?

    public init(
        offsetWidth: CGFloat,
        offsetHeight: CGFloat,
        opacity: Float,
        radius: CGFloat,
        colorRGBA: [Double]? = nil
    ) {
        self.offsetWidth = offsetWidth
        self.offsetHeight = offsetHeight
        self.opacity = opacity
        self.radius = radius
        self.colorRGBA = colorRGBA
    }
}

extension AttributeValue {
    public static func == (lhs: AttributeValue, rhs: AttributeValue) -> Bool {
        switch (lhs, rhs) {
        case (.char(let a), .char(let b)): return a == b
        case (.int(let a), .int(let b)): return a == b
        case (.short(let a), .short(let b)): return a == b
        case (.long(let a), .long(let b)): return a == b
        case (.longLong(let a), .longLong(let b)): return a == b
        case (.unsignedChar(let a), .unsignedChar(let b)): return a == b
        case (.unsignedInt(let a), .unsignedInt(let b)): return a == b
        case (.unsignedShort(let a), .unsignedShort(let b)): return a == b
        case (.unsignedLong(let a), .unsignedLong(let b)): return a == b
        case (.unsignedLongLong(let a), .unsignedLongLong(let b)): return a == b
        case (.float(let a), .float(let b)): return a == b
        case (.double(let a), .double(let b)): return a == b
        case (.bool(let a), .bool(let b)): return a == b
        case (.selector(let a), .selector(let b)): return a == b
        case (.classRef(let a), .classRef(let b)): return a == b
        case (.cgPoint(let a), .cgPoint(let b)): return a == b
        case (.cgVector(let a), .cgVector(let b)): return a == b
        case (.cgSize(let a), .cgSize(let b)): return a == b
        case (.cgRect(let a), .cgRect(let b)): return a == b
        case (.cgAffineTransform(let a), .cgAffineTransform(let b)): return a == b
        case (.edgeInsets(let a), .edgeInsets(let b)):
            return a.top == b.top && a.left == b.left && a.bottom == b.bottom && a.right == b.right
        case (.offset(let a, let b), .offset(let c, let d)): return a == c && b == d
        case (.string(let a), .string(let b)): return a == b
        case (.color(let a), .color(let b)): return a == b
        case (.shadow(let a), .shadow(let b)): return a == b
        case (.json(let a), .json(let b)): return a == b
        case (.customObject(let a), .customObject(let b)):
            if let sa = a as? String, let sb = b as? String { return sa == sb }
            if let sa = a as? [String], let sb = b as? [String] { return sa == sb }
            if let sa = a as? [[String]], let sb = b as? [[String]] { return sa == sb }
            return (a == nil && b == nil) || String(describing: a) == String(describing: b)
        default:
            return false
        }
    }
}
