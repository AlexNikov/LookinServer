// Generated from LookinDashboardBlueprint.m — do not edit by hand.
import Foundation
#if canImport(LookinServerShared)
import LookinServerShared
#endif

@objc(LookinDashboardBlueprint)
public final class LookinDashboardBlueprint: NSObject {

    private struct AttrInfo {
        var className: String?
        var fullTitle: String?
        var briefTitle: String?
        var getter: LookinAttributeGetter?
        var setterString: String?
        var typeIfObj: LookinAttrType?
        var enumList: String?
        var patch: Bool?
        var hideIfNil: Bool?
        var osVersion: Int?
    }

    private static let allGroupIDs: [LookinAttrGroupIdentifier] = [
        LookinAttrGroup_Class,
        LookinAttrGroup_Accessibility,
        LookinAttrGroup_Relation,
        LookinAttrGroup_Layout,
        LookinAttrGroup_AutoLayout,
        LookinAttrGroup_ViewLayer,
        LookinAttrGroup_UIStackView,
        LookinAttrGroup_UIVisualEffectView,
        LookinAttrGroup_UIImageView,
        LookinAttrGroup_UILabel,
        LookinAttrGroup_UIControl,
        LookinAttrGroup_UIButton,
        LookinAttrGroup_UIScrollView,
        LookinAttrGroup_UITableView,
        LookinAttrGroup_UITextView,
        LookinAttrGroup_UITextField,
    ]

    private static let sectionsByGroup: [LookinAttrGroupIdentifier: [LookinAttrSectionIdentifier]] = [
        LookinAttrGroup_Class: [LookinAttrSec_Class_Class],
        LookinAttrGroup_Accessibility: [
            LookinAttrSec_Accessibility_Identifier,
            LookinAttrSec_Accessibility_Label,
            LookinAttrSec_Accessibility_Value,
            LookinAttrSec_Accessibility_Hint,
            LookinAttrSec_Accessibility_Flags,
            LookinAttrSec_Accessibility_Traits,
        ],
        LookinAttrGroup_Relation: [LookinAttrSec_Relation_Relation],
        LookinAttrGroup_Layout: [LookinAttrSec_Layout_Frame, LookinAttrSec_Layout_Bounds, LookinAttrSec_Layout_SafeArea, LookinAttrSec_Layout_Position, LookinAttrSec_Layout_AnchorPoint],
        LookinAttrGroup_AutoLayout: [LookinAttrSec_AutoLayout_Constraints, LookinAttrSec_AutoLayout_IntrinsicSize, LookinAttrSec_AutoLayout_Hugging, LookinAttrSec_AutoLayout_Resistance],
        LookinAttrGroup_ViewLayer: [LookinAttrSec_ViewLayer_Visibility, LookinAttrSec_ViewLayer_InterationAndMasks, LookinAttrSec_ViewLayer_BgColor, LookinAttrSec_ViewLayer_Border, LookinAttrSec_ViewLayer_Corner, LookinAttrSec_ViewLayer_Shadow, LookinAttrSec_ViewLayer_ContentMode, LookinAttrSec_ViewLayer_TintColor, LookinAttrSec_ViewLayer_Tag],
        LookinAttrGroup_UIStackView: [LookinAttrSec_UIStackView_Axis, LookinAttrSec_UIStackView_Distribution, LookinAttrSec_UIStackView_Alignment, LookinAttrSec_UIStackView_Spacing],
        LookinAttrGroup_UIVisualEffectView: [LookinAttrSec_UIVisualEffectView_Style, LookinAttrSec_UIVisualEffectView_QMUIForegroundColor],
        LookinAttrGroup_UIImageView: [LookinAttrSec_UIImageView_Name, LookinAttrSec_UIImageView_Open],
        LookinAttrGroup_UILabel: [LookinAttrSec_UILabel_Text, LookinAttrSec_UILabel_Font, LookinAttrSec_UILabel_NumberOfLines, LookinAttrSec_UILabel_TextColor, LookinAttrSec_UILabel_BreakMode, LookinAttrSec_UILabel_Alignment, LookinAttrSec_UILabel_CanAdjustFont],
        LookinAttrGroup_UIControl: [LookinAttrSec_UIControl_EnabledSelected, LookinAttrSec_UIControl_QMUIOutsideEdge, LookinAttrSec_UIControl_VerAlignment, LookinAttrSec_UIControl_HorAlignment],
        LookinAttrGroup_UIButton: [LookinAttrSec_UIButton_ContentInsets, LookinAttrSec_UIButton_TitleInsets, LookinAttrSec_UIButton_ImageInsets],
        LookinAttrGroup_UIScrollView: [LookinAttrSec_UIScrollView_ContentInset, LookinAttrSec_UIScrollView_AdjustedInset, LookinAttrSec_UIScrollView_QMUIInitialInset, LookinAttrSec_UIScrollView_IndicatorInset, LookinAttrSec_UIScrollView_Offset, LookinAttrSec_UIScrollView_ContentSize, LookinAttrSec_UIScrollView_Behavior, LookinAttrSec_UIScrollView_ShowsIndicator, LookinAttrSec_UIScrollView_Bounce, LookinAttrSec_UIScrollView_ScrollPaging, LookinAttrSec_UIScrollView_ContentTouches, LookinAttrSec_UIScrollView_Zoom],
        LookinAttrGroup_UITableView: [LookinAttrSec_UITableView_Style, LookinAttrSec_UITableView_SectionsNumber, LookinAttrSec_UITableView_RowsNumber, LookinAttrSec_UITableView_SeparatorStyle, LookinAttrSec_UITableView_SeparatorColor, LookinAttrSec_UITableView_SeparatorInset],
        LookinAttrGroup_UITextView: [LookinAttrSec_UITextView_Basic, LookinAttrSec_UITextView_Text, LookinAttrSec_UITextView_Font, LookinAttrSec_UITextView_TextColor, LookinAttrSec_UITextView_Alignment, LookinAttrSec_UITextView_ContainerInset],
        LookinAttrGroup_UITextField: [LookinAttrSec_UITextField_Text, LookinAttrSec_UITextField_Placeholder, LookinAttrSec_UITextField_Font, LookinAttrSec_UITextField_TextColor, LookinAttrSec_UITextField_Alignment, LookinAttrSec_UITextField_Clears, LookinAttrSec_UITextField_CanAdjustFont, LookinAttrSec_UITextField_ClearButtonMode],
    ]

    private static let attrsBySection: [LookinAttrSectionIdentifier: [LookinAttrIdentifier]] = [
        LookinAttrSec_Class_Class: [LookinAttr_Class_Class_Class],
        LookinAttrSec_Accessibility_Identifier: [LookinAttr_Accessibility_Identifier],
        LookinAttrSec_Accessibility_Label: [LookinAttr_Accessibility_Label],
        LookinAttrSec_Accessibility_Value: [LookinAttr_Accessibility_Value],
        LookinAttrSec_Accessibility_Hint: [LookinAttr_Accessibility_Hint],
        LookinAttrSec_Accessibility_Flags: [
            LookinAttr_Accessibility_IsElement,
            LookinAttr_Accessibility_ElementsHidden,
            LookinAttr_Accessibility_ViewIsModal,
        ],
        LookinAttrSec_Accessibility_Traits: [LookinAttr_Accessibility_Traits],
        LookinAttrSec_Relation_Relation: [LookinAttr_Relation_Relation_Relation],
        LookinAttrSec_Layout_Frame: [LookinAttr_Layout_Frame_Frame],
        LookinAttrSec_Layout_Bounds: [LookinAttr_Layout_Bounds_Bounds],
        LookinAttrSec_Layout_SafeArea: [LookinAttr_Layout_SafeArea_SafeArea],
        LookinAttrSec_Layout_Position: [LookinAttr_Layout_Position_Position],
        LookinAttrSec_Layout_AnchorPoint: [LookinAttr_Layout_AnchorPoint_AnchorPoint],
        LookinAttrSec_AutoLayout_Hugging: [LookinAttr_AutoLayout_Hugging_Hor, LookinAttr_AutoLayout_Hugging_Ver],
        LookinAttrSec_AutoLayout_Resistance: [LookinAttr_AutoLayout_Resistance_Hor, LookinAttr_AutoLayout_Resistance_Ver],
        LookinAttrSec_AutoLayout_Constraints: [LookinAttr_AutoLayout_Constraints_Constraints],
        LookinAttrSec_AutoLayout_IntrinsicSize: [LookinAttr_AutoLayout_IntrinsicSize_Size],
        LookinAttrSec_ViewLayer_Visibility: [LookinAttr_ViewLayer_Visibility_Hidden, LookinAttr_ViewLayer_Visibility_Opacity],
        LookinAttrSec_ViewLayer_InterationAndMasks: [LookinAttr_ViewLayer_InterationAndMasks_Interaction, LookinAttr_ViewLayer_InterationAndMasks_MasksToBounds],
        LookinAttrSec_ViewLayer_Corner: [LookinAttr_ViewLayer_Corner_Radius],
        LookinAttrSec_ViewLayer_BgColor: [LookinAttr_ViewLayer_BgColor_BgColor],
        LookinAttrSec_ViewLayer_Border: [LookinAttr_ViewLayer_Border_Color, LookinAttr_ViewLayer_Border_Width],
        LookinAttrSec_ViewLayer_Shadow: [LookinAttr_ViewLayer_Shadow_Color, LookinAttr_ViewLayer_Shadow_Opacity, LookinAttr_ViewLayer_Shadow_Radius, LookinAttr_ViewLayer_Shadow_OffsetW, LookinAttr_ViewLayer_Shadow_OffsetH],
        LookinAttrSec_ViewLayer_ContentMode: [LookinAttr_ViewLayer_ContentMode_Mode],
        LookinAttrSec_ViewLayer_TintColor: [LookinAttr_ViewLayer_TintColor_Color, LookinAttr_ViewLayer_TintColor_Mode],
        LookinAttrSec_ViewLayer_Tag: [LookinAttr_ViewLayer_Tag_Tag],
        LookinAttrSec_UIStackView_Axis: [LookinAttr_UIStackView_Axis_Axis],
        LookinAttrSec_UIStackView_Distribution: [LookinAttr_UIStackView_Distribution_Distribution],
        LookinAttrSec_UIStackView_Alignment: [LookinAttr_UIStackView_Alignment_Alignment],
        LookinAttrSec_UIStackView_Spacing: [LookinAttr_UIStackView_Spacing_Spacing],
        LookinAttrSec_UIVisualEffectView_Style: [LookinAttr_UIVisualEffectView_Style_Style],
        LookinAttrSec_UIVisualEffectView_QMUIForegroundColor: [LookinAttr_UIVisualEffectView_QMUIForegroundColor_Color],
        LookinAttrSec_UIImageView_Name: [LookinAttr_UIImageView_Name_Name],
        LookinAttrSec_UIImageView_Open: [LookinAttr_UIImageView_Open_Open],
        LookinAttrSec_UILabel_Font: [LookinAttr_UILabel_Font_Name, LookinAttr_UILabel_Font_Size],
        LookinAttrSec_UILabel_NumberOfLines: [LookinAttr_UILabel_NumberOfLines_NumberOfLines],
        LookinAttrSec_UILabel_Text: [LookinAttr_UILabel_Text_Text],
        LookinAttrSec_UILabel_TextColor: [LookinAttr_UILabel_TextColor_Color],
        LookinAttrSec_UILabel_BreakMode: [LookinAttr_UILabel_BreakMode_Mode],
        LookinAttrSec_UILabel_Alignment: [LookinAttr_UILabel_Alignment_Alignment],
        LookinAttrSec_UILabel_CanAdjustFont: [LookinAttr_UILabel_CanAdjustFont_CanAdjustFont],
        LookinAttrSec_UIControl_EnabledSelected: [LookinAttr_UIControl_EnabledSelected_Enabled, LookinAttr_UIControl_EnabledSelected_Selected],
        LookinAttrSec_UIControl_QMUIOutsideEdge: [LookinAttr_UIControl_QMUIOutsideEdge_Edge],
        LookinAttrSec_UIControl_VerAlignment: [LookinAttr_UIControl_VerAlignment_Alignment],
        LookinAttrSec_UIControl_HorAlignment: [LookinAttr_UIControl_HorAlignment_Alignment],
        LookinAttrSec_UIButton_ContentInsets: [LookinAttr_UIButton_ContentInsets_Insets],
        LookinAttrSec_UIButton_TitleInsets: [LookinAttr_UIButton_TitleInsets_Insets],
        LookinAttrSec_UIButton_ImageInsets: [LookinAttr_UIButton_ImageInsets_Insets],
        LookinAttrSec_UIScrollView_ContentInset: [LookinAttr_UIScrollView_ContentInset_Inset],
        LookinAttrSec_UIScrollView_AdjustedInset: [LookinAttr_UIScrollView_AdjustedInset_Inset],
        LookinAttrSec_UIScrollView_QMUIInitialInset: [LookinAttr_UIScrollView_QMUIInitialInset_Inset],
        LookinAttrSec_UIScrollView_IndicatorInset: [LookinAttr_UIScrollView_IndicatorInset_Inset],
        LookinAttrSec_UIScrollView_Offset: [LookinAttr_UIScrollView_Offset_Offset],
        LookinAttrSec_UIScrollView_ContentSize: [LookinAttr_UIScrollView_ContentSize_Size],
        LookinAttrSec_UIScrollView_Behavior: [LookinAttr_UIScrollView_Behavior_Behavior],
        LookinAttrSec_UIScrollView_ShowsIndicator: [LookinAttr_UIScrollView_ShowsIndicator_Hor, LookinAttr_UIScrollView_ShowsIndicator_Ver],
        LookinAttrSec_UIScrollView_Bounce: [LookinAttr_UIScrollView_Bounce_Hor, LookinAttr_UIScrollView_Bounce_Ver],
        LookinAttrSec_UIScrollView_ScrollPaging: [LookinAttr_UIScrollView_ScrollPaging_ScrollEnabled, LookinAttr_UIScrollView_ScrollPaging_PagingEnabled],
        LookinAttrSec_UIScrollView_ContentTouches: [LookinAttr_UIScrollView_ContentTouches_Delay, LookinAttr_UIScrollView_ContentTouches_CanCancel],
        LookinAttrSec_UIScrollView_Zoom: [LookinAttr_UIScrollView_Zoom_Bounce, LookinAttr_UIScrollView_Zoom_Scale, LookinAttr_UIScrollView_Zoom_MinScale, LookinAttr_UIScrollView_Zoom_MaxScale],
        LookinAttrSec_UITableView_Style: [LookinAttr_UITableView_Style_Style],
        LookinAttrSec_UITableView_SectionsNumber: [LookinAttr_UITableView_SectionsNumber_Number],
        LookinAttrSec_UITableView_RowsNumber: [LookinAttr_UITableView_RowsNumber_Number],
        LookinAttrSec_UITableView_SeparatorInset: [LookinAttr_UITableView_SeparatorInset_Inset],
        LookinAttrSec_UITableView_SeparatorColor: [LookinAttr_UITableView_SeparatorColor_Color],
        LookinAttrSec_UITableView_SeparatorStyle: [LookinAttr_UITableView_SeparatorStyle_Style],
        LookinAttrSec_UITextView_Basic: [LookinAttr_UITextView_Basic_Editable, LookinAttr_UITextView_Basic_Selectable],
        LookinAttrSec_UITextView_Text: [LookinAttr_UITextView_Text_Text],
        LookinAttrSec_UITextView_Font: [LookinAttr_UITextView_Font_Name, LookinAttr_UITextView_Font_Size],
        LookinAttrSec_UITextView_TextColor: [LookinAttr_UITextView_TextColor_Color],
        LookinAttrSec_UITextView_Alignment: [LookinAttr_UITextView_Alignment_Alignment],
        LookinAttrSec_UITextView_ContainerInset: [LookinAttr_UITextView_ContainerInset_Inset],
        LookinAttrSec_UITextField_Text: [LookinAttr_UITextField_Text_Text],
        LookinAttrSec_UITextField_Placeholder: [LookinAttr_UITextField_Placeholder_Placeholder],
        LookinAttrSec_UITextField_Font: [LookinAttr_UITextField_Font_Name, LookinAttr_UITextField_Font_Size],
        LookinAttrSec_UITextField_TextColor: [LookinAttr_UITextField_TextColor_Color],
        LookinAttrSec_UITextField_Alignment: [LookinAttr_UITextField_Alignment_Alignment],
        LookinAttrSec_UITextField_Clears: [LookinAttr_UITextField_Clears_ClearsOnBeginEditing, LookinAttr_UITextField_Clears_ClearsOnInsertion],
        LookinAttrSec_UITextField_CanAdjustFont: [LookinAttr_UITextField_CanAdjustFont_CanAdjustFont, LookinAttr_UITextField_CanAdjustFont_MinSize],
        LookinAttrSec_UITextField_ClearButtonMode: [LookinAttr_UITextField_ClearButtonMode_Mode],
    ]

    private static let groupTitles: [LookinAttrGroupIdentifier: String] = [
        LookinAttrGroup_Class: "Class",
        LookinAttrGroup_Accessibility: "Accessibility",
        LookinAttrGroup_Relation: "Relation",
        LookinAttrGroup_Layout: "Layout",
        LookinAttrGroup_AutoLayout: "AutoLayout",
        LookinAttrGroup_ViewLayer: "CALayer / UIView",
        LookinAttrGroup_UIImageView: "UIImageView",
        LookinAttrGroup_UILabel: "UILabel",
        LookinAttrGroup_UIControl: "UIControl",
        LookinAttrGroup_UIButton: "UIButton",
        LookinAttrGroup_UIScrollView: "UIScrollView",
        LookinAttrGroup_UITableView: "UITableView",
        LookinAttrGroup_UITextView: "UITextView",
        LookinAttrGroup_UITextField: "UITextField",
        LookinAttrGroup_UIVisualEffectView: "UIVisualEffectView",
        LookinAttrGroup_UIStackView: "UIStackView",
    ]

    private static let sectionTitles: [LookinAttrSectionIdentifier: String] = [
        LookinAttrSec_Layout_Frame: "Frame",
        LookinAttrSec_Layout_Bounds: "Bounds",
        LookinAttrSec_Layout_SafeArea: "SafeArea",
        LookinAttrSec_Layout_Position: "Position",
        LookinAttrSec_Layout_AnchorPoint: "AnchorPoint",
        LookinAttrSec_AutoLayout_Hugging: "HuggingPriority",
        LookinAttrSec_AutoLayout_Resistance: "ResistancePriority",
        LookinAttrSec_AutoLayout_IntrinsicSize: "IntrinsicSize",
        LookinAttrSec_ViewLayer_Corner: "CornerRadius",
        LookinAttrSec_ViewLayer_BgColor: "BackgroundColor",
        LookinAttrSec_ViewLayer_Border: "Border",
        LookinAttrSec_ViewLayer_Shadow: "Shadow",
        LookinAttrSec_ViewLayer_ContentMode: "ContentMode",
        LookinAttrSec_ViewLayer_TintColor: "TintColor",
        LookinAttrSec_ViewLayer_Tag: "Tag",
        LookinAttrSec_UIStackView_Axis: "Axis",
        LookinAttrSec_UIStackView_Distribution: "Distribution",
        LookinAttrSec_UIStackView_Alignment: "Alignment",
        LookinAttrSec_UIVisualEffectView_Style: "Style",
        LookinAttrSec_UIVisualEffectView_QMUIForegroundColor: "ForegroundColor",
        LookinAttrSec_UIImageView_Name: "ImageName",
        LookinAttrSec_UILabel_TextColor: "TextColor",
        LookinAttrSec_UITextView_TextColor: "TextColor",
        LookinAttrSec_UITextField_TextColor: "TextColor",
        LookinAttrSec_UILabel_BreakMode: "LineBreakMode",
        LookinAttrSec_UILabel_NumberOfLines: "NumberOfLines",
        LookinAttrSec_Accessibility_Identifier: "Identifier",
        LookinAttrSec_Accessibility_Label: "Label",
        LookinAttrSec_Accessibility_Value: "Value",
        LookinAttrSec_Accessibility_Hint: "Hint",
        LookinAttrSec_Accessibility_Traits: "Traits",
        LookinAttrSec_UILabel_Text: "Text",
        LookinAttrSec_UITextView_Text: "Text",
        LookinAttrSec_UITextField_Text: "Text",
        LookinAttrSec_UITextField_Placeholder: "Placeholder",
        LookinAttrSec_UILabel_Alignment: "TextAlignment",
        LookinAttrSec_UITextView_Alignment: "TextAlignment",
        LookinAttrSec_UITextField_Alignment: "TextAlignment",
        LookinAttrSec_UIControl_HorAlignment: "HorizontalAlignment",
        LookinAttrSec_UIControl_VerAlignment: "VerticalAlignment",
        LookinAttrSec_UIControl_QMUIOutsideEdge: "QMUI_outsideEdge",
        LookinAttrSec_UIButton_ContentInsets: "ContentInsets",
        LookinAttrSec_UIButton_TitleInsets: "TitleInsets",
        LookinAttrSec_UIButton_ImageInsets: "ImageInsets",
        LookinAttrSec_UIScrollView_QMUIInitialInset: "QMUI_initialContentInset",
        LookinAttrSec_UIScrollView_ContentInset: "ContentInset",
        LookinAttrSec_UIScrollView_AdjustedInset: "AdjustedContentInset",
        LookinAttrSec_UIScrollView_IndicatorInset: "ScrollIndicatorInsets",
        LookinAttrSec_UIScrollView_Offset: "ContentOffset",
        LookinAttrSec_UIScrollView_ContentSize: "ContentSize",
        LookinAttrSec_UIScrollView_Behavior: "InsetAdjustmentBehavior",
        LookinAttrSec_UIScrollView_ShowsIndicator: "ShowsScrollIndicator",
        LookinAttrSec_UIScrollView_Bounce: "AlwaysBounce",
        LookinAttrSec_UIScrollView_Zoom: "Zoom",
        LookinAttrSec_UITableView_Style: "Style",
        LookinAttrSec_UITableView_SectionsNumber: "NumberOfSections",
        LookinAttrSec_UITableView_RowsNumber: "NumberOfRows",
        LookinAttrSec_UITableView_SeparatorColor: "SeparatorColor",
        LookinAttrSec_UITableView_SeparatorInset: "SeparatorInset",
        LookinAttrSec_UITableView_SeparatorStyle: "SeparatorStyle",
        LookinAttrSec_UILabel_Font: "Font",
        LookinAttrSec_UITextField_Font: "Font",
        LookinAttrSec_UITextView_Font: "Font",
        LookinAttrSec_UITextView_ContainerInset: "ContainerInset",
        LookinAttrSec_UITextField_ClearButtonMode: "ClearButtonMode",
    ]

    private static let attrInfos: [LookinAttrIdentifier: AttrInfo] = {
        var dict: [LookinAttrIdentifier: AttrInfo] = [:]
        dict[LookinAttr_Class_Class_Class] = AttrInfo(
            className: "CALayer",
            getter: .lks_relatedClassChainList,
            setterString: "",
            typeIfObj: LookinAttrType.customObj
        )
        dict[LookinAttr_Accessibility_Identifier] = AttrInfo(
            className: "UIView",
            fullTitle: "AccessibilityIdentifier",
            setterString: "",
            typeIfObj: LookinAttrType.NSString,
            patch: false
        )
        dict[LookinAttr_Accessibility_Label] = AttrInfo(
            className: "UIView",
            fullTitle: "AccessibilityLabel",
            setterString: "",
            typeIfObj: LookinAttrType.NSString,
            patch: false
        )
        dict[LookinAttr_Accessibility_Value] = AttrInfo(
            className: "UIView",
            fullTitle: "AccessibilityValue",
            setterString: "",
            typeIfObj: LookinAttrType.NSString,
            patch: false
        )
        dict[LookinAttr_Accessibility_Hint] = AttrInfo(
            className: "UIView",
            fullTitle: "AccessibilityHint",
            setterString: "",
            typeIfObj: LookinAttrType.NSString,
            patch: false
        )
        dict[LookinAttr_Accessibility_IsElement] = AttrInfo(
            className: "UIView",
            fullTitle: "IsAccessibilityElement",
            briefTitle: "IsElement",
            getter: .isAccessibilityElement,
            setterString: "",
            patch: false
        )
        dict[LookinAttr_Accessibility_Traits] = AttrInfo(
            className: "UIView",
            fullTitle: "AccessibilityTraits",
            getter: .lks_accessibilityTraitsDescription,
            setterString: "",
            typeIfObj: LookinAttrType.NSString,
            hideIfNil: true
        )
        dict[LookinAttr_Accessibility_ElementsHidden] = AttrInfo(
            className: "UIView",
            fullTitle: "AccessibilityElementsHidden",
            briefTitle: "ElementsHidden",
            setterString: "",
            patch: false
        )
        dict[LookinAttr_Accessibility_ViewIsModal] = AttrInfo(
            className: "UIView",
            fullTitle: "AccessibilityViewIsModal",
            briefTitle: "ViewIsModal",
            setterString: "",
            patch: false
        )
        dict[LookinAttr_Relation_Relation_Relation] = AttrInfo(
            className: "CALayer",
            getter: .lks_selfRelation,
            setterString: "",
            typeIfObj: LookinAttrType.customObj,
            hideIfNil: true
        )
        dict[LookinAttr_Layout_Frame_Frame] = AttrInfo(
            className: "CALayer",
            fullTitle: "Frame",
            patch: true
        )
        dict[LookinAttr_Layout_Bounds_Bounds] = AttrInfo(
            className: "CALayer",
            fullTitle: "Bounds",
            patch: true
        )
        dict[LookinAttr_Layout_SafeArea_SafeArea] = AttrInfo(
            className: "UIView",
            fullTitle: "SafeAreaInsets",
            setterString: "",
            osVersion: 11
        )
        dict[LookinAttr_Layout_Position_Position] = AttrInfo(
            className: "CALayer",
            fullTitle: "Position",
            patch: true
        )
        dict[LookinAttr_Layout_AnchorPoint_AnchorPoint] = AttrInfo(
            className: "CALayer",
            fullTitle: "AnchorPoint",
            patch: true
        )
        dict[LookinAttr_AutoLayout_Hugging_Hor] = AttrInfo(
            className: "UIView",
            fullTitle: "ContentHuggingPriority(Horizontal)",
            briefTitle: "H",
            getter: .lks_horizontalContentHuggingPriority,
            setterString: "setLks_horizontalContentHuggingPriority:",
            patch: true
        )
        dict[LookinAttr_AutoLayout_Hugging_Ver] = AttrInfo(
            className: "UIView",
            fullTitle: "ContentHuggingPriority(Vertical)",
            briefTitle: "V",
            getter: .lks_verticalContentHuggingPriority,
            setterString: "setLks_verticalContentHuggingPriority:",
            patch: true
        )
        dict[LookinAttr_AutoLayout_Resistance_Hor] = AttrInfo(
            className: "UIView",
            fullTitle: "ContentCompressionResistancePriority(Horizontal)",
            briefTitle: "H",
            getter: .lks_horizontalContentCompressionResistancePriority,
            setterString: "setLks_horizontalContentCompressionResistancePriority:",
            patch: true
        )
        dict[LookinAttr_AutoLayout_Resistance_Ver] = AttrInfo(
            className: "UIView",
            fullTitle: "ContentCompressionResistancePriority(Vertical)",
            briefTitle: "V",
            getter: .lks_verticalContentCompressionResistancePriority,
            setterString: "setLks_verticalContentCompressionResistancePriority:",
            patch: true
        )
        dict[LookinAttr_AutoLayout_Constraints_Constraints] = AttrInfo(
            className: "UIView",
            getter: .lks_constraints,
            setterString: "",
            typeIfObj: LookinAttrType.customObj,
            hideIfNil: true
        )
        dict[LookinAttr_AutoLayout_IntrinsicSize_Size] = AttrInfo(
            className: "UIView",
            fullTitle: "IntrinsicContentSize",
            setterString: ""
        )
        dict[LookinAttr_ViewLayer_Visibility_Hidden] = AttrInfo(
            className: "CALayer",
            fullTitle: "Hidden",
            getter: .isHidden,
            patch: false
        )
        dict[LookinAttr_ViewLayer_Visibility_Opacity] = AttrInfo(
            className: "CALayer",
            fullTitle: "Opacity / Alpha",
            getter: .opacity,
            setterString: "setOpacity:",
            patch: false
        )
        dict[LookinAttr_ViewLayer_InterationAndMasks_Interaction] = AttrInfo(
            className: "UIView",
            fullTitle: "UserInteractionEnabled",
            getter: .isUserInteractionEnabled,
            patch: false
        )
        dict[LookinAttr_ViewLayer_InterationAndMasks_MasksToBounds] = AttrInfo(
            className: "CALayer",
            fullTitle: "MasksToBounds / ClipsToBounds",
            briefTitle: "MasksToBounds",
            getter: .masksToBounds,
            setterString: "setMasksToBounds:",
            patch: true
        )
        dict[LookinAttr_ViewLayer_Corner_Radius] = AttrInfo(
            className: "CALayer",
            fullTitle: "CornerRadius",
            briefTitle: "",
            patch: true
        )
        dict[LookinAttr_ViewLayer_BgColor_BgColor] = AttrInfo(
            className: "CALayer",
            fullTitle: "BackgroundColor",
            getter: .lks_backgroundColor,
            setterString: "setLks_backgroundColor:",
            typeIfObj: LookinAttrType.UIColor,
            patch: true
        )
        dict[LookinAttr_ViewLayer_Border_Color] = AttrInfo(
            className: "CALayer",
            fullTitle: "BorderColor",
            getter: .lks_borderColor,
            setterString: "setLks_borderColor:",
            typeIfObj: LookinAttrType.UIColor,
            patch: true
        )
        dict[LookinAttr_ViewLayer_Border_Width] = AttrInfo(
            className: "CALayer",
            fullTitle: "BorderWidth",
            patch: true
        )
        dict[LookinAttr_ViewLayer_Shadow_Color] = AttrInfo(
            className: "CALayer",
            fullTitle: "ShadowColor",
            getter: .lks_shadowColor,
            setterString: "setLks_shadowColor:",
            typeIfObj: LookinAttrType.UIColor,
            patch: true
        )
        dict[LookinAttr_ViewLayer_Shadow_Opacity] = AttrInfo(
            className: "CALayer",
            fullTitle: "ShadowOpacity",
            briefTitle: "Opacity",
            patch: true
        )
        dict[LookinAttr_ViewLayer_Shadow_Radius] = AttrInfo(
            className: "CALayer",
            fullTitle: "ShadowRadius",
            briefTitle: "Radius",
            patch: true
        )
        dict[LookinAttr_ViewLayer_Shadow_OffsetW] = AttrInfo(
            className: "CALayer",
            fullTitle: "ShadowOffsetWidth",
            briefTitle: "OffsetW",
            getter: .lks_shadowOffsetWidth,
            setterString: "setLks_shadowOffsetWidth:",
            patch: true
        )
        dict[LookinAttr_ViewLayer_Shadow_OffsetH] = AttrInfo(
            className: "CALayer",
            fullTitle: "ShadowOffsetHeight",
            briefTitle: "OffsetH",
            getter: .lks_shadowOffsetHeight,
            setterString: "setLks_shadowOffsetHeight:",
            patch: true
        )
        dict[LookinAttr_ViewLayer_ContentMode_Mode] = AttrInfo(
            className: "UIView",
            fullTitle: "ContentMode",
            enumList: "UIViewContentMode",
            patch: true
        )
        dict[LookinAttr_ViewLayer_TintColor_Color] = AttrInfo(
            className: "UIView",
            fullTitle: "TintColor",
            typeIfObj: LookinAttrType.UIColor,
            patch: true
        )
        dict[LookinAttr_ViewLayer_TintColor_Mode] = AttrInfo(
            className: "UIView",
            fullTitle: "TintAdjustmentMode",
            enumList: "UIViewTintAdjustmentMode",
            patch: true
        )
        dict[LookinAttr_ViewLayer_Tag_Tag] = AttrInfo(
            className: "UIView",
            fullTitle: "Tag",
            briefTitle: "",
            patch: false
        )
        dict[LookinAttr_UIStackView_Axis_Axis] = AttrInfo(
            className: "UIStackView",
            fullTitle: "Axis",
            enumList: "UILayoutConstraintAxis",
            patch: true
        )
        dict[LookinAttr_UIStackView_Distribution_Distribution] = AttrInfo(
            className: "UIStackView",
            fullTitle: "Distribution",
            enumList: "UIStackViewDistribution",
            patch: true
        )
        dict[LookinAttr_UIStackView_Alignment_Alignment] = AttrInfo(
            className: "UIStackView",
            fullTitle: "Alignment",
            enumList: "UIStackViewAlignment",
            patch: true
        )
        dict[LookinAttr_UIStackView_Spacing_Spacing] = AttrInfo(
            className: "UIStackView",
            fullTitle: "Spacing",
            patch: true
        )
        dict[LookinAttr_UIVisualEffectView_Style_Style] = AttrInfo(
            className: "UIVisualEffectView",
            getter: .lks_blurEffectStyleNumber,
            setterString: "setLks_blurEffectStyleNumber:",
            typeIfObj: LookinAttrType.customObj,
            enumList: "UIBlurEffectStyle",
            patch: true,
            hideIfNil: true
        )
        dict[LookinAttr_UIVisualEffectView_QMUIForegroundColor_Color] = AttrInfo(
            className: "QMUIVisualEffectView",
            fullTitle: "ForegroundColor",
            typeIfObj: LookinAttrType.UIColor,
            patch: true
        )
        dict[LookinAttr_UIImageView_Name_Name] = AttrInfo(
            className: "UIImageView",
            fullTitle: "ImageName",
            getter: .lks_imageSourceName,
            setterString: "",
            typeIfObj: LookinAttrType.NSString,
            hideIfNil: true
        )
        dict[LookinAttr_UIImageView_Open_Open] = AttrInfo(
            className: "UIImageView",
            getter: .lks_imageViewOidIfHasImage,
            setterString: "",
            typeIfObj: LookinAttrType.customObj,
            hideIfNil: true
        )
        dict[LookinAttr_UILabel_Text_Text] = AttrInfo(
            className: "UILabel",
            fullTitle: "Text",
            typeIfObj: LookinAttrType.NSString,
            patch: true
        )
        dict[LookinAttr_UILabel_NumberOfLines_NumberOfLines] = AttrInfo(
            className: "UILabel",
            fullTitle: "NumberOfLines",
            briefTitle: "",
            patch: true
        )
        dict[LookinAttr_UILabel_Font_Size] = AttrInfo(
            className: "UILabel",
            fullTitle: "FontSize",
            briefTitle: "FontSize",
            getter: .lks_fontSize,
            setterString: "setLks_fontSize:",
            patch: true
        )
        dict[LookinAttr_UILabel_Font_Name] = AttrInfo(
            className: "UILabel",
            fullTitle: "FontName",
            getter: .lks_fontName,
            setterString: "",
            typeIfObj: LookinAttrType.NSString,
            patch: false
        )
        dict[LookinAttr_UILabel_TextColor_Color] = AttrInfo(
            className: "UILabel",
            fullTitle: "TextColor",
            typeIfObj: LookinAttrType.UIColor,
            patch: true
        )
        dict[LookinAttr_UILabel_Alignment_Alignment] = AttrInfo(
            className: "UILabel",
            fullTitle: "TextAlignment",
            enumList: "NSTextAlignment",
            patch: true
        )
        dict[LookinAttr_UILabel_BreakMode_Mode] = AttrInfo(
            className: "UILabel",
            fullTitle: "LineBreakMode",
            enumList: "NSLineBreakMode",
            patch: true
        )
        dict[LookinAttr_UILabel_CanAdjustFont_CanAdjustFont] = AttrInfo(
            className: "UILabel",
            fullTitle: "AdjustsFontSizeToFitWidth",
            patch: true
        )
        dict[LookinAttr_UIControl_EnabledSelected_Enabled] = AttrInfo(
            className: "UIControl",
            fullTitle: "Enabled",
            getter: .isEnabled,
            patch: false
        )
        dict[LookinAttr_UIControl_EnabledSelected_Selected] = AttrInfo(
            className: "UIControl",
            fullTitle: "Selected",
            getter: .isSelected,
            patch: true
        )
        dict[LookinAttr_UIControl_VerAlignment_Alignment] = AttrInfo(
            className: "UIControl",
            fullTitle: "ContentVerticalAlignment",
            enumList: "UIControlContentVerticalAlignment",
            patch: true
        )
        dict[LookinAttr_UIControl_HorAlignment_Alignment] = AttrInfo(
            className: "UIControl",
            fullTitle: "ContentHorizontalAlignment",
            enumList: "UIControlContentHorizontalAlignment",
            patch: true
        )
        dict[LookinAttr_UIControl_QMUIOutsideEdge_Edge] = AttrInfo(
            className: "UIControl",
            fullTitle: "qmui_outsideEdge"
        )
        dict[LookinAttr_UIButton_ContentInsets_Insets] = AttrInfo(
            className: "UIButton",
            fullTitle: "ContentEdgeInsets",
            patch: true
        )
        dict[LookinAttr_UIButton_TitleInsets_Insets] = AttrInfo(
            className: "UIButton",
            fullTitle: "TitleEdgeInsets",
            patch: true
        )
        dict[LookinAttr_UIButton_ImageInsets_Insets] = AttrInfo(
            className: "UIButton",
            fullTitle: "ImageEdgeInsets",
            patch: true
        )
        dict[LookinAttr_UIScrollView_Offset_Offset] = AttrInfo(
            className: "UIScrollView",
            fullTitle: "ContentOffset",
            patch: true
        )
        dict[LookinAttr_UIScrollView_ContentSize_Size] = AttrInfo(
            className: "UIScrollView",
            fullTitle: "ContentSize",
            patch: true
        )
        dict[LookinAttr_UIScrollView_ContentInset_Inset] = AttrInfo(
            className: "UIScrollView",
            fullTitle: "ContentInset",
            patch: true
        )
        dict[LookinAttr_UIScrollView_QMUIInitialInset_Inset] = AttrInfo(
            className: "UIScrollView",
            fullTitle: "qmui_initialContentInset",
            patch: true
        )
        dict[LookinAttr_UIScrollView_AdjustedInset_Inset] = AttrInfo(
            className: "UIScrollView",
            fullTitle: "AdjustedContentInset",
            setterString: "",
            osVersion: 11
        )
        dict[LookinAttr_UIScrollView_Behavior_Behavior] = AttrInfo(
            className: "UIScrollView",
            fullTitle: "ContentInsetAdjustmentBehavior",
            enumList: "UIScrollViewContentInsetAdjustmentBehavior",
            patch: true,
            osVersion: 11
        )
        dict[LookinAttr_UIScrollView_IndicatorInset_Inset] = AttrInfo(
            className: "UIScrollView",
            fullTitle: "ScrollIndicatorInsets",
            patch: false
        )
        dict[LookinAttr_UIScrollView_ScrollPaging_ScrollEnabled] = AttrInfo(
            className: "UIScrollView",
            fullTitle: "ScrollEnabled",
            getter: .isScrollEnabled,
            patch: false
        )
        dict[LookinAttr_UIScrollView_ScrollPaging_PagingEnabled] = AttrInfo(
            className: "UIScrollView",
            fullTitle: "PagingEnabled",
            getter: .isPagingEnabled,
            patch: false
        )
        dict[LookinAttr_UIScrollView_Bounce_Ver] = AttrInfo(
            className: "UIScrollView",
            fullTitle: "AlwaysBounceVertical",
            briefTitle: "Vertical",
            patch: false
        )
        dict[LookinAttr_UIScrollView_Bounce_Hor] = AttrInfo(
            className: "UIScrollView",
            fullTitle: "AlwaysBounceHorizontal",
            briefTitle: "Horizontal",
            patch: false
        )
        dict[LookinAttr_UIScrollView_ShowsIndicator_Hor] = AttrInfo(
            className: "UIScrollView",
            fullTitle: "ShowsHorizontalScrollIndicator",
            briefTitle: "Horizontal",
            patch: false
        )
        dict[LookinAttr_UIScrollView_ShowsIndicator_Ver] = AttrInfo(
            className: "UIScrollView",
            fullTitle: "ShowsVerticalScrollIndicator",
            briefTitle: "Vertical",
            patch: false
        )
        dict[LookinAttr_UIScrollView_ContentTouches_Delay] = AttrInfo(
            className: "UIScrollView",
            fullTitle: "DelaysContentTouches",
            patch: false
        )
        dict[LookinAttr_UIScrollView_ContentTouches_CanCancel] = AttrInfo(
            className: "UIScrollView",
            fullTitle: "CanCancelContentTouches",
            patch: false
        )
        dict[LookinAttr_UIScrollView_Zoom_MinScale] = AttrInfo(
            className: "UIScrollView",
            fullTitle: "MinimumZoomScale",
            briefTitle: "MinScale",
            patch: false
        )
        dict[LookinAttr_UIScrollView_Zoom_MaxScale] = AttrInfo(
            className: "UIScrollView",
            fullTitle: "MaximumZoomScale",
            briefTitle: "MaxScale",
            patch: false
        )
        dict[LookinAttr_UIScrollView_Zoom_Scale] = AttrInfo(
            className: "UIScrollView",
            fullTitle: "ZoomScale",
            briefTitle: "Scale",
            patch: true
        )
        dict[LookinAttr_UIScrollView_Zoom_Bounce] = AttrInfo(
            className: "UIScrollView",
            fullTitle: "BouncesZoom",
            patch: false
        )
        dict[LookinAttr_UITableView_Style_Style] = AttrInfo(
            className: "UITableView",
            fullTitle: "Style",
            setterString: "",
            enumList: "UITableViewStyle",
            patch: true
        )
        dict[LookinAttr_UITableView_SectionsNumber_Number] = AttrInfo(
            className: "UITableView",
            fullTitle: "NumberOfSections",
            setterString: "",
            patch: true
        )
        dict[LookinAttr_UITableView_RowsNumber_Number] = AttrInfo(
            className: "UITableView",
            getter: .lks_numberOfRows,
            setterString: "",
            typeIfObj: LookinAttrType.customObj
        )
        dict[LookinAttr_UITableView_SeparatorInset_Inset] = AttrInfo(
            className: "UITableView",
            fullTitle: "SeparatorInset",
            patch: false
        )
        dict[LookinAttr_UITableView_SeparatorColor_Color] = AttrInfo(
            className: "UITableView",
            fullTitle: "SeparatorColor",
            typeIfObj: LookinAttrType.UIColor,
            patch: true
        )
        dict[LookinAttr_UITableView_SeparatorStyle_Style] = AttrInfo(
            className: "UITableView",
            fullTitle: "SeparatorStyle",
            enumList: "UITableViewCellSeparatorStyle",
            patch: true
        )
        dict[LookinAttr_UITextView_Text_Text] = AttrInfo(
            className: "UITextView",
            fullTitle: "Text",
            typeIfObj: LookinAttrType.NSString,
            patch: true
        )
        dict[LookinAttr_UITextView_Font_Name] = AttrInfo(
            className: "UITextView",
            fullTitle: "FontName",
            getter: .lks_fontName,
            setterString: "",
            typeIfObj: LookinAttrType.NSString,
            patch: false
        )
        dict[LookinAttr_UITextView_Font_Size] = AttrInfo(
            className: "UITextView",
            fullTitle: "FontSize",
            getter: .lks_fontSize,
            setterString: "setLks_fontSize:",
            patch: true
        )
        dict[LookinAttr_UITextView_Basic_Editable] = AttrInfo(
            className: "UITextView",
            fullTitle: "Editable",
            getter: .isEditable,
            patch: false
        )
        dict[LookinAttr_UITextView_Basic_Selectable] = AttrInfo(
            className: "UITextView",
            fullTitle: "Selectable",
            getter: .isSelectable,
            patch: false
        )
        dict[LookinAttr_UITextView_TextColor_Color] = AttrInfo(
            className: "UITextView",
            fullTitle: "TextColor",
            typeIfObj: LookinAttrType.UIColor,
            patch: true
        )
        dict[LookinAttr_UITextView_Alignment_Alignment] = AttrInfo(
            className: "UITextView",
            fullTitle: "TextAlignment",
            enumList: "NSTextAlignment",
            patch: true
        )
        dict[LookinAttr_UITextView_ContainerInset_Inset] = AttrInfo(
            className: "UITextView",
            fullTitle: "TextContainerInset",
            patch: true
        )
        dict[LookinAttr_UITextField_Font_Name] = AttrInfo(
            className: "UITextField",
            fullTitle: "FontName",
            getter: .lks_fontName,
            setterString: "",
            typeIfObj: LookinAttrType.NSString,
            patch: false
        )
        dict[LookinAttr_UITextField_Font_Size] = AttrInfo(
            className: "UITextField",
            fullTitle: "FontSize",
            getter: .lks_fontSize,
            setterString: "setLks_fontSize:",
            patch: true
        )
        dict[LookinAttr_UITextField_TextColor_Color] = AttrInfo(
            className: "UITextField",
            fullTitle: "TextColor",
            typeIfObj: LookinAttrType.UIColor,
            patch: true
        )
        dict[LookinAttr_UITextField_Alignment_Alignment] = AttrInfo(
            className: "UITextField",
            fullTitle: "TextAlignment",
            enumList: "NSTextAlignment",
            patch: true
        )
        dict[LookinAttr_UITextField_Text_Text] = AttrInfo(
            className: "UITextField",
            fullTitle: "Text",
            typeIfObj: LookinAttrType.NSString,
            patch: true
        )
        dict[LookinAttr_UITextField_Placeholder_Placeholder] = AttrInfo(
            className: "UITextField",
            fullTitle: "Placeholder",
            typeIfObj: LookinAttrType.NSString,
            patch: true
        )
        dict[LookinAttr_UITextField_Clears_ClearsOnBeginEditing] = AttrInfo(
            className: "UITextField",
            fullTitle: "ClearsOnBeginEditing",
            patch: false
        )
        dict[LookinAttr_UITextField_Clears_ClearsOnInsertion] = AttrInfo(
            className: "UITextField",
            fullTitle: "ClearsOnInsertion",
            patch: false
        )
        dict[LookinAttr_UITextField_CanAdjustFont_CanAdjustFont] = AttrInfo(
            className: "UITextField",
            fullTitle: "AdjustsFontSizeToFitWidth",
            patch: true
        )
        dict[LookinAttr_UITextField_CanAdjustFont_MinSize] = AttrInfo(
            className: "UITextField",
            fullTitle: "MinimumFontSize",
            patch: true
        )
        dict[LookinAttr_UITextField_ClearButtonMode_Mode] = AttrInfo(
            className: "UITextField",
            fullTitle: "ClearButtonMode",
            enumList: "UITextFieldViewMode",
            patch: false
        )
        return dict
    }()

    @objc(groupIDs)
    public class func groupIDs() -> [LookinAttrGroupIdentifier] { allGroupIDs }

    @objc(sectionIDsForGroupID:)
    public class func sectionIDs(forGroupID groupID: LookinAttrGroupIdentifier) -> [LookinAttrSectionIdentifier] {
        sectionsByGroup[groupID] ?? []
    }

    @objc(attrIDsForSectionID:)
    public class func attrIDs(forSectionID sectionID: LookinAttrSectionIdentifier) -> [LookinAttrIdentifier] {
        attrsBySection[sectionID] ?? []
    }

    @objc(getHostGroupID:sectionID:fromAttrID:)
    public class func getHostGroupID(
        _ groupID: AutoreleasingUnsafeMutablePointer<NSString?>?,
        sectionID: AutoreleasingUnsafeMutablePointer<NSString?>?,
        fromAttrID targetAttrID: LookinAttrIdentifier
    ) {
        var targetGroupID: LookinAttrGroupIdentifier?
        var targetSecID: LookinAttrSectionIdentifier?
        outer: for gid in allGroupIDs {
            for secID in sectionIDs(forGroupID: gid) {
                for attrID in attrIDs(forSectionID: secID) where attrID == targetAttrID {
                    targetGroupID = gid
                    targetSecID = secID
                    break outer
                }
            }
        }
        if let groupID, let targetGroupID { groupID.pointee = targetGroupID as NSString }
        if let sectionID, let targetSecID { sectionID.pointee = targetSecID as NSString }
    }

    @objc(groupTitleWithGroupID:)
    public class func groupTitle(withGroupID groupID: LookinAttrGroupIdentifier) -> String {
        let title = groupTitles[groupID]
        assert(title?.isEmpty == false)
        return title ?? ""
    }

    @objc(sectionTitleWithSectionID:)
    public class func sectionTitle(withSectionID secID: LookinAttrSectionIdentifier) -> String? {
        sectionTitles[secID]
    }

    private class func info(forAttrID attrID: LookinAttrIdentifier) -> AttrInfo? { attrInfos[attrID] }

    public class func objectAttrType(withAttrID attrID: LookinAttrIdentifier) -> LookinAttrType {
        info(forAttrID: attrID)?.typeIfObj ?? .none
    }

    @objc(classNameWithAttrID:)
    public class func className(withAttrID attrID: LookinAttrIdentifier) -> String? {
        let className = info(forAttrID: attrID)?.className
        assert(className?.isEmpty == false)
        return className
    }

    @objc(isUIViewPropertyWithAttrID:)
    public class func isUIViewProperty(withAttrID attrID: LookinAttrIdentifier) -> Bool {
        className(withAttrID: attrID) != "CALayer"
    }

    @objc(enumListNameWithAttrID:)
    public class func enumListName(withAttrID attrID: LookinAttrIdentifier) -> String? {
        info(forAttrID: attrID)?.enumList
    }

    @objc(needPatchAfterModificationWithAttrID:)
    public class func needPatchAfterModification(withAttrID attrID: LookinAttrIdentifier) -> Bool {
        info(forAttrID: attrID)?.patch ?? false
    }

    @objc(fullTitleWithAttrID:)
    public class func fullTitle(withAttrID attrID: LookinAttrIdentifier) -> String? {
        info(forAttrID: attrID)?.fullTitle
    }

    @objc(briefTitleWithAttrID:)
    public class func briefTitle(withAttrID attrID: LookinAttrIdentifier) -> String? {
        let info = info(forAttrID: attrID)
        if let brief = info?.briefTitle { return brief }
        return info?.fullTitle
    }

    @objc(getterWithAttrID:)
    public class func getter(withAttrID attrID: LookinAttrIdentifier) -> Selector? {
        guard let info = info(forAttrID: attrID) else { return nil }
        if let getter = info.getter {
            return getter.selector
        }
        guard let fullTitle = info.fullTitle, !fullTitle.isEmpty else { assertionFailure(); return nil }
        return NSSelectorFromString(fullTitle.prefix(1).lowercased() + fullTitle.dropFirst())
    }

    @objc(setterWithAttrID:)
    public class func setter(withAttrID attrID: LookinAttrIdentifier) -> Selector? {
        guard let info = info(forAttrID: attrID) else { return nil }
        if let setterString = info.setterString {
            if setterString.isEmpty { return nil }
            return NSSelectorFromString(setterString)
        }
        guard let fullTitle = info.fullTitle, !fullTitle.isEmpty else { assertionFailure(); return nil }
        return NSSelectorFromString("set" + fullTitle.prefix(1).uppercased() + fullTitle.dropFirst() + ":")
    }

    @objc(hideIfNilWithAttrID:)
    public class func hideIfNil(withAttrID attrID: LookinAttrIdentifier) -> Bool {
        info(forAttrID: attrID)?.hideIfNil ?? false
    }

    @objc(minAvailableOSVersionWithAttrID:)
    public class func minAvailableOSVersion(withAttrID attrID: LookinAttrIdentifier) -> Int {
        info(forAttrID: attrID)?.osVersion ?? 0
    }
}