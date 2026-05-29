import Foundation

public class LookinConnectionResponseAttachment: LookinConnectionAttachment {
    public var lookinServerVersion: Int32 = lookinServerVersionInt32
    public var error: NSError?
    public var appIsInBackground: Bool = false
    public var dataTotalCount: UInt = 0
    public var currentDataCount: UInt = 0

    public override init() {
        super.init()
    }
    public class func attachment(with error: NSError?) -> LookinConnectionResponseAttachment {
        let attachment = LookinConnectionResponseAttachment()
        attachment.error = error
        return attachment
    }
}
