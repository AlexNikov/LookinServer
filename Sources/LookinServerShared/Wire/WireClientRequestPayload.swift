import Foundation

/// Typed Peertalk request bodies for wire v2 (replaces untyped `NSDictionary` on the mac client).
public enum WireClientRequestPayload {
    case none
    case hierarchy(WireHierarchyRequestParams)
    case detailPackages([WireStaticAsyncUpdateTasksPackage])
    case patchTasks([WireStaticAsyncUpdateTask])
    case app(WireAppRequestParams)
    case oid(UInt)
    case selector(WireSelectorQueryParams)
    case invoke(WireInvokeParams)
    case recognizer(WireRecognizerParams)
    case inbuilt(LookinAttributeModification)
    case custom(LookinCustomAttrModification)

    /// Builds a `WireRequestEnvelope` for the given request type and tag.
    public func envelope(requestType: UInt32, tag: UInt32) -> WireRequestEnvelope {
        WireRequestResponseMapper.requestEnvelope(
            requestType: requestType,
            tag: tag,
            payload: self
        )
    }
}

extension WireRequestResponseMapper {
    public static func requestEnvelope(
        requestType: UInt32,
        tag: UInt32,
        payload: WireClientRequestPayload
    ) -> WireRequestEnvelope {
        switch payload {
        case .none:
            return WireRequestEnvelope(requestType: requestType, tag: tag)
        case .hierarchy(let params):
            return WireRequestEnvelope(
                requestType: requestType,
                tag: tag,
                hierarchyParams: params
            )
        case .detailPackages(let packages):
            return WireRequestEnvelope(
                requestType: requestType,
                tag: tag,
                detailPackages: packages
            )
        case .patchTasks(let tasks):
            return WireRequestEnvelope(
                requestType: requestType,
                tag: tag,
                patchTasks: tasks
            )
        case .app(let params):
            return WireRequestEnvelope(
                requestType: requestType,
                tag: tag,
                appParams: params
            )
        case .oid(let oid):
            return WireRequestEnvelope(requestType: requestType, tag: tag, oid: oid)
        case .selector(let query):
            return WireRequestEnvelope(
                requestType: requestType,
                tag: tag,
                selectorQuery: query
            )
        case .invoke(let params):
            return WireRequestEnvelope(
                requestType: requestType,
                tag: tag,
                invokeParams: params
            )
        case .recognizer(let params):
            return WireRequestEnvelope(
                requestType: requestType,
                tag: tag,
                recognizerParams: params
            )
        case .inbuilt(let modification):
            return WireRequestEnvelope(
                requestType: requestType,
                tag: tag,
                inbuiltModification: wireModification(from: modification)
            )
        case .custom(let modification):
            return WireRequestEnvelope(
                requestType: requestType,
                tag: tag,
                customModification: wireCustomModification(from: modification)
            )
        }
    }
}
