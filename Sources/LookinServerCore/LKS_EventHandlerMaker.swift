#if canImport(LookinShared)
import LookinShared
#endif
#if SHOULD_COMPILE_LOOKIN_SERVER

import Foundation
import UIKit

@objc(LKS_EventHandlerMaker)
public final class LKS_EventHandlerMaker: NSObject {

    public static func make(for view: UIView?) -> [LookinEventHandler]? {
        guard let view else { return nil }

        var allHandlers: [LookinEventHandler]?

        if let control = view as? UIControl {
            if let targetActionHandlers = _targetActionHandlers(for: control), !targetActionHandlers.isEmpty {
                allHandlers = targetActionHandlers
            }
        }

        if let gestureHandlers = _gestureHandlers(for: view), !gestureHandlers.isEmpty {
            if allHandlers != nil {
                allHandlers?.append(contentsOf: gestureHandlers)
            } else {
                allHandlers = gestureHandlers
            }
        }

        return allHandlers
    }

    private static func _gestureHandlers(for view: UIView) -> [LookinEventHandler]? {
        guard let recognizers = view.gestureRecognizers, !recognizers.isEmpty else {
            return nil
        }

        let handlers: [LookinEventHandler] = recognizers.lookin_map { _, recognizer in
            var handler = LookinEventHandler()
            handler.handlerType = LookinEventHandlerType.gesture
            handler.eventName = NSStringFromClass(type(of: recognizer))

            let targetActionInfos = LKS_GestureTargetActionsSearcher.getTargetActions(from: recognizer)
            handler.targetActions = targetActionInfos.lookin_map { _, rawTuple in
                guard let tuple = rawTuple as? LookinTwoTuple,
                      let container = tuple.first as? LookinWeakContainer,
                      let target = container.object else {
                    return nil
                }
                var newTuple = LookinStringTwoTuple()
                newTuple.first = LKS_Helper.description(of: target)
                newTuple.second = tuple.second as? String
                return newTuple
            }
            handler.inheritedRecognizerName = _inheritedRecognizerName(for: recognizer)
            handler.gestureRecognizerIsEnabled = recognizer.isEnabled
            if let delegate = recognizer.delegate {
                handler.gestureRecognizerDelegator = LKS_Helper.description(of: delegate)
            }
            handler.recognizerIvarTraces = (recognizer as NSObject).lks_ivarTraces?.map {
                "(\($0.hostClassName ?? "")) -> \($0.ivarName ?? "")"
            }
            handler.recognizerOid = UInt64((recognizer as NSObject).lks_registerOid())
            return handler
        }
        return handlers
    }

    private static func _inheritedRecognizerName(for recognizer: UIGestureRecognizer?) -> String? {
        guard let recognizer else {
            assertionFailure()
            return nil
        }

        struct Static {
            static let baseRecognizers: [AnyClass] = {
                #if os(tvOS)
                return [
                    UILongPressGestureRecognizer.self,
                    UIPanGestureRecognizer.self,
                    UISwipeGestureRecognizer.self,
                    UITapGestureRecognizer.self,
                ]
                #elseif os(visionOS)
                return [
                    UILongPressGestureRecognizer.self,
                    UIPanGestureRecognizer.self,
                    UISwipeGestureRecognizer.self,
                    UIRotationGestureRecognizer.self,
                    UIPinchGestureRecognizer.self,
                    UITapGestureRecognizer.self,
                ]
                #else
                return [
                    UILongPressGestureRecognizer.self,
                    UIScreenEdgePanGestureRecognizer.self,
                    UIPanGestureRecognizer.self,
                    UISwipeGestureRecognizer.self,
                    UIRotationGestureRecognizer.self,
                    UIPinchGestureRecognizer.self,
                    UITapGestureRecognizer.self,
                ]
                #endif
            }()
        }

        var result: String? = "UIGestureRecognizer"
        for baseClass in Static.baseRecognizers {
            if type(of: recognizer) == baseClass {
                result = nil
                break
            }
            if recognizer.isKind(of: baseClass) {
                result = NSStringFromClass(baseClass)
                break
            }
        }
        return result
    }

    private static func _targetActionHandlers(for control: UIControl) -> [LookinEventHandler]? {
        struct Static {
            static let allEvents: [UIControl.Event] = {
                return [
                    .touchDown, .touchDownRepeat, .touchDragInside, .touchDragOutside,
                    .touchDragEnter, .touchDragExit, .touchUpInside, .touchUpOutside,
                    .touchCancel, .valueChanged, .editingDidBegin, .editingChanged,
                    .editingDidEnd, .editingDidEndOnExit, .primaryActionTriggered,
                ]
            }()
        }

        let allTargets = control.allTargets
        guard !allTargets.isEmpty else { return nil }

        var handlers: [LookinEventHandler] = []

        for event in Static.allEvents {
            var targetActions: [LookinStringTwoTuple] = []

            for target in allTargets {
                guard let actions = control.actions(forTarget: target, forControlEvent: event) else { continue }
                for action in actions {
                    var tuple = LookinStringTwoTuple()
                    tuple.first = LKS_Helper.description(of: target)
                    tuple.second = action
                    targetActions.append(tuple)
                }
            }

            if !targetActions.isEmpty {
                var handler = LookinEventHandler()
                handler.handlerType = LookinEventHandlerType.targetAction
                handler.eventName = _name(from: event)
                handler.targetActions = targetActions
                handlers.append(handler)
            }
        }

        return handlers
    }

    private static func _name(from event: UIControl.Event) -> String? {
        struct Static {
            static let eventsAndNames: [UIControl.Event.RawValue: String] = {
                var map: [UIControl.Event.RawValue: String] = [
                    UIControl.Event.touchDown.rawValue: "UIControlEventTouchDown",
                    UIControl.Event.touchDownRepeat.rawValue: "UIControlEventTouchDownRepeat",
                    UIControl.Event.touchDragInside.rawValue: "UIControlEventTouchDragInside",
                    UIControl.Event.touchDragOutside.rawValue: "UIControlEventTouchDragOutside",
                    UIControl.Event.touchDragEnter.rawValue: "UIControlEventTouchDragEnter",
                    UIControl.Event.touchDragExit.rawValue: "UIControlEventTouchDragExit",
                    UIControl.Event.touchUpInside.rawValue: "UIControlEventTouchUpInside",
                    UIControl.Event.touchUpOutside.rawValue: "UIControlEventTouchUpOutside",
                    UIControl.Event.touchCancel.rawValue: "UIControlEventTouchCancel",
                    UIControl.Event.valueChanged.rawValue: "UIControlEventValueChanged",
                    UIControl.Event.editingDidBegin.rawValue: "UIControlEventEditingDidBegin",
                    UIControl.Event.editingChanged.rawValue: "UIControlEventEditingChanged",
                    UIControl.Event.editingDidEnd.rawValue: "UIControlEventEditingDidEnd",
                    UIControl.Event.editingDidEndOnExit.rawValue: "UIControlEventEditingDidEndOnExit",
                    UIControl.Event.primaryActionTriggered.rawValue: "UIControlEventPrimaryActionTriggered",
                ]
                return map
            }()
        }
        return Static.eventsAndNames[event.rawValue]
    }
}

#endif
