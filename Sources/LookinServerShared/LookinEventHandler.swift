import Foundation

public enum LookinEventHandlerType: Int {
    case targetAction = 0
    case gesture = 1
}

public struct LookinEventHandler {
    public var handlerType: LookinEventHandlerType = .targetAction
    public var eventName: String?
    public var targetActions: [LookinStringTwoTuple]?
    public var inheritedRecognizerName: String?
    public var gestureRecognizerIsEnabled: Bool = false
    public var gestureRecognizerDelegator: String?
    public var recognizerIvarTraces: [String]?
    public var recognizerOid: UInt64 = 0

    public init() {}
}
