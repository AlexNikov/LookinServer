import Foundation

/// Wire protocol v3 — JSON metadata + binary screenshot blobs (Peertalk multiplex).
public enum LookinWireFormat {
    public static let version = 3

    public static func isSupportedWireVersion(_ version: Int) -> Bool {
        version == Self.version
    }

    @discardableResult
    public static func validateWireVersion(_ version: Int, context: String) -> Bool {
        guard isSupportedWireVersion(version) else {
            NSLog(
                "LookinWire - rejected %@: wireVersion=%d expected=%d",
                context,
                version,
                Self.version
            )
            return false
        }
        return true
    }

    /// JSON UTF-8 payload (`WireResponseEnvelope` or `WireCommand`).
    public static let frameTypeJSON: UInt32 = 0x4C4B4A53 // "LKJS"

    /// Binary screenshot: 16-byte header + PNG/JPEG bytes.
    public static let frameTypeScreenshot: UInt32 = 0x4C4B5047 // "LKPG"

    public static let screenshotHeaderLength = 16
}

public enum WireScreenshotKind: UInt8, Codable {
    case solo = 1
    case group = 2
}

public enum WireImageFormat: UInt8, Codable {
    case png = 1
    case jpeg = 2
}
