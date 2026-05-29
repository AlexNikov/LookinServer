import Foundation

public enum LookinAttributesSectionStyle: Int {
    case `default` = 0
    case style0 = 1
    case style1 = 2
    case style2 = 3
}

public struct LookinAttributesSection {
    public var identifier: String?
    public var attributes: [LookinAttribute]?

    public init() {}

    public func isUserCustom() -> Bool {
        identifier == LookinSharedAttrID.secUserCustom
    }

    public func duplicated() -> LookinAttributesSection {
        var copy = self
        copy.attributes = attributes?.map { $0.duplicate() }
        return copy
    }
}
