import Foundation

/// Typed attribute getter keys (replaces scattered `getterString` literals in blueprint).
public enum LookinAttributeGetter: String, CaseIterable {
    case lks_relatedClassChainList
    case lks_accessibilityTraitsDescription
    case lks_selfRelation
    case lks_horizontalContentHuggingPriority
    case lks_verticalContentHuggingPriority
    case lks_horizontalContentCompressionResistancePriority
    case lks_verticalContentCompressionResistancePriority
    case lks_constraints
    case isHidden
    case opacity
    case isUserInteractionEnabled
    case masksToBounds
    case lks_backgroundColor
    case lks_borderColor
    case lks_shadowColor
    case lks_shadowOffsetWidth
    case lks_shadowOffsetHeight
    case lks_blurEffectStyleNumber
    case lks_imageSourceName
    case lks_imageViewOidIfHasImage
    case lks_fontSize
    case lks_fontName
    case isEnabled
    case isSelected
    case isScrollEnabled
    case isPagingEnabled
    case lks_numberOfRows
    case isEditable
    case isSelectable
    case isAccessibilityElement

    public var selector: Selector {
        NSSelectorFromString(rawValue)
    }
}
