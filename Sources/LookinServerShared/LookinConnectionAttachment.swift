import Foundation

public class LookinConnectionAttachment: NSObject {
    public var dataType: LookinCodingValueType = .unknown
    public var data: Any?

    public override init() {
        super.init()
    }
}
