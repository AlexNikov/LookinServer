#if SHOULD_COMPILE_LOOKIN_SERVER
import Foundation
import OSLog
import UIKit
#if canImport(LookinShared)
import LookinShared
#endif

@MainActor
extension MCPHTTPHandler {

    // MARK: - Orientation

    func handleGetOrientation() -> MCPHTTPResponse {
        #if os(iOS) || os(tvOS)
        guard let scene = LKS_MultiplatformAdapter.keyWindow()?.windowScene else {
            return .error(message: "No key window scene", statusCode: 503)
        }
        return .ok(data: ["orientation": interfaceOrientationName(scene.interfaceOrientation)])
        #else
        return .error(message: "Interface orientation is only available on iOS.", statusCode: 400)
        #endif
    }

    func handleSetOrientation(body: [String: Any]?) async -> MCPHTTPResponse {
        #if os(iOS)
        guard let name = body?["orientation"] as? String, !name.isEmpty else {
            return .error(
                message: "Provide orientation: portrait, portraitUpsideDown, landscapeLeft, or landscapeRight",
                statusCode: 400
            )
        }
        guard let mask = interfaceOrientationMask(named: name) else {
            return .error(
                message: "Unknown orientation '\(name)'. Use portrait, portraitUpsideDown, landscapeLeft, or landscapeRight.",
                statusCode: 400
            )
        }
        guard #available(iOS 16.0, *) else {
            return .error(
                message: "Setting interface orientation requires iOS 16 or newer (UIWindowScene.requestGeometryUpdate). This OS has no public API that changes orientation.",
                statusCode: 400
            )
        }
        guard let scene = LKS_MultiplatformAdapter.keyWindow()?.windowScene else {
            return .error(message: "No key window scene", statusCode: 503)
        }

        let preferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: mask)
        let failure: String? = await withCheckedContinuation { continuation in
            let gate = MCPResumeOnce()
            scene.requestGeometryUpdate(preferences) { error in
                gate.resume {
                    continuation.resume(returning: error.localizedDescription)
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                gate.resume {
                    continuation.resume(returning: nil)
                }
            }
        }
        if let failure {
            return .error(message: "requestGeometryUpdate failed: \(failure)", statusCode: 500)
        }
        let applied = interfaceOrientationName(scene.interfaceOrientation)
        if applied != name {
            return .error(
                message: "requestGeometryUpdate was accepted, but the scene orientation is still \(applied). The app may not allow \(name) (Info.plist or the visible view controller).",
                statusCode: 409
            )
        }
        return .ok(data: ["orientation": applied, "requested": name])
        #else
        _ = body
        return .error(
            message: "Setting interface orientation is only supported on iOS 16 or newer via UIWindowScene.requestGeometryUpdate.",
            statusCode: 400
        )
        #endif
    }

    // MARK: - Appearance

    func handleGetAppearance() -> MCPHTTPResponse {
        guard let window = LKS_MultiplatformAdapter.keyWindow() else {
            return .error(message: "No key window", statusCode: 503)
        }
        return .ok(data: ["style": interfaceStyleName(window.overrideUserInterfaceStyle)])
    }

    func handleSetAppearance(body: [String: Any]?) -> MCPHTTPResponse {
        guard let name = body?["style"] as? String, let style = interfaceStyle(named: name) else {
            return .error(message: "Provide style: light, dark, or unspecified", statusCode: 400)
        }
        let windows = LKS_MultiplatformAdapter.allWindows()
        guard !windows.isEmpty else {
            return .error(message: "No windows found", statusCode: 503)
        }
        for window in windows {
            window.overrideUserInterfaceStyle = style
            #if os(iOS)
            if #available(iOS 17.0, *) {
                window.windowScene?.traitOverrides.userInterfaceStyle = style
            }
            #endif
        }
        return .ok(data: ["style": interfaceStyleName(style)])
    }

    // MARK: - Shake

    func handleShake() -> MCPHTTPResponse {
        guard let window = LKS_MultiplatformAdapter.keyWindow() else {
            return .error(message: "No key window to deliver shake", statusCode: 503)
        }
        let start = findFirstResponder(in: window) ?? window
        var responder: UIResponder? = start
        var hops = 0
        while let current = responder, hops < 64 {
            hops += 1
            if responderOverridesMotion(current) {
                current.motionBegan(.motionShake, with: nil)
                current.motionEnded(.motionShake, with: nil)
                return .ok(data: [
                    "shaken": true,
                    "responder": NSStringFromClass(type(of: current)),
                ])
            }
            responder = current.next
        }
        return .error(
            message: "No responder in the key window chain overrides motionBegan or motionEnded. Shake was not delivered.",
            statusCode: 400
        )
    }

    // MARK: - Logs

    func handleLogs(request: MCPHTTPRequest) -> MCPHTTPResponse {
        guard #available(iOS 15.0, tvOS 15.0, *) else {
            return .error(message: "OSLogStore requires iOS 15 or newer.", statusCode: 400)
        }
        let requested = Int(request.query["limit"] ?? "") ?? 100
        let limit = min(max(requested, 1), 500)
        let subsystem = request.query["subsystem"].flatMap { $0.isEmpty ? nil : $0 }
        let category = request.query["category"].flatMap { $0.isEmpty ? nil : $0 }
        do {
            let store = try OSLogStore(scope: .currentProcessIdentifier)
            let position = store.position(timeIntervalSinceEnd: -60 * 60)
            let predicate = logPredicate(subsystem: subsystem, category: category)
            let entries = try store.getEntries(with: [], at: position, matching: predicate)
            let logs = entries.compactMap { $0 as? OSLogEntryLog }
            let slice = logs.suffix(limit)
            let payload: [[String: Any]] = slice.map { entry in
                [
                    "date": MCPLogDate.formatter.string(from: entry.date),
                    "level": logLevelName(entry.level),
                    "subsystem": entry.subsystem,
                    "category": entry.category,
                    "message": entry.composedMessage,
                ]
            }
            return .ok(data: ["count": payload.count, "limit": limit, "logs": payload])
        } catch {
            return .error(message: "OSLogStore unavailable: \(error.localizedDescription)", statusCode: 503)
        }
    }

    // MARK: - Screenshot compare

    func handleScreenshotCompare(body: [String: Any]?) -> MCPHTTPResponse {
        if let baseline = body?["baseline"] as? String, baseline != "previous" {
            return .error(message: "Only baseline \"previous\" is supported", statusCode: 400)
        }
        let oid: UInt
        if let raw = body?["oid"], !(raw is NSNull) {
            guard let parsed = uintOid(from: raw), parsed > 0 else {
                return .error(message: "Invalid oid", statusCode: 400)
            }
            oid = parsed
        } else if let windowOid = LKS_MultiplatformAdapter.keyWindow()?.lks_registerOid(), windowOid > 0 {
            oid = windowOid
        } else {
            return .error(message: "No key window to screenshot", statusCode: 503)
        }

        switch capturePNG(oid: oid) {
        case .failure(let response):
            return response
        case .image(let png, let width, let height):
            let includeDiff = jsonBool(body?["includeDiffImage"])
            guard let previous = screenshotBaselines[oid] else {
                screenshotBaselines[oid] = png
                return .ok(data: [
                    "oid": oid,
                    "stored": true,
                    "compared": false,
                    "width": width,
                    "height": height,
                ])
            }
            guard let currentPixels = rgbaPixels(from: png),
                  let previousPixels = rgbaPixels(from: previous) else {
                return .error(message: "Failed to decode screenshot PNG for comparison", statusCode: 500)
            }
            screenshotBaselines[oid] = png
            if currentPixels.width != previousPixels.width || currentPixels.height != previousPixels.height {
                return .ok(data: [
                    "oid": oid,
                    "stored": true,
                    "compared": true,
                    "changedPixelRatio": 1.0,
                    "changedPixelCount": max(currentPixels.width * currentPixels.height, previousPixels.width * previousPixels.height),
                    "width": currentPixels.width,
                    "height": currentPixels.height,
                    "summary": "Dimensions differ (\(previousPixels.width)×\(previousPixels.height) → \(currentPixels.width)×\(currentPixels.height))",
                ])
            }
            let changed = changedPixelCount(currentPixels.bytes, previousPixels.bytes)
            let total = currentPixels.width * currentPixels.height
            let ratio = total > 0 ? Double(changed) / Double(total) : 0
            var data: [String: Any] = [
                "oid": oid,
                "stored": true,
                "compared": true,
                "changedPixelRatio": ratio,
                "changedPixelCount": changed,
                "width": width,
                "height": height,
                "summary": "\(changed) of \(total) pixels changed",
            ]
            if includeDiff, let diff = diffPNGBase64(
                current: currentPixels.bytes,
                previous: previousPixels.bytes,
                width: currentPixels.width,
                height: currentPixels.height
            ) {
                data["diffImageBase64"] = diff
                data["diffMimeType"] = "image/png"
            }
            return .ok(data: data)
        }
    }
}

private enum MCPLogDate {
    static let formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}

private final class MCPResumeOnce: @unchecked Sendable {
    private let lock = NSLock()
    private var fired = false

    func resume(_ body: () -> Void) {
        lock.lock()
        let shouldRun = !fired
        if shouldRun { fired = true }
        lock.unlock()
        if shouldRun { body() }
    }
}

@MainActor
private extension MCPHTTPHandler {
    #if os(iOS) || os(tvOS)
    func interfaceOrientationName(_ orientation: UIInterfaceOrientation) -> String {
        switch orientation {
        case .portrait: return "portrait"
        case .portraitUpsideDown: return "portraitUpsideDown"
        case .landscapeLeft: return "landscapeLeft"
        case .landscapeRight: return "landscapeRight"
        default: return "unknown"
        }
    }
    #endif

    #if os(iOS)
    func interfaceOrientationMask(named name: String) -> UIInterfaceOrientationMask? {
        switch name {
        case "portrait": return .portrait
        case "portraitUpsideDown": return .portraitUpsideDown
        case "landscapeLeft": return .landscapeLeft
        case "landscapeRight": return .landscapeRight
        default: return nil
        }
    }
    #endif

    func interfaceStyleName(_ style: UIUserInterfaceStyle) -> String {
        switch style {
        case .light: return "light"
        case .dark: return "dark"
        default: return "unspecified"
        }
    }

    func interfaceStyle(named name: String) -> UIUserInterfaceStyle? {
        switch name {
        case "light": return .light
        case "dark": return .dark
        case "unspecified": return .unspecified
        default: return nil
        }
    }

    func findFirstResponder(in view: UIView) -> UIResponder? {
        if view.isFirstResponder { return view }
        for subview in view.subviews {
            if let found = findFirstResponder(in: subview) { return found }
        }
        return nil
    }

    func responderOverridesMotion(_ responder: UIResponder) -> Bool {
        overridesMotion(#selector(UIResponder.motionEnded(_:with:)), responder)
            || overridesMotion(#selector(UIResponder.motionBegan(_:with:)), responder)
    }

    func overridesMotion(_ selector: Selector, _ responder: UIResponder) -> Bool {
        var current: AnyClass? = type(of: responder)
        while let cls = current, cls != UIResponder.self {
            if let method = class_getInstanceMethod(cls, selector),
               let superClass = class_getSuperclass(cls),
               let superMethod = class_getInstanceMethod(superClass, selector),
               method_getImplementation(method) != method_getImplementation(superMethod) {
                return true
            }
            current = class_getSuperclass(cls)
        }
        return false
    }

    func logPredicate(subsystem: String?, category: String?) -> NSPredicate? {
        switch (subsystem, category) {
        case let (subsystem?, category?):
            return NSPredicate(format: "subsystem == %@ AND category == %@", subsystem, category)
        case let (subsystem?, nil):
            return NSPredicate(format: "subsystem == %@", subsystem)
        case let (nil, category?):
            return NSPredicate(format: "category == %@", category)
        default:
            return nil
        }
    }

    @available(iOS 15.0, tvOS 15.0, *)
    func logLevelName(_ level: OSLogEntryLog.Level) -> String {
        switch level {
        case .debug: return "debug"
        case .info: return "info"
        case .notice: return "notice"
        case .error: return "error"
        case .fault: return "fault"
        default: return "undefined"
        }
    }

    func jsonBool(_ value: Any?) -> Bool {
        if let value = value as? Bool { return value }
        if let value = value as? NSNumber { return value.boolValue }
        return false
    }

    func rgbaPixels(from data: Data) -> (bytes: [UInt8], width: Int, height: Int)? {
        guard let image = UIImage(data: data), let cgImage = image.cgImage else { return nil }
        let width = cgImage.width
        let height = cgImage.height
        guard width > 0, height > 0 else { return nil }
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        let drew = bytes.withUnsafeMutableBytes { raw -> Bool in
            guard let base = raw.baseAddress else { return false }
            guard let context = CGContext(
                data: base,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        return drew ? (bytes, width, height) : nil
    }

    func changedPixelCount(_ current: [UInt8], _ previous: [UInt8]) -> Int {
        let pixels = min(current.count, previous.count) / 4
        var changed = 0
        for index in 0..<pixels {
            let offset = index * 4
            if current[offset] != previous[offset]
                || current[offset + 1] != previous[offset + 1]
                || current[offset + 2] != previous[offset + 2]
                || current[offset + 3] != previous[offset + 3] {
                changed += 1
            }
        }
        return changed
    }

    func diffPNGBase64(current: [UInt8], previous: [UInt8], width: Int, height: Int) -> String? {
        let maxEdge = 160
        let scale = min(1.0, Double(maxEdge) / Double(max(width, height)))
        let destWidth = max(1, Int((Double(width) * scale).rounded(.down)))
        let destHeight = max(1, Int((Double(height) * scale).rounded(.down)))
        var pixels = [UInt8](repeating: 255, count: destWidth * destHeight * 4)
        for y in 0..<destHeight {
            let sourceY = min(height - 1, Int((Double(y) / scale).rounded(.down)))
            for x in 0..<destWidth {
                let sourceX = min(width - 1, Int((Double(x) / scale).rounded(.down)))
                let source = (sourceY * width + sourceX) * 4
                let dest = (y * destWidth + x) * 4
                let changed = current[source] != previous[source]
                    || current[source + 1] != previous[source + 1]
                    || current[source + 2] != previous[source + 2]
                    || current[source + 3] != previous[source + 3]
                if changed {
                    pixels[dest] = 255
                    pixels[dest + 1] = 32
                    pixels[dest + 2] = 32
                    pixels[dest + 3] = 255
                } else {
                    pixels[dest] = current[source]
                    pixels[dest + 1] = current[source + 1]
                    pixels[dest + 2] = current[source + 2]
                    pixels[dest + 3] = 255
                }
            }
        }
        let image: UIImage? = pixels.withUnsafeMutableBytes { raw in
            guard let base = raw.baseAddress,
                  let context = CGContext(
                    data: base,
                    width: destWidth,
                    height: destHeight,
                    bitsPerComponent: 8,
                    bytesPerRow: destWidth * 4,
                    space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                  ),
                  let cgImage = context.makeImage() else {
                return nil
            }
            return UIImage(cgImage: cgImage)
        }
        return image?.pngData()?.base64EncodedString()
    }
}
#endif
