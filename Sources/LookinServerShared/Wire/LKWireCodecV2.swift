import Foundation

public enum LKWireCodecV2 {
    private static let jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()

    private static let jsonDecoder = JSONDecoder()

    public static func encodeJSON<T: Encodable>(_ value: T) throws -> Data {
        try jsonEncoder.encode(value)
    }

    public static func decodeJSON<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        try jsonDecoder.decode(type, from: data)
    }

    /// `oid(4) | kind(1) | format(1) | reserved(2) | length(4) | reserved(4)` + bytes
    public static func makeScreenshotPayload(
        oid: UInt,
        kind: WireScreenshotKind,
        format: WireImageFormat,
        imageData: Data
    ) -> Data {
        var header = Data(count: LookinWireFormat.screenshotHeaderLength)
        var oid32 = UInt32(oid).littleEndian
        var length32 = UInt32(imageData.count).littleEndian
        withUnsafeBytes(of: &oid32) { header.replaceSubrange(0..<4, with: $0) }
        header[4] = kind.rawValue
        header[5] = format.rawValue
        withUnsafeBytes(of: &length32) { header.replaceSubrange(8..<12, with: $0) }
        var payload = header
        payload.append(imageData)
        return payload
    }

    public static func parseScreenshotPayload(_ data: Data) -> (oid: UInt, kind: WireScreenshotKind, format: WireImageFormat, imageData: Data)? {
        guard data.count >= LookinWireFormat.screenshotHeaderLength else { return nil }
        let oid = UInt(UInt32(littleEndian: data.withUnsafeBytes { $0.load(as: UInt32.self) }))
        guard let kind = WireScreenshotKind(rawValue: data[4]),
              let format = WireImageFormat(rawValue: data[5]) else { return nil }
        let length = Int(UInt32(littleEndian: data.withUnsafeBytes { ptr in
            ptr.load(fromByteOffset: 8, as: UInt32.self)
        }))
        let start = LookinWireFormat.screenshotHeaderLength
        guard length >= 0, start + length <= data.count else { return nil }
        let imageData = data.subdata(in: start..<(start + length))
        return (oid, kind, format, imageData)
    }
}
