#if canImport(LookinShared)
import LookinShared
#endif
#if SHOULD_COMPILE_LOOKIN_SERVER

import Foundation
import UIKit

public typealias LKS_StringSetter = @convention(block) (String) -> Void
public typealias LKS_NumberSetter = @convention(block) (NSNumber) -> Void
public typealias LKS_BoolSetter = @convention(block) (Bool) -> Void
public typealias LKS_ColorSetter = @convention(block) (UIColor?) -> Void
public typealias LKS_EnumSetter = @convention(block) (String) -> Void
public typealias LKS_RectSetter = @convention(block) (CGRect) -> Void
public typealias LKS_SizeSetter = @convention(block) (CGSize) -> Void
public typealias LKS_PointSetter = @convention(block) (CGPoint) -> Void
public typealias LKS_InsetsSetter = @convention(block) (UIEdgeInsets) -> Void

@objc(LKS_CustomAttrSetterManager)
public final class LKS_CustomAttrSetterManager: NSObject {

    @objc(sharedInstance)
    public class func sharedInstance() -> LKS_CustomAttrSetterManager {
        SingletonStorage.instance
    }

    private enum SingletonStorage {
        static let instance = LKS_CustomAttrSetterManager()
    }

    private var settersMap: [String: Any] = [:]

    private override init() {
        super.init()
    }

    @objc(removeAll)
    public func removeAll() {
        settersMap.removeAll()
    }

    @objc(saveSetter:uniqueID:)
    public func saveSetter(_ setter: Any, uniqueID: String) {
        settersMap[uniqueID] = setter
    }

    @objc(saveStringSetter:uniqueID:)
    public func saveStringSetter(_ setter: LKS_StringSetter?, uniqueID: String) {
        guard let setter else { return }
        settersMap[uniqueID] = setter
    }

    @objc(getStringSetterWithID:)
    public func getStringSetter(withID uniqueID: String) -> LKS_StringSetter? {
        settersMap[uniqueID] as? LKS_StringSetter
    }

    @objc(saveNumberSetter:uniqueID:)
    public func saveNumberSetter(_ setter: LKS_NumberSetter?, uniqueID: String) {
        guard let setter else { return }
        settersMap[uniqueID] = setter
    }

    @objc(getNumberSetterWithID:)
    public func getNumberSetter(withID uniqueID: String) -> LKS_NumberSetter? {
        settersMap[uniqueID] as? LKS_NumberSetter
    }

    @objc(saveBoolSetter:uniqueID:)
    public func saveBoolSetter(_ setter: LKS_BoolSetter?, uniqueID: String) {
        guard let setter else { return }
        settersMap[uniqueID] = setter
    }

    @objc(getBoolSetterWithID:)
    public func getBoolSetter(withID uniqueID: String) -> LKS_BoolSetter? {
        settersMap[uniqueID] as? LKS_BoolSetter
    }

    @objc(saveColorSetter:uniqueID:)
    public func saveColorSetter(_ setter: LKS_ColorSetter?, uniqueID: String) {
        guard let setter else { return }
        settersMap[uniqueID] = setter
    }

    @objc(getColorSetterWithID:)
    public func getColorSetter(withID uniqueID: String) -> LKS_ColorSetter? {
        settersMap[uniqueID] as? LKS_ColorSetter
    }

    @objc(saveEnumSetter:uniqueID:)
    public func saveEnumSetter(_ setter: LKS_EnumSetter?, uniqueID: String) {
        guard let setter else { return }
        settersMap[uniqueID] = setter
    }

    @objc(getEnumSetterWithID:)
    public func getEnumSetter(withID uniqueID: String) -> LKS_EnumSetter? {
        settersMap[uniqueID] as? LKS_EnumSetter
    }

    @objc(saveRectSetter:uniqueID:)
    public func saveRectSetter(_ setter: LKS_RectSetter?, uniqueID: String) {
        guard let setter else { return }
        settersMap[uniqueID] = setter
    }

    @objc(getRectSetterWithID:)
    public func getRectSetter(withID uniqueID: String) -> LKS_RectSetter? {
        settersMap[uniqueID] as? LKS_RectSetter
    }

    @objc(saveSizeSetter:uniqueID:)
    public func saveSizeSetter(_ setter: LKS_SizeSetter?, uniqueID: String) {
        guard let setter else { return }
        settersMap[uniqueID] = setter
    }

    @objc(getSizeSetterWithID:)
    public func getSizeSetter(withID uniqueID: String) -> LKS_SizeSetter? {
        settersMap[uniqueID] as? LKS_SizeSetter
    }

    @objc(savePointSetter:uniqueID:)
    public func savePointSetter(_ setter: LKS_PointSetter?, uniqueID: String) {
        guard let setter else { return }
        settersMap[uniqueID] = setter
    }

    @objc(getPointSetterWithID:)
    public func getPointSetter(withID uniqueID: String) -> LKS_PointSetter? {
        settersMap[uniqueID] as? LKS_PointSetter
    }

    @objc(saveInsetsSetter:uniqueID:)
    public func saveInsetsSetter(_ setter: LKS_InsetsSetter?, uniqueID: String) {
        guard let setter else { return }
        settersMap[uniqueID] = setter
    }

    @objc(getInsetsSetterWithID:)
    public func getInsetsSetter(withID uniqueID: String) -> LKS_InsetsSetter? {
        settersMap[uniqueID] as? LKS_InsetsSetter
    }
}

#endif
