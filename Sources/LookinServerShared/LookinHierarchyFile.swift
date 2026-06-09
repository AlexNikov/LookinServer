import Foundation

public struct LookinHierarchyFile {
    public var serverVersion: Int32 = 0
    public var hierarchyInfo: LookinHierarchyInfo?
    public var soloScreenshots: [NSNumber: Data]?
    public var groupScreenshots: [NSNumber: Data]?

    public init() {}

    public static func verify(_ hierarchyFile: LookinHierarchyFile?) -> NSError? {
        guard let hierarchyFile else {
            return lookinInnerError()
        }

        if hierarchyFile.serverVersion < lookinSupportedServerMin {
            let fileVersion = hierarchyFile.serverVersion != 0 ? hierarchyFile.serverVersion : 6
            let detail = String(
                format: NSLocalizedString(
                    "The document was created by a Lookin app with too old version. Current Lookin app version is %@, but the document version is %@.",
                    comment: ""
                ),
                NSNumber(value: lookinClientVersion),
                NSNumber(value: fileVersion)
            )
            return NSError(
                domain: lookinErrorDomain,
                code: LookinSharedErrCode.serverVersionTooLow.rawValue,
                userInfo: [
                    NSLocalizedDescriptionKey: NSLocalizedString("Failed to open the document.", comment: ""),
                    NSLocalizedRecoverySuggestionErrorKey: detail,
                ]
            )
        }

        if hierarchyFile.serverVersion > lookinSupportedServerMax {
            let detail = String(
                format: NSLocalizedString(
                    "Current Lookin app is too old to open this document. Current Lookin app version is %@, but the document version is %@.",
                    comment: ""
                ),
                NSNumber(value: lookinClientVersion),
                NSNumber(value: hierarchyFile.serverVersion)
            )
            return NSError(
                domain: lookinErrorDomain,
                code: LookinSharedErrCode.serverVersionTooHigh.rawValue,
                userInfo: [
                    NSLocalizedDescriptionKey: NSLocalizedString("Failed to open the document.", comment: ""),
                    NSLocalizedRecoverySuggestionErrorKey: detail,
                ]
            )
        }

        return nil
    }
}
