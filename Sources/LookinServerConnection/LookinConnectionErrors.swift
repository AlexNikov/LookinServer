#if SHOULD_COMPILE_LOOKIN_SERVER

import Foundation

public enum LookinConnectionError: Error {
    case inner
    case objectNotFound
    case custom(title: String, detail: String = "")
}

extension LookinConnectionError {
    var nsError: NSError {
        switch self {
        case .inner:
            return NSError(
                domain: LookinErrorDomain,
                code: Int(LookinErrCode_Inner),
                userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("The operation failed due to an inner error.", comment: "")]
            )
        case .objectNotFound:
            return NSError(
                domain: LookinErrorDomain,
                code: Int(LookinErrCode_ObjectNotFound),
                userInfo: [
                    NSLocalizedDescriptionKey: NSLocalizedString("Failed to get target object in iOS app", comment: ""),
                    NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString("Perhaps the related object was deallocated. You can reload Lookin to get newest data.", comment: ""),
                ]
            )
        case .custom(let title, let detail):
            return NSError(
                domain: LookinErrorDomain,
                code: Int(LookinErrCode_Default),
                userInfo: [
                    NSLocalizedDescriptionKey: title,
                    NSLocalizedRecoverySuggestionErrorKey: detail,
                ]
            )
        }
    }
}

enum LookinConnectionErrors {
    static var inner: NSError { LookinConnectionError.inner.nsError }
    static var objectNotFound: NSError { LookinConnectionError.objectNotFound.nsError }
    static func make(title: String, detail: String = "") -> NSError {
        LookinConnectionError.custom(title: title, detail: detail).nsError
    }
}

#endif
