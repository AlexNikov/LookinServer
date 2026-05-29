import Foundation

public class LookinAttribute: NSObject {
    public var identifier: String?
    public var displayTitle: String?
    public var attrType: LookinAttrType = .none
    public var value: AttributeValue?
    public var extraValue: AttributeValue?
    public var customSetterID: String?

    /// Not encoded. Set by the owning display item.
    public weak var targetDisplayItem: LookinDisplayItem?

    public override init() {
        super.init()
    }

    public func isUserCustom() -> Bool {
        identifier == LookinSharedAttrID.attrUserCustom
    }

    public func duplicate() -> LookinAttribute {
        let copy = LookinAttribute()
        copy.identifier = identifier
        copy.displayTitle = displayTitle
        copy.value = value
        copy.attrType = attrType
        copy.extraValue = extraValue
        copy.customSetterID = customSetterID
        return copy
    }
}
