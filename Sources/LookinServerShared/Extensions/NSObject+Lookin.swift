import Foundation
import ObjectiveC
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

private final class LookinWeakBox: NSObject {
    weak var object: AnyObject?
}

extension NSObject {
    private static var bindObjectsKey: UInt8 = 0

    private var lookin_allBindObjects: NSMutableDictionary {
        if let dict = objc_getAssociatedObject(self, &Self.bindObjectsKey) as? NSMutableDictionary {
            return dict
        }
        let dict = NSMutableDictionary()
        objc_setAssociatedObject(self, &Self.bindObjectsKey, dict, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return dict
    }

    @objc(lookin_bindObject:forKey:)
    public func lookin_bindObject(_ object: Any?, forKey key: String) {
        guard !key.isEmpty else { return }
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        if let object {
            lookin_allBindObjects[key] = object
        } else {
            lookin_allBindObjects.removeObject(forKey: key)
        }
    }

    @objc(lookin_bindObjectWeakly:forKey:)
    public func lookin_bindObjectWeakly(_ object: AnyObject?, forKey key: String) {
        guard !key.isEmpty else { return }
        if let object {
            let box = LookinWeakBox()
            box.object = object
            lookin_bindObject(box, forKey: key)
        } else {
            lookin_bindObject(nil, forKey: key)
        }
    }

    @objc(lookin_getBindObjectForKey:)
    public func lookin_getBindObject(forKey key: String) -> Any? {
        guard !key.isEmpty else { return nil }
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        let stored = lookin_allBindObjects[key]
        if let box = stored as? LookinWeakBox {
            return box.object
        }
        return stored
    }

    @objc(lookin_clearBindForKey:)
    public func lookin_clearBind(forKey key: String) {
        lookin_bindObject(nil, forKey: key)
    }

    @objc(lookin_bindDouble:forKey:)
    public func lookin_bindDouble(_ doubleValue: Double, forKey key: String) {
        lookin_bindObject(NSNumber(value: doubleValue), forKey: key)
    }

    @objc(lookin_getBindDoubleForKey:)
    public func lookin_getBindDouble(forKey key: String) -> Double {
        (lookin_getBindObject(forKey: key) as? NSNumber)?.doubleValue ?? 0
    }

    @objc(lookin_bindBOOL:forKey:)
    public func lookin_bindBOOL(_ boolValue: Bool, forKey key: String) {
        lookin_bindObject(NSNumber(value: boolValue), forKey: key)
    }

    @objc(lookin_getBindBOOLForKey:)
    public func lookin_getBindBOOL(forKey key: String) -> Bool {
        (lookin_getBindObject(forKey: key) as? NSNumber)?.boolValue ?? false
    }

    @objc(lookin_bindLong:forKey:)
    public func lookin_bindLong(_ longValue: Int, forKey key: String) {
        lookin_bindObject(NSNumber(value: longValue), forKey: key)
    }

    @objc(lookin_getBindLongForKey:)
    public func lookin_getBindLong(forKey key: String) -> Int {
        (lookin_getBindObject(forKey: key) as? NSNumber)?.intValue ?? 0
    }

    @objc(lookin_bindPoint:forKey:)
    public func lookin_bindPoint(_ pointValue: CGPoint, forKey key: String) {
        lookin_bindObject(LookinGeometryCoding.nsValue(from: pointValue), forKey: key)
    }

    @objc(lookin_getBindPointForKey:)
    public func lookin_getBindPoint(forKey key: String) -> CGPoint {
        guard let value = lookin_getBindObject(forKey: key) as? NSValue else { return .zero }
        return LookinGeometryCoding.point(from: value)
    }

    public func lookin_encodedObject(with type: LookinCodingValueType) -> Any? {
        switch type {
        case .color:
            guard let color = self as? LookinColor else { return nil }
            return color.lookin_rgbaComponents
        case .image:
            if let image = self as? LookinImage {
                return image.lookin_pngData()
            }
            return nil
        default:
            return self
        }
    }

    public func lookin_decodedObject(with type: LookinCodingValueType) -> Any? {
        switch type {
        case .color:
            if let rgba = self as? [NSNumber] {
                return LookinColor.lookin_color(fromRGBAComponents: rgba)
            }
            return nil
        case .image:
            if let data = self as? Data {
                return LookinImage.lookin_image(with: data)
            }
            return nil
        default:
            return self
        }
    }
}
