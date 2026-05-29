import Foundation

public enum LookinEventHandlerType: Int {
    case targetAction = 0
    case gesture = 1
}

public class LookinEventHandler: NSObject, NSCopying {
    public var handlerType: LookinEventHandlerType = .targetAction
    public var eventName: String?
    public var targetActions: [LookinStringTwoTuple]?
    public var inheritedRecognizerName: String?
    public var gestureRecognizerIsEnabled: Bool = false
    public var gestureRecognizerDelegator: String?
    public var recognizerIvarTraces: [String]?
    public var recognizerOid: UInt64 = 0

    public override init() {
        super.init()
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = LookinEventHandler()
        copy.handlerType = handlerType
        copy.eventName = eventName
        copy.targetActions = targetActions?.lookin_map { _, value in value.copy() as? LookinStringTwoTuple }
        copy.gestureRecognizerIsEnabled = gestureRecognizerIsEnabled
        copy.gestureRecognizerDelegator = gestureRecognizerDelegator
        copy.inheritedRecognizerName = inheritedRecognizerName
        copy.recognizerIvarTraces = recognizerIvarTraces
        copy.recognizerOid = recognizerOid
        return copy
    }

}
