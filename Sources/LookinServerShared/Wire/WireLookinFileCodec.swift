import Foundation

public struct WireLookinDocumentPayload: Codable, Equatable {
    public var formatVersion: Int
    public var serverVersion: Int32
    public var hierarchy: WireHierarchyPayload
    public var soloScreenshots: [String: String]?
    public var groupScreenshots: [String: String]?

    public init(
        formatVersion: Int = WireLookinFileCodec.formatVersion,
        serverVersion: Int32,
        hierarchy: WireHierarchyPayload,
        soloScreenshots: [String: String]? = nil,
        groupScreenshots: [String: String]? = nil
    ) {
        self.formatVersion = formatVersion
        self.serverVersion = serverVersion
        self.hierarchy = hierarchy
        self.soloScreenshots = soloScreenshots
        self.groupScreenshots = groupScreenshots
    }
}

/// `.lookin` on disk: magic `LKJ2` + UTF-8 JSON (`WireLookinDocumentPayload`).
public enum WireLookinFileCodec {
    public static let magic = Data("LKJ2".utf8)
    public static let formatVersion = 2

    public static func isV2Format(_ data: Data) -> Bool {
        data.count >= magic.count && data.prefix(magic.count) == magic
    }

    public static func data(from file: LookinHierarchyFile) throws -> Data {
        guard let info = file.hierarchyInfo else {
            throw LKWireCodec.Error.unarchiveFailed
        }
        let payload = WireLookinDocumentPayload(
            serverVersion: file.serverVersion,
            hierarchy: WireHierarchyMapper.wirePayload(from: info),
            soloScreenshots: wireScreenshotMap(from: file.soloScreenshots),
            groupScreenshots: wireScreenshotMap(from: file.groupScreenshots)
        )
        var data = magic
        data.append(try LKWireCodecV2.encodeJSON(payload))
        return data
    }

    public static func lookinHierarchyFile(from data: Data) throws -> LookinHierarchyFile {
        guard isV2Format(data) else {
            throw LKWireCodec.Error.unarchiveFailed
        }
        let jsonData = Data(data.dropFirst(magic.count))
        let payload = try LKWireCodecV2.decodeJSON(WireLookinDocumentPayload.self, from: jsonData)
        var file = LookinHierarchyFile()
        file.serverVersion = payload.serverVersion
        file.hierarchyInfo = WireHierarchyMapper.lookinHierarchy(from: payload.hierarchy)
        file.soloScreenshots = lookinScreenshotMap(from: payload.soloScreenshots)
        file.groupScreenshots = lookinScreenshotMap(from: payload.groupScreenshots)
        return file
    }

    private static func wireScreenshotMap(from map: [NSNumber: Data]?) -> [String: String]? {
        guard let map, !map.isEmpty else { return nil }
        var result: [String: String] = [:]
        for (key, data) in map {
            result[String(key.uintValue)] = data.base64EncodedString()
        }
        return result
    }

    private static func lookinScreenshotMap(from map: [String: String]?) -> [NSNumber: Data]? {
        guard let map, !map.isEmpty else { return nil }
        var result: [NSNumber: Data] = [:]
        for (key, base64) in map {
            guard let oid = UInt(key), let data = Data(base64Encoded: base64) else { continue }
            result[NSNumber(value: oid)] = data
        }
        return result.isEmpty ? nil : result
    }
}
