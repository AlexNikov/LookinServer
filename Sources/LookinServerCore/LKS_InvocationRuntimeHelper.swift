#if SHOULD_COMPILE_LOOKIN_SERVER

import Foundation
import UIKit

// MARK: - Type encodings (runtime probe; NSInvocation is unavailable in Swift)

private final class _LookinInvocationTypeEncodingProbe: NSObject {
    @objc func probeVoid() {}
    @objc func probeChar() -> CChar { 0 }
    @objc func probeInt() -> Int32 { 0 }
    @objc func probeShort() -> Int16 { 0 }
    @objc func probeLong() -> Int { 0 }
    @objc func probeLongLong() -> Int64 { 0 }
    @objc func probeUnsignedChar() -> UInt8 { 0 }
    @objc func probeUnsignedInt() -> UInt32 { 0 }
    @objc func probeUnsignedShort() -> UInt16 { 0 }
    @objc func probeUnsignedLong() -> UInt { 0 }
    @objc func probeUnsignedLongLong() -> UInt64 { 0 }
    @objc func probeFloat() -> Float { 0 }
    @objc func probeDouble() -> Double { 0 }
    @objc func probeBOOL() -> Bool { false }
    @objc func probeSEL() -> Selector { NSSelectorFromString("") }
    @objc func probeClass() -> AnyClass { NSObject.self }
    @objc func probeCGPoint() -> CGPoint { .zero }
    @objc func probeCGVector() -> CGVector { .zero }
    @objc func probeCGSize() -> CGSize { .zero }
    @objc func probeCGRect() -> CGRect { .zero }
    @objc func probeCGAffineTransform() -> CGAffineTransform { .identity }
    @objc func probeUIEdgeInsets() -> UIEdgeInsets { .zero }
    @objc func probeUIOffset() -> UIOffset { .zero }
    @objc func probeObject() -> Any? { nil }
    @objc func probeDirectionalEdgeInsets() -> NSDirectionalEdgeInsets { .zero }
}

private enum LookinInvocationEncodings {
    private static let probe = _LookinInvocationTypeEncodingProbe.self

    static let void = encoding(for: #selector(_LookinInvocationTypeEncodingProbe.probeVoid))
    static let char = encoding(for: #selector(_LookinInvocationTypeEncodingProbe.probeChar))
    static let int = encoding(for: #selector(_LookinInvocationTypeEncodingProbe.probeInt))
    static let short = encoding(for: #selector(_LookinInvocationTypeEncodingProbe.probeShort))
    static let long = encoding(for: #selector(_LookinInvocationTypeEncodingProbe.probeLong))
    static let longLong = encoding(for: #selector(_LookinInvocationTypeEncodingProbe.probeLongLong))
    static let unsignedChar = encoding(for: #selector(_LookinInvocationTypeEncodingProbe.probeUnsignedChar))
    static let unsignedInt = encoding(for: #selector(_LookinInvocationTypeEncodingProbe.probeUnsignedInt))
    static let unsignedShort = encoding(for: #selector(_LookinInvocationTypeEncodingProbe.probeUnsignedShort))
    static let unsignedLong = encoding(for: #selector(_LookinInvocationTypeEncodingProbe.probeUnsignedLong))
    static let unsignedLongLong = encoding(for: #selector(_LookinInvocationTypeEncodingProbe.probeUnsignedLongLong))
    static let float = encoding(for: #selector(_LookinInvocationTypeEncodingProbe.probeFloat))
    static let double = encoding(for: #selector(_LookinInvocationTypeEncodingProbe.probeDouble))
    static let bool = encoding(for: #selector(_LookinInvocationTypeEncodingProbe.probeBOOL))
    static let sel = encoding(for: #selector(_LookinInvocationTypeEncodingProbe.probeSEL))
    static let classType = encoding(for: #selector(_LookinInvocationTypeEncodingProbe.probeClass))
    static let cgPoint = encoding(for: #selector(_LookinInvocationTypeEncodingProbe.probeCGPoint))
    static let cgVector = encoding(for: #selector(_LookinInvocationTypeEncodingProbe.probeCGVector))
    static let cgSize = encoding(for: #selector(_LookinInvocationTypeEncodingProbe.probeCGSize))
    static let cgRect = encoding(for: #selector(_LookinInvocationTypeEncodingProbe.probeCGRect))
    static let cgAffineTransform = encoding(for: #selector(_LookinInvocationTypeEncodingProbe.probeCGAffineTransform))
    static let uiEdgeInsets = encoding(for: #selector(_LookinInvocationTypeEncodingProbe.probeUIEdgeInsets))
    static let uiOffset = encoding(for: #selector(_LookinInvocationTypeEncodingProbe.probeUIOffset))
    static let object = encoding(for: #selector(_LookinInvocationTypeEncodingProbe.probeObject))
    static let directionalEdgeInsets = encoding(for: #selector(_LookinInvocationTypeEncodingProbe.probeDirectionalEdgeInsets))

    private static func encoding(for selector: Selector) -> String {
        guard let method = class_getInstanceMethod(probe, selector) else {
            assertionFailure()
            return ""
        }
        let ptr = method_copyReturnType(method)
        defer { free(ptr) }
        return String(cString: ptr)
    }

    static func matches(_ returnType: String, _ encoding: String) -> Bool {
        returnType == encoding
    }
}

// MARK: - Runtime invoke (IMP casting; replaces NSInvocation)

private enum LookinTypedReturn {
    case void
    case char(CChar)
    case int(Int32)
    case short(Int16)
    case long(Int)
    case longLong(Int64)
    case unsignedChar(UInt8)
    case unsignedInt(UInt32)
    case unsignedShort(UInt16)
    case unsignedLong(UInt)
    case unsignedLongLong(UInt64)
    case float(Float)
    case double(Double)
    case bool(Bool)
    case sel(Selector)
    case classType(AnyClass?)
    case cgPoint(CGPoint)
    case cgVector(CGVector)
    case cgSize(CGSize)
    case cgRect(CGRect)
    case cgAffineTransform(CGAffineTransform)
    case uiEdgeInsets(UIEdgeInsets)
    case uiOffset(UIOffset)
    case directionalEdgeInsets(NSDirectionalEdgeInsets)
    case object(AnyObject?)
    case unsupported(String)
}

private enum LookinMethodInvoker {
    static func method(on object: NSObject, selector: Selector) -> Method? {
        let cls: AnyClass = object_isClass(object) ? (object as! AnyClass) : type(of: object)
        return class_getInstanceMethod(cls, selector)
    }

    static func totalArgumentCount(method: Method) -> Int {
        var index: UInt32 = 0
        // method_getArgumentType(_, _, nil, 0) returns required buffer size, not NULL at end — use copy API.
        while let encoding = method_copyArgumentType(method, index) {
            free(encoding)
            index += 1
        }
        return Int(index)
    }

    static func returnTypeEncoding(method: Method) -> String {
        let ptr = method_copyReturnType(method)
        defer { free(ptr) }
        return String(cString: ptr)
    }

    static func invokeNoArgMethod(on object: NSObject, selector: Selector) -> Any? {
        guard let method = method(on: object, selector: selector) else { return nil }
        if totalArgumentCount(method: method) > 2 {
            assertionFailure("LookinServer - There should be no explicit parameters.")
            return nil
        }
        guard case .object(let value) = readReturn(from: object, method: method, selector: selector) else {
            return nil
        }
        return value
    }

    static func readReturn(from object: NSObject, method: Method, selector: Selector) -> LookinTypedReturn {
        let enc = LookinInvocationEncodings.self
        let returnType = returnTypeEncoding(method: method)
        let imp = method_getImplementation(method)

        if enc.matches(returnType, enc.void) {
            typealias Fn = @convention(c) (AnyObject, Selector) -> Void
            unsafeBitCast(imp, to: Fn.self)(object, selector)
            return .void
        }
        if enc.matches(returnType, enc.char) {
            typealias Fn = @convention(c) (AnyObject, Selector) -> CChar
            return .char(unsafeBitCast(imp, to: Fn.self)(object, selector))
        }
        if enc.matches(returnType, enc.int) {
            typealias Fn = @convention(c) (AnyObject, Selector) -> Int32
            return .int(unsafeBitCast(imp, to: Fn.self)(object, selector))
        }
        if enc.matches(returnType, enc.short) {
            typealias Fn = @convention(c) (AnyObject, Selector) -> Int16
            return .short(unsafeBitCast(imp, to: Fn.self)(object, selector))
        }
        if enc.matches(returnType, enc.long) {
            typealias Fn = @convention(c) (AnyObject, Selector) -> Int
            return .long(unsafeBitCast(imp, to: Fn.self)(object, selector))
        }
        if enc.matches(returnType, enc.longLong) {
            typealias Fn = @convention(c) (AnyObject, Selector) -> Int64
            return .longLong(unsafeBitCast(imp, to: Fn.self)(object, selector))
        }
        if enc.matches(returnType, enc.unsignedChar) {
            typealias Fn = @convention(c) (AnyObject, Selector) -> UInt8
            return .unsignedChar(unsafeBitCast(imp, to: Fn.self)(object, selector))
        }
        if enc.matches(returnType, enc.unsignedInt) {
            typealias Fn = @convention(c) (AnyObject, Selector) -> UInt32
            return .unsignedInt(unsafeBitCast(imp, to: Fn.self)(object, selector))
        }
        if enc.matches(returnType, enc.unsignedShort) {
            typealias Fn = @convention(c) (AnyObject, Selector) -> UInt16
            return .unsignedShort(unsafeBitCast(imp, to: Fn.self)(object, selector))
        }
        if enc.matches(returnType, enc.unsignedLong) {
            typealias Fn = @convention(c) (AnyObject, Selector) -> UInt
            return .unsignedLong(unsafeBitCast(imp, to: Fn.self)(object, selector))
        }
        if enc.matches(returnType, enc.unsignedLongLong) {
            typealias Fn = @convention(c) (AnyObject, Selector) -> UInt64
            return .unsignedLongLong(unsafeBitCast(imp, to: Fn.self)(object, selector))
        }
        if enc.matches(returnType, enc.float) {
            typealias Fn = @convention(c) (AnyObject, Selector) -> Float
            return .float(unsafeBitCast(imp, to: Fn.self)(object, selector))
        }
        if enc.matches(returnType, enc.double) {
            typealias Fn = @convention(c) (AnyObject, Selector) -> Double
            return .double(unsafeBitCast(imp, to: Fn.self)(object, selector))
        }
        if enc.matches(returnType, enc.bool) {
            typealias Fn = @convention(c) (AnyObject, Selector) -> Bool
            return .bool(unsafeBitCast(imp, to: Fn.self)(object, selector))
        }
        if enc.matches(returnType, enc.sel) {
            typealias Fn = @convention(c) (AnyObject, Selector) -> Selector
            return .sel(unsafeBitCast(imp, to: Fn.self)(object, selector))
        }
        if enc.matches(returnType, enc.classType) {
            typealias Fn = @convention(c) (AnyObject, Selector) -> AnyClass?
            return .classType(unsafeBitCast(imp, to: Fn.self)(object, selector))
        }
        if enc.matches(returnType, enc.cgPoint) {
            typealias Fn = @convention(c) (AnyObject, Selector) -> CGPoint
            return .cgPoint(unsafeBitCast(imp, to: Fn.self)(object, selector))
        }
        if enc.matches(returnType, enc.cgVector) {
            typealias Fn = @convention(c) (AnyObject, Selector) -> CGVector
            return .cgVector(unsafeBitCast(imp, to: Fn.self)(object, selector))
        }
        if enc.matches(returnType, enc.cgSize) {
            typealias Fn = @convention(c) (AnyObject, Selector) -> CGSize
            return .cgSize(unsafeBitCast(imp, to: Fn.self)(object, selector))
        }
        if enc.matches(returnType, enc.cgRect) {
            typealias Fn = @convention(c) (AnyObject, Selector) -> CGRect
            return .cgRect(unsafeBitCast(imp, to: Fn.self)(object, selector))
        }
        if enc.matches(returnType, enc.cgAffineTransform) {
            typealias Fn = @convention(c) (AnyObject, Selector) -> CGAffineTransform
            return .cgAffineTransform(unsafeBitCast(imp, to: Fn.self)(object, selector))
        }
        if enc.matches(returnType, enc.uiEdgeInsets) {
            typealias Fn = @convention(c) (AnyObject, Selector) -> UIEdgeInsets
            return .uiEdgeInsets(unsafeBitCast(imp, to: Fn.self)(object, selector))
        }
        if enc.matches(returnType, enc.uiOffset) {
            typealias Fn = @convention(c) (AnyObject, Selector) -> UIOffset
            return .uiOffset(unsafeBitCast(imp, to: Fn.self)(object, selector))
        }
        if enc.matches(returnType, enc.directionalEdgeInsets) {
            typealias Fn = @convention(c) (AnyObject, Selector) -> NSDirectionalEdgeInsets
            return .directionalEdgeInsets(unsafeBitCast(imp, to: Fn.self)(object, selector))
        }
        if returnType.hasPrefix("@") || returnType.hasPrefix("#") {
            typealias Fn = @convention(c) (AnyObject, Selector) -> AnyObject?
            return .object(unsafeBitCast(imp, to: Fn.self)(object, selector))
        }
        if returnType.hasPrefix("^{") {
            typealias Fn = @convention(c) (AnyObject, Selector) -> AnyObject?
            return .object(unsafeBitCast(imp, to: Fn.self)(object, selector))
        }
        return .unsupported(returnType)
    }

    static func invokeSetter(on object: NSObject, selector: Selector, value: AttributeValue?) {
        guard let value else { return }
        guard let method = method(on: object, selector: selector) else { return }
        let imp = method_getImplementation(method)

        switch value {
        case .char(let v):
            typealias Fn = @convention(c) (AnyObject, Selector, CChar) -> Void
            unsafeBitCast(imp, to: Fn.self)(object, selector, v)
        case .int(let v):
            typealias Fn = @convention(c) (AnyObject, Selector, Int32) -> Void
            unsafeBitCast(imp, to: Fn.self)(object, selector, v)
        case .short(let v):
            typealias Fn = @convention(c) (AnyObject, Selector, Int16) -> Void
            unsafeBitCast(imp, to: Fn.self)(object, selector, v)
        case .long(let v):
            typealias Fn = @convention(c) (AnyObject, Selector, Int) -> Void
            unsafeBitCast(imp, to: Fn.self)(object, selector, v)
        case .longLong(let v):
            typealias Fn = @convention(c) (AnyObject, Selector, Int64) -> Void
            unsafeBitCast(imp, to: Fn.self)(object, selector, v)
        case .unsignedChar(let v):
            typealias Fn = @convention(c) (AnyObject, Selector, UInt8) -> Void
            unsafeBitCast(imp, to: Fn.self)(object, selector, v)
        case .unsignedInt(let v):
            typealias Fn = @convention(c) (AnyObject, Selector, UInt32) -> Void
            unsafeBitCast(imp, to: Fn.self)(object, selector, v)
        case .unsignedShort(let v):
            typealias Fn = @convention(c) (AnyObject, Selector, UInt16) -> Void
            unsafeBitCast(imp, to: Fn.self)(object, selector, v)
        case .unsignedLong(let v):
            typealias Fn = @convention(c) (AnyObject, Selector, UInt) -> Void
            unsafeBitCast(imp, to: Fn.self)(object, selector, v)
        case .unsignedLongLong(let v):
            typealias Fn = @convention(c) (AnyObject, Selector, UInt64) -> Void
            unsafeBitCast(imp, to: Fn.self)(object, selector, v)
        case .float(let v):
            typealias Fn = @convention(c) (AnyObject, Selector, Float) -> Void
            unsafeBitCast(imp, to: Fn.self)(object, selector, v)
        case .double(let v):
            typealias Fn = @convention(c) (AnyObject, Selector, Double) -> Void
            unsafeBitCast(imp, to: Fn.self)(object, selector, v)
        case .bool(let v):
            typealias Fn = @convention(c) (AnyObject, Selector, Bool) -> Void
            unsafeBitCast(imp, to: Fn.self)(object, selector, v)
        case .selector(let v):
            typealias Fn = @convention(c) (AnyObject, Selector, Selector) -> Void
            unsafeBitCast(imp, to: Fn.self)(object, selector, v)
        case .classRef(let v):
            typealias Fn = @convention(c) (AnyObject, Selector, AnyClass?) -> Void
            unsafeBitCast(imp, to: Fn.self)(object, selector, v)
        case .cgPoint(let v):
            typealias Fn = @convention(c) (AnyObject, Selector, CGPoint) -> Void
            unsafeBitCast(imp, to: Fn.self)(object, selector, v)
        case .cgVector(let v):
            typealias Fn = @convention(c) (AnyObject, Selector, CGVector) -> Void
            unsafeBitCast(imp, to: Fn.self)(object, selector, v)
        case .cgSize(let v):
            typealias Fn = @convention(c) (AnyObject, Selector, CGSize) -> Void
            unsafeBitCast(imp, to: Fn.self)(object, selector, v)
        case .cgRect(let v):
            typealias Fn = @convention(c) (AnyObject, Selector, CGRect) -> Void
            unsafeBitCast(imp, to: Fn.self)(object, selector, v)
        case .cgAffineTransform(let v):
            typealias Fn = @convention(c) (AnyObject, Selector, CGAffineTransform) -> Void
            unsafeBitCast(imp, to: Fn.self)(object, selector, v)
        case .edgeInsets(let v):
            typealias Fn = @convention(c) (AnyObject, Selector, UIEdgeInsets) -> Void
            unsafeBitCast(imp, to: Fn.self)(object, selector, v)
        case .offset(let h, let vert):
            typealias Fn = @convention(c) (AnyObject, Selector, UIOffset) -> Void
            unsafeBitCast(imp, to: Fn.self)(object, selector, UIOffset(horizontal: h, vertical: vert))
        case .string(let v):
            var obj: AnyObject? = v as NSString
            typealias Fn = @convention(c) (AnyObject, Selector, AnyObject?) -> Void
            unsafeBitCast(imp, to: Fn.self)(object, selector, obj)
        case .customObject(let v):
            var obj = v as AnyObject?
            typealias Fn = @convention(c) (AnyObject, Selector, AnyObject?) -> Void
            unsafeBitCast(imp, to: Fn.self)(object, selector, obj)
        case .color(let rgba):
            var cv: UIColor? = UIColor.lks_color(fromRGBAComponents: rgba.map { NSNumber(value: $0) })
            typealias Fn = @convention(c) (AnyObject, Selector, UIColor?) -> Void
            unsafeBitCast(imp, to: Fn.self)(object, selector, cv)
        case .json, .shadow:
            return
        }
    }
}

// MARK: - LKS_InvocationRuntimeHelper

@objc(LKS_InvocationRuntimeHelper)
public final class LKS_InvocationRuntimeHelper: NSObject {

    @objc(invokeNoArgMethodOnObject:selectorName:)
    public static func invokeNoArgMethod(on object: Any?, selectorName: String?) -> Any? {
        guard let object, let selectorName, !selectorName.isEmpty else { return nil }
        guard let target = object as? NSObject, target is UIView || target is CALayer else { return nil }

        let selector = NSSelectorFromString(selectorName)
        guard target.responds(to: selector) else { return nil }
        return LookinMethodInvoker.invokeNoArgMethod(on: target, selector: selector)
    }

    @objc(attributeWithIdentifier:targetObject:)
    public static func attribute(withIdentifier identifier: String, targetObject target: Any?) -> LookinAttribute? {
        guard let target = target as? NSObject else {
            assertionFailure()
            return nil
        }

        let attribute = LookinAttribute()
        attribute.identifier = identifier

        guard let getter = LookinDashboardBlueprint.getter(withAttrID: identifier) else {
            assertionFailure()
            return nil
        }
        if !target.responds(to: getter) { return nil }

        guard let method = LookinMethodInvoker.method(on: target, selector: getter) else { return nil }
        if LookinMethodInvoker.totalArgumentCount(method: method) > 2 {
            assertionFailure("getter cannot have parameters")
            return nil
        }
        if LookinInvocationEncodings.matches(
            LookinMethodInvoker.returnTypeEncoding(method: method),
            LookinInvocationEncodings.void
        ) {
            assertionFailure("getter return type cannot be void")
            return nil
        }

        let typedReturn = LookinMethodInvoker.readReturn(from: target, method: method, selector: getter)
        return fillAttribute(attribute, identifier: identifier, typedReturn: typedReturn)
    }

    public static func applySetter(for modification: LookinAttributeModification, receiver: NSObject) -> NSError? {
        guard let method = LookinMethodInvoker.method(on: receiver, selector: modification.setterSelector) else {
            return lookinInnerError()
        }
        if LookinMethodInvoker.totalArgumentCount(method: method) != 3
            || !receiver.responds(to: modification.setterSelector) {
            return lookinInnerError()
        }

        switch modification.attrType {
        case .none, .void, .enumString, .shadow, .json:
            return lookinInnerError()
        default:
            break
        }

        do {
            try LookinObjCExceptionBridge.tryExecute {
                LookinMethodInvoker.invokeSetter(
                    on: receiver,
                    selector: modification.setterSelector,
                    value: modification.value
                )
            }
            return nil
        } catch {
            let reason = (error as NSError).localizedRecoverySuggestion ?? error.localizedDescription
            let errorMsg = String(
                format: lksLocalized("<%@: %p>: an exception was raised when invoking %@. (%@)"),
                NSStringFromClass(type(of: receiver)),
                receiver,
                NSStringFromSelector(modification.setterSelector),
                reason
            )
            return lookinExceptionError(recoverySuggestion: errorMsg)
        }
    }

    @objc(handleInvokeWithObject:selector:resultDescription:resultObject:error:)
    public static func handleInvoke(
        with obj: NSObject,
        selector: Selector,
        resultDescription: AutoreleasingUnsafeMutablePointer<NSString?>?,
        resultObject: AutoreleasingUnsafeMutablePointer<LookinObject?>?,
        error: AutoreleasingUnsafeMutablePointer<NSError?>?
    ) {
        guard let method = LookinMethodInvoker.method(on: obj, selector: selector) else { return }
        if LookinMethodInvoker.totalArgumentCount(method: method) > 2 {
            error?.pointee = lookinErrorMake(
                title: lksLocalized("Lookin doesn't support invoking methods with arguments yet."),
                detail: ""
            )
            return
        }

        let typedReturn = LookinMethodInvoker.readReturn(from: obj, method: method, selector: selector)
        describeInvokeReturn(
            typedReturn,
            selector: selector,
            resultDescription: resultDescription,
            resultObject: resultObject
        )
    }
}

// MARK: - Attribute population

private extension LKS_InvocationRuntimeHelper {
    static func fillAttribute(
        _ attribute: LookinAttribute,
        identifier: String,
        typedReturn: LookinTypedReturn
    ) -> LookinAttribute? {
        switch typedReturn {
        case .char(let targetValue):
            attribute.attrType = .char
            attribute.value = .char(targetValue)
        case .int(let targetValue):
            attribute.value = .int(targetValue)
            attribute.attrType = LookinDashboardBlueprint.enumListName(withAttrID: identifier) != nil ? .enumInt : .int
        case .short(let targetValue):
            attribute.attrType = .short
            attribute.value = .short(targetValue)
        case .long(let targetValue):
            attribute.value = .long(targetValue)
            attribute.attrType = LookinDashboardBlueprint.enumListName(withAttrID: identifier) != nil ? .enumLong : .long
        case .longLong(let targetValue):
            attribute.attrType = .longLong
            attribute.value = .longLong(targetValue)
        case .unsignedChar(let targetValue):
            attribute.attrType = .unsignedChar
            attribute.value = .unsignedChar(targetValue)
        case .unsignedInt(let targetValue):
            attribute.attrType = .unsignedInt
            attribute.value = .unsignedInt(targetValue)
        case .unsignedShort(let targetValue):
            attribute.attrType = .unsignedShort
            attribute.value = .unsignedShort(targetValue)
        case .unsignedLong(let targetValue):
            attribute.attrType = .unsignedLong
            attribute.value = .unsignedLong(targetValue)
        case .unsignedLongLong(let targetValue):
            attribute.attrType = .unsignedLongLong
            attribute.value = .unsignedLongLong(targetValue)
        case .float(let targetValue):
            attribute.attrType = .float
            attribute.value = .float(targetValue)
        case .double(let targetValue):
            attribute.attrType = .double
            attribute.value = .double(targetValue)
        case .bool(let targetValue):
            attribute.attrType = .BOOL
            attribute.value = .bool(targetValue)
        case .sel(let targetValue):
            attribute.attrType = .sel
            attribute.value = .string(NSStringFromSelector(targetValue))
        case .classType(let targetValue):
            attribute.attrType = .class
            attribute.value = .string(targetValue.map { NSStringFromClass($0) } ?? "")
        case .cgPoint(let targetValue):
            attribute.attrType = .CGPoint
            attribute.value = .cgPoint(targetValue)
        case .cgVector(let targetValue):
            attribute.attrType = .CGVector
            attribute.value = .cgVector(targetValue)
        case .cgSize(let targetValue):
            attribute.attrType = .CGSize
            attribute.value = .cgSize(targetValue)
        case .cgRect(let targetValue):
            attribute.attrType = .CGRect
            attribute.value = .cgRect(targetValue)
        case .cgAffineTransform(let targetValue):
            attribute.attrType = .CGAffineTransform
            attribute.value = .cgAffineTransform(targetValue)
        case .uiEdgeInsets(let targetValue):
            attribute.attrType = .UIEdgeInsets
            attribute.value = .edgeInsets(targetValue)
        case .uiOffset(let targetValue):
            attribute.attrType = .UIOffset
            attribute.value = .offset(targetValue.horizontal, targetValue.vertical)
        case .object(let returnObjValue):
            if returnObjValue == nil, LookinDashboardBlueprint.hideIfNil(withAttrID: identifier) {
                return nil
            }
            attribute.attrType = LookinDashboardBlueprint.objectAttrType(withAttrID: identifier)
            if attribute.attrType == .UIColor {
                if returnObjValue == nil {
                    attribute.value = nil
                } else if let color = returnObjValue as? UIColor, color.responds(to: #selector(UIColor.lks_rgbaComponents)) {
                    attribute.value = .color(color.lks_rgbaComponents().map(\.doubleValue))
                } else {
                    return nil
                }
            } else {
                attribute.value = returnObjValue.map { .customObject($0) }
            }
        case .void, .directionalEdgeInsets, .unsupported:
            assertionFailure("Unsupported return type for parsing")
            return nil
        }
        return attribute
    }
}

// MARK: - Invoke result description

private extension LKS_InvocationRuntimeHelper {
    static func describeInvokeReturn(
        _ typedReturn: LookinTypedReturn,
        selector: Selector,
        resultDescription: AutoreleasingUnsafeMutablePointer<NSString?>?,
        resultObject: AutoreleasingUnsafeMutablePointer<LookinObject?>?
    ) {
        switch typedReturn {
        case .void:
            resultDescription?.pointee = lookinStringFlagVoidReturn as NSString
        case .char(let charValue):
            resultDescription?.pointee = "\(charValue)" as NSString
        case .int(let intValue):
            if intValue == Int32.max {
                resultDescription?.pointee = "INT_MAX" as NSString
            } else if intValue == Int32.min {
                resultDescription?.pointee = "INT_MIN" as NSString
            } else {
                resultDescription?.pointee = "\(intValue)" as NSString
            }
        case .short(let shortValue):
            if shortValue == Int16.max {
                resultDescription?.pointee = "SHRT_MAX" as NSString
            } else if shortValue == Int16.min {
                resultDescription?.pointee = "SHRT_MIN" as NSString
            } else {
                resultDescription?.pointee = "\(shortValue)" as NSString
            }
        case .long(let longValue):
            if longValue == NSNotFound {
                resultDescription?.pointee = "NSNotFound" as NSString
            } else if longValue == Int.max {
                resultDescription?.pointee = "LONG_MAX" as NSString
            } else if longValue == Int.min {
                resultDescription?.pointee = "LONG_MAX" as NSString
            } else {
                resultDescription?.pointee = "\(longValue)" as NSString
            }
        case .longLong(let longLongValue):
            if longLongValue == Int64.max {
                resultDescription?.pointee = "LLONG_MAX" as NSString
            } else if longLongValue == Int64.min {
                resultDescription?.pointee = "LLONG_MIN" as NSString
            } else {
                resultDescription?.pointee = "\(longLongValue)" as NSString
            }
        case .unsignedChar(let ucharValue):
            if ucharValue == UInt8.max {
                resultDescription?.pointee = "UCHAR_MAX" as NSString
            } else {
                resultDescription?.pointee = "\(ucharValue)" as NSString
            }
        case .unsignedInt(let uintValue):
            if uintValue == UInt32.max {
                resultDescription?.pointee = "UINT_MAX" as NSString
            } else {
                resultDescription?.pointee = "\(uintValue)" as NSString
            }
        case .unsignedShort(let ushortValue):
            if ushortValue == UInt16.max {
                resultDescription?.pointee = "USHRT_MAX" as NSString
            } else {
                resultDescription?.pointee = "\(ushortValue)" as NSString
            }
        case .unsignedLong(let ulongValue):
            if ulongValue == UInt.max {
                resultDescription?.pointee = "ULONG_MAX" as NSString
            } else {
                resultDescription?.pointee = "\(ulongValue)" as NSString
            }
        case .unsignedLongLong(let ulongLongValue):
            if ulongLongValue == UInt64.max {
                resultDescription?.pointee = "ULONG_LONG_MAX" as NSString
            } else {
                resultDescription?.pointee = "\(ulongLongValue)" as NSString
            }
        case .float(let floatValue):
            if floatValue == Float.greatestFiniteMagnitude {
                resultDescription?.pointee = "FLT_MAX" as NSString
            } else if floatValue == Float.leastNormalMagnitude {
                resultDescription?.pointee = "FLT_MIN" as NSString
            } else {
                resultDescription?.pointee = "\(floatValue)" as NSString
            }
        case .double(let doubleValue):
            if doubleValue == Double.greatestFiniteMagnitude {
                resultDescription?.pointee = "DBL_MAX" as NSString
            } else if doubleValue == Double.leastNormalMagnitude {
                resultDescription?.pointee = "DBL_MIN" as NSString
            } else {
                resultDescription?.pointee = "\(doubleValue)" as NSString
            }
        case .bool(let boolValue):
            resultDescription?.pointee = (boolValue ? "YES" : "NO") as NSString
        case .sel(let selValue):
            resultDescription?.pointee = "SEL(\(NSStringFromSelector(selValue)))" as NSString
        case .classType(let classValue):
            if let classValue {
                resultDescription?.pointee = "<\(NSStringFromClass(classValue))>" as NSString
            }
        case .cgPoint(let targetValue):
            resultDescription?.pointee = "\(targetValue)" as NSString
        case .cgVector(let targetValue):
            resultDescription?.pointee = "\(targetValue)" as NSString
        case .cgSize(let targetValue):
            resultDescription?.pointee = "\(targetValue)" as NSString
        case .cgRect(let rectValue):
            resultDescription?.pointee = "\(rectValue)" as NSString
        case .cgAffineTransform(let transformValue):
            resultDescription?.pointee = "\(transformValue)" as NSString
        case .uiEdgeInsets(let targetValue):
            resultDescription?.pointee = "\(targetValue)" as NSString
        case .uiOffset(let targetValue):
            resultDescription?.pointee = "\(targetValue)" as NSString
        case .directionalEdgeInsets(let targetValue):
            resultDescription?.pointee = "\(targetValue)" as NSString
        case .object(let returnObjValue):
            if let returnObjValue {
                resultDescription?.pointee = "\(returnObjValue)" as NSString
                if let nsObject = returnObjValue as? NSObject {
                    resultObject?.pointee = LookinObject.instance(with: nsObject)
                }
            } else {
                resultDescription?.pointee = "nil" as NSString
            }
        case .unsupported(let encoding):
            resultDescription?.pointee = String(
                format: lksLocalized("%@ was invoked successfully, but Lookin can't parse the return value:%@"),
                NSStringFromSelector(selector),
                encoding
            ) as NSString
        }
    }
}

#endif
