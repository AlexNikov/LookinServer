import Foundation

/// New attribute types must be appended at the end to preserve wire compatibility.
public enum LookinAttrType: Int, CaseIterable {
    case none = 0
    case void = 1
    case char = 2
    case int = 3
    case short = 4
    case long = 5
    case longLong = 6
    case unsignedChar = 7
    case unsignedInt = 8
    case unsignedShort = 9
    case unsignedLong = 10
    case unsignedLongLong = 11
    case float = 12
    case double = 13
    case BOOL = 14
    case sel = 15
    case `class` = 16
    case CGPoint = 17
    case CGVector = 18
    case CGSize = 19
    case CGRect = 20
    case CGAffineTransform = 21
    case UIEdgeInsets = 22
    case UIOffset = 23
    case NSString = 24
    case enumInt = 25
    case enumLong = 26
    /// value is an RGBA array: @[NSNumber, NSNumber, NSNumber, NSNumber], each in 0...1
    case UIColor = 27
    /// business logic parses value according to the specific AttrIdentifier
    case customObj = 28
    case enumString = 29
    case shadow = 30
    case json = 31

    /// Human-readable type name for MCP / debugging output.
    public static func description(for rawValue: Int) -> String {
        guard let type = LookinAttrType(rawValue: rawValue) else {
            return "unknown"
        }
        return type.typeDescription
    }

    public var typeDescription: String {
        switch self {
        case .none, .void: return "void"
        case .char: return "char"
        case .int: return "int"
        case .short: return "short"
        case .long: return "NSInteger"
        case .longLong: return "long long"
        case .unsignedChar: return "unsigned char"
        case .unsignedInt: return "unsigned int"
        case .unsignedShort: return "unsigned short"
        case .unsignedLong: return "unsigned long"
        case .unsignedLongLong: return "unsigned long long"
        case .float: return "float"
        case .double: return "double"
        case .BOOL: return "BOOL"
        case .sel: return "SEL"
        case .class: return "Class"
        case .CGPoint: return "CGPoint"
        case .CGVector: return "CGVector"
        case .CGSize: return "CGSize"
        case .CGRect: return "CGRect"
        case .CGAffineTransform: return "CGAffineTransform"
        case .UIEdgeInsets: return "UIEdgeInsets"
        case .UIOffset: return "UIOffset"
        case .NSString: return "NSString"
        case .enumInt: return "enum(int)"
        case .enumLong: return "enum(long)"
        case .UIColor: return "UIColor"
        case .customObj: return "custom"
        case .enumString: return "enum(string)"
        case .shadow: return "shadow"
        case .json: return "json"
        }
    }
}

/// Backward-compatible alias for existing callers (e.g. tests, MCP helpers).
public enum LookinAttrTypeMapping {
    public static func description(for rawValue: Int) -> String {
        LookinAttrType.description(for: rawValue)
    }
}
