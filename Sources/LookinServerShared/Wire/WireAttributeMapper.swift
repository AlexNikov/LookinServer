import CoreGraphics
import Foundation

#if canImport(UIKit)
import UIKit
#endif

public enum WireAttributeMapper {
    public static func wireGroup(from group: LookinAttributesGroup) -> WireAttributesGroup {
        WireAttributesGroup(
            identifier: group.identifier,
            userCustomTitle: group.userCustomTitle,
            attrSections: group.attrSections?.map { wireSection(from: $0) }
        )
    }

    public static func lookinGroup(from wire: WireAttributesGroup) -> LookinAttributesGroup {
        var group = LookinAttributesGroup()
        group.identifier = wire.identifier
        group.userCustomTitle = wire.userCustomTitle
        group.attrSections = wire.attrSections?.map { lookinSection(from: $0) }
        return group
    }

    public static func wireSection(from section: LookinAttributesSection) -> WireAttributesSection {
        WireAttributesSection(
            identifier: section.identifier,
            attributes: section.attributes?.map { wireAttribute(from: $0) }
        )
    }

    public static func lookinSection(from wire: WireAttributesSection) -> LookinAttributesSection {
        var section = LookinAttributesSection()
        section.identifier = wire.identifier
        section.attributes = wire.attributes?.map { lookinAttribute(from: $0) }
        return section
    }

    public static func wireAttribute(from attribute: LookinAttribute) -> WireAttribute {
        WireAttribute(
            identifier: attribute.identifier,
            displayTitle: attribute.displayTitle,
            attrType: attribute.attrType.rawValue,
            value: wireValue(from: attribute.value),
            extraValue: wireValue(from: attribute.extraValue),
            customSetterID: attribute.customSetterID
        )
    }

    public static func lookinAttribute(from wire: WireAttribute) -> LookinAttribute {
        let attrType = LookinAttrType(rawValue: wire.attrType) ?? .none
        let attribute = LookinAttribute()
        attribute.identifier = wire.identifier
        attribute.displayTitle = wire.displayTitle
        attribute.attrType = attrType
        attribute.value = lookinValue(from: wire.value, attrType: attrType)
        attribute.extraValue = lookinValue(from: wire.extraValue, attrType: attrType)
        attribute.customSetterID = wire.customSetterID
        return attribute
    }

    public static func wireValue(from attrValue: AttributeValue?) -> WireAttrValue? {
        guard let attrValue else { return nil }
        switch attrValue {
        case .bool(let v):
            return .bool(v)
        case .char(let v):
            return .number(Double(v))
        case .int(let v):
            return .number(Double(v))
        case .short(let v):
            return .number(Double(v))
        case .long(let v):
            return .number(Double(v))
        case .longLong(let v):
            return .number(Double(v))
        case .unsignedChar(let v):
            return .number(Double(v))
        case .unsignedInt(let v):
            return .number(Double(v))
        case .unsignedShort(let v):
            return .number(Double(v))
        case .unsignedLong(let v):
            return .number(Double(v))
        case .unsignedLongLong(let v):
            return .number(Double(v))
        case .float(let v):
            return .number(Double(v))
        case .double(let v):
            return .number(Double(v))
        case .selector(let v):
            return .string(NSStringFromSelector(v))
        case .classRef(let v):
            return .string(v.map { NSStringFromClass($0) } ?? "")
        case .string(let v):
            return .string(v)
        case .json(let v):
            return .json(v)
        case .color(let v):
            return .numbers(v)
        case .cgPoint(let v):
            return .point(Point(x: Double(v.x), y: Double(v.y)))
        case .cgVector(let v):
            return .vector(Vector(dx: Double(v.dx), dy: Double(v.dy)))
        case .cgSize(let v):
            return .size(Size(width: Double(v.width), height: Double(v.height)))
        case .cgRect(let v):
            return .rect(Rect(v))
        case .cgAffineTransform(let v):
            return .transform(AffineTransform(
                a: Double(v.a), b: Double(v.b), c: Double(v.c),
                d: Double(v.d), tx: Double(v.tx), ty: Double(v.ty)
            ))
        case .edgeInsets(let v):
            return .insets(EdgeInsets(
                top: Double(v.top), left: Double(v.left),
                bottom: Double(v.bottom), right: Double(v.right)
            ))
        case .offset(let h, let vert):
            return .offset(Offset(horizontal: Double(h), vertical: Double(vert)))
        case .shadow(let s):
            return .shadow(ShadowValue(
                offsetWidth: Double(s.offsetWidth),
                offsetHeight: Double(s.offsetHeight),
                opacity: Double(s.opacity),
                radius: Double(s.radius),
                colorRGBA: s.colorRGBA
            ))
        case .customObject(let v):
            return wireCustomObject(from: v)
        }
    }

    public static func lookinValue(from wire: WireAttrValue?, attrType: LookinAttrType) -> AttributeValue? {
        guard let wire, wire != .null else { return nil }

        switch wire {
        case .null:
            return nil
        case .bool(let value):
            return .bool(value)
        case .number(let value):
            switch attrType {
            case .char: return .char(Int8(value))
            case .int, .enumInt: return .int(Int32(value))
            case .short: return .short(Int16(value))
            case .long, .enumLong: return .long(Int(value))
            case .longLong: return .longLong(Int64(value))
            case .unsignedChar: return .unsignedChar(UInt8(value))
            case .unsignedInt: return .unsignedInt(UInt32(value))
            case .unsignedShort: return .unsignedShort(UInt16(value))
            case .unsignedLong: return .unsignedLong(UInt(value))
            case .unsignedLongLong: return .unsignedLongLong(UInt64(value))
            case .float: return .float(Float(value))
            case .double: return .double(value)
            default: return .double(value)
            }
        case .string(let value):
            switch attrType {
            case .sel: return .selector(NSSelectorFromString(value))
            case .class: return .classRef(NSClassFromString(value))
            case .json: return .json(value)
            default: return .string(value)
            }
        case .numbers(let numbers):
            return .color(numbers)
        case .strings(let strings):
            return .customObject(strings)
        case .stringGroups(let groups):
            return .customObject(groups)
        case .point(let point):
            return .cgPoint(CGPoint(x: point.x, y: point.y))
        case .vector(let vector):
            return .cgVector(CGVector(dx: vector.dx, dy: vector.dy))
        case .size(let size):
            return .cgSize(CGSize(width: size.width, height: size.height))
        case .rect(let rect):
            return .cgRect(rect.cgRect)
        case .transform(let t):
            return .cgAffineTransform(CGAffineTransform(a: t.a, b: t.b, c: t.c, d: t.d, tx: t.tx, ty: t.ty))
        case .insets(let insets):
            return .edgeInsets(LookinInsets(
                top: insets.top, left: insets.left,
                bottom: insets.bottom, right: insets.right
            ))
        case .offset(let offset):
            return .offset(CGFloat(offset.horizontal), CGFloat(offset.vertical))
        case .shadow(let shadow):
            return .shadow(ShadowComponents(
                offsetWidth: CGFloat(shadow.offsetWidth),
                offsetHeight: CGFloat(shadow.offsetHeight),
                opacity: Float(shadow.opacity),
                radius: CGFloat(shadow.radius),
                colorRGBA: shadow.colorRGBA
            ))
        case .json(let doc):
            return .json(doc)
        case .custom(let summary):
            return .string(summary)
        }
    }

    // MARK: - MCP HTTP JSON (same semantics as wire, no keyed archive)

    /// Attribute value → JSON-friendly object for MCP responses.
    public static func mcpJSONObject(from attrValue: AttributeValue?) -> Any {
        guard let wire = wireValue(from: attrValue) else { return NSNull() }
        return mcpJSONObject(from: wire)
    }

    public static func mcpJSONObject(from wire: WireAttrValue) -> Any {
        switch wire {
        case .null:
            return NSNull()
        case .bool(let v):
            return v
        case .number(let v):
            return v
        case .string(let v):
            return v
        case .numbers(let v):
            return v.map { NSNumber(value: $0) }
        case .strings(let v):
            return v
        case .stringGroups(let v):
            return v
        case .point(let p):
            return ["x": p.x, "y": p.y]
        case .vector(let v):
            return ["dx": v.dx, "dy": v.dy]
        case .size(let s):
            return ["width": s.width, "height": s.height]
        case .rect(let r):
            return ["x": r.x, "y": r.y, "width": r.width, "height": r.height]
        case .transform(let t):
            return ["a": t.a, "b": t.b, "c": t.c, "d": t.d, "tx": t.tx, "ty": t.ty]
        case .insets(let i):
            return ["top": i.top, "left": i.left, "bottom": i.bottom, "right": i.right]
        case .offset(let o):
            return ["horizontal": o.horizontal, "vertical": o.vertical]
        case .shadow(let s):
            var dict: [String: Any] = [
                "offsetWidth": s.offsetWidth,
                "offsetHeight": s.offsetHeight,
                "opacity": s.opacity,
                "radius": s.radius,
            ]
            if let rgba = s.colorRGBA, rgba.count >= 4 {
                dict["color"] = ["r": rgba[0], "g": rgba[1], "b": rgba[2], "a": rgba[3]]
            }
            return dict
        case .json(let doc):
            guard let data = doc.data(using: .utf8),
                  let parsed = try? JSONSerialization.jsonObject(with: data) else {
                return doc
            }
            return parsed
        case .custom(let s):
            return s
        }
    }

    /// MCP POST body `value` → in-memory attribute value.
    public static func lookinValue(fromMCPJSON json: Any?, attrType: LookinAttrType) -> AttributeValue? {
        guard let json, !(json is NSNull) else { return nil }

        switch attrType {
        case .BOOL:
            let v = (json as? NSNumber)?.boolValue ?? (json as? Bool) ?? false
            return .bool(v)
        case .float:
            if let number = json as? NSNumber { return .float(number.floatValue) }
            if let double = json as? Double { return .float(Float(double)) }
            if let int = json as? Int { return .float(Float(int)) }
            return nil
        case .double:
            if let number = json as? NSNumber { return .double(number.doubleValue) }
            if let double = json as? Double { return .double(double) }
            if let int = json as? Int { return .double(Double(int)) }
            return nil
        case .int, .enumInt:
            if let number = json as? NSNumber { return .int(number.int32Value) }
            if let int = json as? Int { return .int(Int32(int)) }
            return nil
        case .short:
            if let number = json as? NSNumber { return .short(number.int16Value) }
            return nil
        case .long, .enumLong:
            if let number = json as? NSNumber { return .long(number.intValue) }
            if let int = json as? Int { return .long(int) }
            return nil
        case .longLong:
            if let number = json as? NSNumber { return .longLong(number.int64Value) }
            return nil
        case .char:
            if let number = json as? NSNumber { return .char(number.int8Value) }
            return nil
        case .unsignedInt:
            if let number = json as? NSNumber { return .unsignedInt(number.uint32Value) }
            return nil
        case .unsignedShort:
            if let number = json as? NSNumber { return .unsignedShort(number.uint16Value) }
            return nil
        case .unsignedLong:
            if let number = json as? NSNumber { return .unsignedLong(number.uintValue) }
            return nil
        case .unsignedLongLong:
            if let number = json as? NSNumber { return .unsignedLongLong(number.uint64Value) }
            return nil
        case .unsignedChar:
            if let number = json as? NSNumber { return .unsignedChar(number.uint8Value) }
            return nil
        case .NSString, .sel, .class, .enumString:
            return .string((json as? String) ?? String(describing: json))
        case .json:
            if let string = json as? String { return .json(string) }
            guard JSONSerialization.isValidJSONObject(json),
                  let data = try? JSONSerialization.data(withJSONObject: json),
                  let text = String(data: data, encoding: .utf8) else {
                return .json(String(describing: json))
            }
            return .json(text)
        case .CGPoint:
            guard let dict = json as? [String: Any] else { return nil }
            return .cgPoint(CGPoint(x: dict["x"] as? CGFloat ?? 0, y: dict["y"] as? CGFloat ?? 0))
        case .CGSize:
            guard let dict = json as? [String: Any] else { return nil }
            return .cgSize(CGSize(width: dict["width"] as? CGFloat ?? 0, height: dict["height"] as? CGFloat ?? 0))
        case .CGRect:
            guard let dict = json as? [String: Any] else { return nil }
            return .cgRect(CGRect(
                x: dict["x"] as? CGFloat ?? 0, y: dict["y"] as? CGFloat ?? 0,
                width: dict["width"] as? CGFloat ?? 0, height: dict["height"] as? CGFloat ?? 0
            ))
        case .UIEdgeInsets:
            guard let dict = json as? [String: Any] else { return nil }
            return .edgeInsets(LookinInsets(
                top: dict["top"] as? CGFloat ?? 0, left: dict["left"] as? CGFloat ?? 0,
                bottom: dict["bottom"] as? CGFloat ?? 0, right: dict["right"] as? CGFloat ?? 0
            ))
        case .UIColor:
            if let components = json as? [NSNumber], components.count >= 4 {
                return .color(components.map(\.doubleValue))
            }
            if let dict = json as? [String: Any] {
                return .color([
                    (dict["r"] as? NSNumber)?.doubleValue ?? 0,
                    (dict["g"] as? NSNumber)?.doubleValue ?? 0,
                    (dict["b"] as? NSNumber)?.doubleValue ?? 0,
                    (dict["a"] as? NSNumber)?.doubleValue ?? 1,
                ])
            }
            return nil
        case .shadow:
            guard let dict = json as? [String: Any] else { return nil }
            var rgba: [Double]?
            if let color = dict["color"] as? [String: Any] {
                rgba = [
                    (color["r"] as? NSNumber)?.doubleValue ?? 0,
                    (color["g"] as? NSNumber)?.doubleValue ?? 0,
                    (color["b"] as? NSNumber)?.doubleValue ?? 0,
                    (color["a"] as? NSNumber)?.doubleValue ?? 1,
                ]
            }
            return .shadow(ShadowComponents(
                offsetWidth: dict["offsetWidth"] as? CGFloat ?? 0,
                offsetHeight: dict["offsetHeight"] as? CGFloat ?? 0,
                opacity: Float((dict["opacity"] as? NSNumber)?.floatValue ?? 0),
                radius: dict["radius"] as? CGFloat ?? 0,
                colorRGBA: rgba
            ))
        default:
            return lookinValue(from: mcpJSONToWire(json, attrType: attrType), attrType: attrType)
        }
    }

    private static func mcpJSONToWire(_ json: Any, attrType: LookinAttrType) -> WireAttrValue? {
        switch attrType {
        case .BOOL:
            let v = (json as? NSNumber)?.boolValue ?? (json as? Bool) ?? false
            return .bool(v)
        case .NSString, .sel, .class, .enumString:
            return .string((json as? String) ?? String(describing: json))
        default:
            if let number = json as? NSNumber { return .number(number.doubleValue) }
            if let double = json as? Double { return .number(double) }
            if let string = json as? String { return .string(string) }
            return nil
        }
    }

    private static func wireCustomObject(from any: Any?) -> WireAttrValue? {
        guard let any, !(any is NSNull) else { return nil }
        if let string = any as? String {
            return .string(string)
        }
        if let string = any as? NSString {
            return .string(string as String)
        }
        if let strings = any as? [String] {
            return .strings(strings)
        }
        if let strings = any as? [NSString] {
            return .strings(strings.map { $0 as String })
        }
        if let groups = any as? [[String]] {
            return .stringGroups(groups)
        }
        if let groups = any as? [[NSString]] {
            return .stringGroups(groups.map { $0.map { $0 as String } })
        }
        if let array = any as? [Any], let groups = stringGroups(from: array) {
            return .stringGroups(groups)
        }
        if let array = any as? [Any], let strings = stringList(from: array) {
            return .strings(strings)
        }
        return .custom(String(describing: any))
    }

    private static func stringList(from array: [Any]) -> [String]? {
        guard !array.isEmpty else { return nil }
        var strings: [String] = []
        strings.reserveCapacity(array.count)
        for element in array {
            if let string = element as? String {
                strings.append(string)
            } else if let string = element as? NSString {
                strings.append(string as String)
            } else {
                return nil
            }
        }
        return strings
    }

    private static func stringGroups(from array: [Any]) -> [[String]]? {
        guard !array.isEmpty else { return nil }
        var groups: [[String]] = []
        groups.reserveCapacity(array.count)
        for element in array {
            if let nested = element as? [String] {
                groups.append(nested)
            } else if let nested = element as? [NSString] {
                groups.append(nested.map { $0 as String })
            } else if let nested = element as? [Any], let strings = stringList(from: nested) {
                groups.append(strings)
            } else {
                return nil
            }
        }
        return groups
    }

}
