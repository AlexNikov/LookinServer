import Foundation

/// File-only codec for `.lookin` hierarchy exports (`LKJ2` + JSON via `WireLookinFileCodec`).
/// Peertalk live wire uses `LKWireCodecV2` (JSON `LKJS` + screenshot `LKPG`) — not this type.
public enum LKWireCodec {
    public enum Error: Swift.Error {
        case unarchiveFailed
    }

    /// `.lookin` v2 only (`LKJ2` + JSON). Legacy NSCoding documents are not supported.
    public static func loadHierarchyFile(from data: Data) throws -> LookinHierarchyFile {
        guard WireLookinFileCodec.isV2Format(data) else {
            throw NSError(
                domain: lookinErrorDomain,
                code: LookinSharedErrCode.unsupportedFileType.rawValue,
                userInfo: [
                    NSLocalizedDescriptionKey: NSLocalizedString("Failed to open the document.", comment: ""),
                    NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(
                        "This file uses an unsupported legacy format. Re-export the hierarchy from a current Lookin app.",
                        comment: ""
                    ),
                ]
            )
        }
        return try WireLookinFileCodec.lookinHierarchyFile(from: data)
    }

    /// Export `.lookin` v2 (JSON + magic).
    public static func archive(hierarchyFile: LookinHierarchyFile) throws -> Data {
        try WireLookinFileCodec.data(from: hierarchyFile)
    }
}
