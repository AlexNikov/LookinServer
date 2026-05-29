import Foundation

public let lookinServerVersion = 7
public let lookinServerReadableVersion = "1.2.8"
public let lookinClientVersion = 7
public let lookinSupportedServerMin = 7
public let lookinSupportedServerMax = 7
public let lookinServerVersionInt32: Int32 = 7
public let lookinStringFlagVoidReturn = "LOOKIN_TAG_RETURN_VALUE_VOID"

public let lookinErrorDomain = "LookinError"

@objc public enum LookinSharedErrCode: Int {
    case `default` = -400
    case inner = -401
    case peerTalk = -402
    case noConnect = -403
    case pingFailForTimeout = -404
    case timeout = -405
    case discard = -406
    case pingFailForBackgroundState = -407
    case objectNotFound = -500
    case modifyValueTypeInvalid = -501
    case exception = -502
    case serverVersionTooHigh = -600
    case serverVersionTooLow = -601
    case unsupportedFileType = -700
}

public func lookinInnerError() -> NSError {
    NSError(
        domain: lookinErrorDomain,
        code: LookinSharedErrCode.inner.rawValue,
        userInfo: [
            NSLocalizedDescriptionKey: NSLocalizedString(
                "The operation failed due to an inner error.",
                comment: ""
            ),
        ]
    )
}

public func lookinErrObjNotFound() -> NSError {
    NSError(
        domain: lookinErrorDomain,
        code: LookinSharedErrCode.objectNotFound.rawValue,
        userInfo: [
            NSLocalizedDescriptionKey: NSLocalizedString(
                "Failed to get target object in iOS app",
                comment: ""
            ),
            NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(
                "Perhaps the related object was deallocated. You can reload Lookin to get newest data.",
                comment: ""
            ),
        ]
    )
}

public func lookinErrorMake(title: String, detail: String = "") -> NSError {
    NSError(
        domain: lookinErrorDomain,
        code: LookinSharedErrCode.default.rawValue,
        userInfo: [
            NSLocalizedDescriptionKey: title,
            NSLocalizedRecoverySuggestionErrorKey: detail,
        ]
    )
}

public func lookinExceptionError(recoverySuggestion: String) -> NSError {
    NSError(
        domain: lookinErrorDomain,
        code: LookinSharedErrCode.exception.rawValue,
        userInfo: [
            NSLocalizedDescriptionKey: NSLocalizedString("The modification may failed.", comment: ""),
            NSLocalizedRecoverySuggestionErrorKey: recoverySuggestion,
        ]
    )
}
