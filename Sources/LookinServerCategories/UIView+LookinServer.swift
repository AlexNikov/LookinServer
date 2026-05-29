#if SHOULD_COMPILE_LOOKIN_SERVER

import UIKit

extension UIView {
    @objc(lks_findHostViewController)
    public func lks_findHostViewController() -> UIViewController? {
        guard let responder = next, let viewController = responder as? UIViewController else { return nil }
        guard viewController.view === self else { return nil }
        return viewController
    }

    @objc(lks_subviewAtPoint:preferredClasses:)
    public func lks_subview(at point: CGPoint, preferredClasses: [AnyClass]) -> UIView {
        let isPreferredClassForSelf = (preferredClasses as NSArray).lookin_any { obj in
            guard let cls = obj as? AnyClass else { return false }
            return isKind(of: cls)
        }
        if isPreferredClassForSelf {
            return self
        }

        var targetView = (subviews as NSArray).lookin_lastFiltered { obj in
            guard let view = obj as? UIView else { return false }
            if view.isHidden || view.alpha <= 0.01 { return false }
            return view.frame.contains(point)
        } as? UIView

        if targetView == nil {
            return self
        }

        let newPoint = targetView!.convert(point, from: self)
        targetView = targetView!.lks_subview(at: newPoint, preferredClasses: preferredClasses)
        return targetView!
    }

    @objc(lks_bestSize)
    public func lks_bestSize() -> CGSize {
        sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
    }

    @objc(lks_bestWidth)
    public func lks_bestWidth() -> CGFloat {
        lks_bestSize().width
    }

    @objc(lks_bestHeight)
    public func lks_bestHeight() -> CGFloat {
        lks_bestSize().height
    }

    @objc public var lks_isChildrenViewOfTabBar: Bool {
        get { lookin_getBindBOOL(forKey: "lks_isChildrenViewOfTabBar") }
        set { lookin_bindBOOL(newValue, forKey: "lks_isChildrenViewOfTabBar") }
    }

    /// Returns false when any clipsToBounds ancestor clips this view out of its visible bounds
    /// (e.g. a UIScrollView cell that is outside the current contentOffset viewport).
    /// CALayer.render(in:) should be used instead of drawHierarchy in that case.
    var lks_isVisibleInClipHierarchy: Bool {
        var current: UIView = self
        while let superview = current.superview {
            if superview.clipsToBounds || superview is UIScrollView {
                let frameInSuperview = current.convert(current.bounds, to: superview)
                if !superview.bounds.intersects(frameInSuperview) {
                    return false
                }
            }
            current = superview
        }
        return true
    }

    @objc var lks_verticalContentHuggingPriority: Float {
        get { contentHuggingPriority(for: .vertical).rawValue }
        set { setContentHuggingPriority(UILayoutPriority(rawValue: newValue), for: .vertical) }
    }

    @objc var lks_horizontalContentHuggingPriority: Float {
        get { contentHuggingPriority(for: .horizontal).rawValue }
        set { setContentHuggingPriority(UILayoutPriority(rawValue: newValue), for: .horizontal) }
    }

    @objc var lks_verticalContentCompressionResistancePriority: Float {
        get { contentCompressionResistancePriority(for: .vertical).rawValue }
        set { setContentCompressionResistancePriority(UILayoutPriority(rawValue: newValue), for: .vertical) }
    }

    @objc var lks_horizontalContentCompressionResistancePriority: Float {
        get { contentCompressionResistancePriority(for: .horizontal).rawValue }
        set { setContentCompressionResistancePriority(UILayoutPriority(rawValue: newValue), for: .horizontal) }
    }

    @objc(lks_rebuildGlobalInvolvedRawConstraints)
    public static func lks_rebuildGlobalInvolvedRawConstraints() {
        let windows = LKS_MultiplatformAdapter.allWindows() as? [UIWindow] ?? []
        for window in windows {
            lks_removeInvolvedRawConstraints(forViewsRootedBy: window)
        }
        for window in windows {
            lks_addInvolvedRawConstraints(forViewsRootedBy: window)
        }
    }

    @objc(lks_addInvolvedRawConstraintsForViewsRootedByView:)
    public static func lks_addInvolvedRawConstraints(forViewsRootedBy rootView: UIView) {
        for constraint in rootView.constraints {
            if let firstView = constraint.firstItem as? UIView,
               !(firstView.lks_involvedRawConstraints?.contains(constraint) ?? false) {
                if firstView.lks_involvedRawConstraints == nil {
                    firstView.lks_involvedRawConstraints = NSMutableArray()
                }
                firstView.lks_involvedRawConstraints?.add(constraint)
            }
            if let secondView = constraint.secondItem as? UIView,
               !(secondView.lks_involvedRawConstraints?.contains(constraint) ?? false) {
                if secondView.lks_involvedRawConstraints == nil {
                    secondView.lks_involvedRawConstraints = NSMutableArray()
                }
                secondView.lks_involvedRawConstraints?.add(constraint)
            }
        }
        for subview in rootView.subviews {
            lks_addInvolvedRawConstraints(forViewsRootedBy: subview)
        }
    }

    @objc(lks_removeInvolvedRawConstraintsForViewsRootedByView:)
    public static func lks_removeInvolvedRawConstraints(forViewsRootedBy rootView: UIView) {
        rootView.lks_involvedRawConstraints?.removeAllObjects()
        for subview in rootView.subviews {
            lks_removeInvolvedRawConstraints(forViewsRootedBy: subview)
        }
    }

    @objc var lks_involvedRawConstraints: NSMutableArray? {
        get { lookin_getBindObject(forKey: "lks_involvedRawConstraints") as? NSMutableArray }
        set { lookin_bindObject(newValue, forKey: "lks_involvedRawConstraints") }
    }

    @objc(lks_constraints)
    public func lks_constraints() -> [LookinAutoLayoutConstraint]? {
        var effectiveConstraints = NSMutableArray()
        effectiveConstraints.addObjects(from: constraintsAffectingLayout(for: .horizontal))
        effectiveConstraints.addObjects(from: constraintsAffectingLayout(for: .vertical))

        let involved = lks_involvedRawConstraints as? [NSLayoutConstraint] ?? []
        let lookinConstraints = (involved as NSArray).lookin_map { _, value in
            guard let constraint = value as? NSLayoutConstraint, constraint.isActive else { return nil }
            let isEffective = effectiveConstraints.contains(constraint)
            let firstItemType = self.lks_constraintItemType(for: constraint.firstItem)
            let secondItemType = self.lks_constraintItemType(for: constraint.secondItem)
            return LookinAutoLayoutConstraint.instance(
                fromNSConstraint: constraint,
                isEffective: isEffective,
                firstItemType: firstItemType,
                secondItemType: secondItemType
            )
        } as? [LookinAutoLayoutConstraint] ?? []

        return lookinConstraints.isEmpty ? nil : lookinConstraints
    }

    private func lks_constraintItemType(for item: Any?) -> LookinConstraintItemType {
        guard let item else { return .nil }
        if (item as AnyObject) === self { return .self }
        if let superview, (item as AnyObject) === superview { return .super }

        if item is UILayoutGuide {
            return .layoutGuide
        }

        let className = NSStringFromClass(type(of: item as AnyObject))
        if className.hasSuffix("_UILayoutGuide") {
            return .layoutGuide
        }

        if item is UIView {
            return .view
        }

        assertionFailure()
        return .unknown
    }

    @objc(lks_accessibilityTraitsDescription)
    public func lks_accessibilityTraitsDescription() -> String? {
        let traits = accessibilityTraits
        if traits.isEmpty { return nil }

        var names: [String] = []
        let mapping: [(UIAccessibilityTraits, String)] = [
            (.button, "button"),
            (.link, "link"),
            (.image, "image"),
            (.selected, "selected"),
            (.playsSound, "playsSound"),
            (.keyboardKey, "keyboardKey"),
            (.staticText, "staticText"),
            (.summaryElement, "summaryElement"),
            (.notEnabled, "notEnabled"),
            (.updatesFrequently, "updatesFrequently"),
            (.searchField, "searchField"),
            (.startsMediaSession, "startsMediaSession"),
            (.adjustable, "adjustable"),
            (.allowsDirectInteraction, "allowsDirectInteraction"),
            (.causesPageTurn, "causesPageTurn"),
            (.header, "header"),
            (.tabBar, "tabBar"),
        ]
        for (trait, name) in mapping where traits.contains(trait) {
            names.append(name)
        }
        return names.isEmpty ? nil : names.joined(separator: ", ")
    }
}

#endif
