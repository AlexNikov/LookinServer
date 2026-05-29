import Foundation

public final class LookinCustomDisplayItemInfo: NSObject, NSCopying {
    public var frameInWindow: NSValue?
    public var title: String?
    public var subtitle: String?
    public var danceuiSource: String?

    public override init() {
        super.init()
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = LookinCustomDisplayItemInfo()
        if let frameInWindow {
            copy.frameInWindow = LookinGeometryCoding.nsValue(from: LookinGeometryCoding.rect(from: frameInWindow))
        }
        copy.title = title
        copy.subtitle = subtitle
        copy.danceuiSource = danceuiSource
        return copy
    }
}
