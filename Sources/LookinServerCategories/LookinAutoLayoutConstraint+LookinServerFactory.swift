#if os(iOS) || os(tvOS) || os(visionOS)
import UIKit
#if canImport(LookinShared)
import LookinShared
#endif

extension LookinAutoLayoutConstraint {
    @objc(instanceFromNSConstraint:isEffective:firstItemType:secondItemType:)
    public class func instance(
        fromNSConstraint constraint: NSLayoutConstraint,
        isEffective: Bool,
        firstItemType: LookinConstraintItemType,
        secondItemType: LookinConstraintItemType
    ) -> LookinAutoLayoutConstraint {
        let instance = LookinAutoLayoutConstraint()
        instance.effective = isEffective
        instance.active = constraint.isActive
        instance.shouldBeArchived = constraint.shouldBeArchived
        if let firstObject = constraint.firstItem as? NSObject {
            instance.firstItem = LookinObject.instance(with: firstObject)
        }
        instance.firstItemType = firstItemType
        instance.firstAttribute = constraint.firstAttribute.rawValue
        instance.relation = constraint.relation
        if let secondObject = constraint.secondItem as? NSObject {
            instance.secondItem = LookinObject.instance(with: secondObject)
        }
        instance.secondItemType = secondItemType
        instance.secondAttribute = constraint.secondAttribute.rawValue
        instance.multiplier = constraint.multiplier
        instance.constant = constraint.constant
        instance.priority = CGFloat(constraint.priority.rawValue)
        instance.identifier = constraint.identifier
        return instance
    }
}
#endif
