import Foundation
#if canImport(LookinServerShared)
import LookinServerShared
#endif
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@objc public enum LookinConstraintItemType: Int {
    case unknown = 0
    case `nil` = 1
    case view = 2
    case `self` = 3
    case `super` = 4
    case layoutGuide = 5
}

@objc(LookinAutoLayoutConstraint)
public class LookinAutoLayoutConstraint: NSObject {
    @objc public var effective: Bool = false
    @objc public var active: Bool = false
    @objc public var shouldBeArchived: Bool = false
    @objc public var firstItem: LookinObject?
    @objc public var firstItemType: LookinConstraintItemType = .unknown
    @objc public var firstAttribute: Int = 0 {
        didSet { assertUnknownAttribute(firstAttribute) }
    }
    @objc public var relation: NSLayoutConstraint.Relation = .equal
    @objc public var secondItem: LookinObject?
    @objc public var secondItemType: LookinConstraintItemType = .unknown
    @objc public var secondAttribute: Int = 0 {
        didSet { assertUnknownAttribute(secondAttribute) }
    }
    @objc public var multiplier: CGFloat = 0
    @objc public var constant: CGFloat = 0
    @objc public var priority: CGFloat = 0
    @objc public var identifier: String?

    public override init() {
        super.init()
    }

    #if os(iOS) || os(tvOS) || os(visionOS)
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
    #endif

    private func assertUnknownAttribute(_ attribute: Int) {
        if attribute > 20 && attribute < 32 {
            assertionFailure()
        }
        if attribute > 37 {
            assertionFailure()
        }
    }
}
