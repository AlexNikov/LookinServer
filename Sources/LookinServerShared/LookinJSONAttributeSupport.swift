import Foundation

/// Result of parsing a JSON custom attribute for the macOS dashboard tree UI.
public enum LookinJSONAttributeDashboardParseState {
    case empty
    case valid(rootRows: [[String: Any]])
    case invalid(message: String)
}

/// Parsing helpers for `LookinAttrType.json` (`WireAttrValue.json` and raw UTF-8 JSON string values).
public enum LookinJSONAttributeSupport {
    /// UTF-8 JSON text for transport / logging.
    public static func jsonDocumentString(from value: Any?) -> String? {
        guard let value, !(value is NSNull) else { return nil }
        if let string = value as? String { return string }
        if let string = value as? NSString { return string as String }
        if let data = value as? Data { return String(data: data, encoding: .utf8) }
        if JSONSerialization.isValidJSONObject(value),
           let data = try? JSONSerialization.data(withJSONObject: value),
           let text = String(data: data, encoding: .utf8) {
            return text
        }
        return nil
    }

    /// Parsed JSON object (dictionary, array, or scalar).
    public static func parsedJSONObject(from value: Any?) -> Any? {
        if let value, !(value is NSNull), JSONSerialization.isValidJSONObject(value) {
            return value
        }
        guard let doc = jsonDocumentString(from: value),
              let data = doc.data(using: .utf8) else {
            return nil
        }
        return try? JSONSerialization.jsonObject(with: data)
    }

    /// Classifies `attribute.value` for dashboard rendering (tree vs invalid JSON message).
    public static func dashboardParseState(from value: AttributeValue?) -> LookinJSONAttributeDashboardParseState {
        guard let value else { return .empty }
        return dashboardParseState(from: jsonSupportBridgeValue(from: value))
    }

    public static func dashboardParseState(from value: Any?) -> LookinJSONAttributeDashboardParseState {
        guard let value, !(value is NSNull) else { return .empty }

        if let rows = lookinTreeRootArray(from: value) {
            return .valid(rootRows: rows)
        }

        if jsonDocumentString(from: value) == nil {
            return .invalid(
                message: "Attribute value is not JSON text or a JSON object."
            )
        }

        if parsedJSONObject(from: value) == nil {
            return .invalid(message: "Malformed JSON — the document could not be parsed.")
        }

        return .invalid(
            message: "JSON must be an array of objects with \"title\", \"desc\", and \"details\" keys (Lookin custom attr schema)."
        )
    }

    public static func lookinTreeRootArray(from value: AttributeValue?) -> [[String: Any]]? {
        guard let value else { return nil }
        return lookinTreeRootArray(from: jsonSupportBridgeValue(from: value))
    }

    private static func jsonSupportBridgeValue(from value: AttributeValue) -> Any? {
        switch value {
        case .json(let doc): return doc
        case .string(let s): return s
        default: return nil
        }
    }

    /// Root array for the macOS JSON attribute tree (`title` / `desc` / `details` schema).
    public static func lookinTreeRootArray(from value: Any?) -> [[String: Any]]? {
        guard let parsed = parsedJSONObject(from: value) else { return nil }
        if let rows = parsed as? [[String: Any]] {
            return rows
        }
        if let rows = parsed as? [Any] {
            let dicts = rows.compactMap { $0 as? [String: Any] }
            if !dicts.isEmpty { return dicts }
            let flatDicts = rows.compactMap { $0 as? [Any] }
                .flatMap { $0 }
                .compactMap { $0 as? [String: Any] }
            return flatDicts.isEmpty ? nil : flatDicts
        }
        if let dict = parsed as? [String: Any] {
            return [dict]
        }
        return nil
    }
}
