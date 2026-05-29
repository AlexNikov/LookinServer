import Foundation

@_silgen_name("LookinCatchObjCException")
private func lookinCatchObjCException(
    _ tryBlock: (@convention(block) () -> Void)?,
    _ exceptionOut: UnsafeMutablePointer<NSException?>?
)

/// Swift API for ObjC `@try/@catch` around inspect paths that may raise `NSException`.
public enum LookinObjCExceptionBridge {

    /// Runs `body` and returns a caught `NSException`, if any.
    public static func catchException(_ body: @escaping () -> Void) -> NSException? {
        var exception: NSException?
        lookinCatchObjCException(body, &exception)
        return exception
    }

    /// Runs `body`; on `NSException` throws `NSError` in `LookinErrorDomain` with code -502.
    public static func tryExecute(_ body: @escaping () -> Void) throws {
        guard let exception = catchException(body) else { return }
        throw lookinObjCExceptionError(reason: exception.reason)
    }

    private static func lookinObjCExceptionError(reason: String?) -> NSError {
        NSError(
            domain: LookinErrorDomain,
            code: LookinSharedErrCode.exception.rawValue,
            userInfo: [
                NSLocalizedDescriptionKey: NSLocalizedString("The modification may failed.", comment: ""),
                NSLocalizedRecoverySuggestionErrorKey: reason ?? "",
            ]
        )
    }
}
