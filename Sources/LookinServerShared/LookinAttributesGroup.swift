import Foundation

public struct LookinAttributesGroup: Hashable {
    public var userCustomTitle: String?
    public var identifier: String?
    public var attrSections: [LookinAttributesSection]?

    public init() {}

    public func uniqueKey() -> String? {
        identifier == LookinSharedAttrID.groupUserCustom ? userCustomTitle : identifier
    }

    public func isUserCustom() -> Bool {
        identifier == LookinSharedAttrID.groupUserCustom
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(uniqueKey())
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs.identifier == rhs.identifier else { return false }
        if lhs.identifier == LookinSharedAttrID.groupUserCustom {
            return lhs.userCustomTitle == rhs.userCustomTitle
        }
        return true
    }

    public func duplicated() -> LookinAttributesGroup {
        var copy = self
        copy.attrSections = attrSections?.map { $0.duplicated() }
        return copy
    }
}
