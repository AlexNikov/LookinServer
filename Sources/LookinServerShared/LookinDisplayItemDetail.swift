import Foundation

public class LookinDisplayItemDetail: NSObject {
    public var displayItemOid: UInt = 0
    public var groupScreenshot: LookinImage?
    public var soloScreenshot: LookinImage?
    public var frameValue: NSValue?
    public var boundsValue: NSValue?
    public var hiddenValue: NSNumber?
    public var alphaValue: NSNumber?
    public var customDisplayTitle: String?
    public var danceUISource: String?
    public var attributesGroupList: [LookinAttributesGroup]?
    public var customAttrGroupList: [LookinAttributesGroup]?
    public var subitems: [LookinDisplayItem]?
    public var failureCode: Int = 0

    public override init() {
        super.init()
    }

}
