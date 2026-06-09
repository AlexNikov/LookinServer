import Foundation

public struct LookinConnectionResponseAttachment {
    public var dataType: LookinCodingValueType = .unknown
    public var data: Any?
    public var lookinServerVersion: Int32 = lookinServerVersionInt32
    public var error: NSError?
    public var appIsInBackground: Bool = false
    public var dataTotalCount: UInt = 0
    public var currentDataCount: UInt = 0

    public init() {}

    public static func attachment(with error: NSError?) -> LookinConnectionResponseAttachment {
        var attachment = LookinConnectionResponseAttachment()
        attachment.error = error
        return attachment
    }
}
