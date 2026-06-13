#if SHOULD_COMPILE_LOOKIN_SERVER
import Foundation
import UIKit
#if canImport(LookinShared)
import LookinShared
#endif

@MainActor
final class MCPHTTPHandler {

    func handle(request: MCPHTTPRequest) async -> MCPHTTPResponse {
        switch (request.method, request.path) {
        case ("GET", "/status"):
            return handleStatus()
        case ("GET", "/hierarchy"):
            return handleHierarchy()
        case ("GET", "/tap-targets"):
            return handleTapTargets()
        case ("GET", "/text-inputs"):
            return handleTextInputs()
        case ("GET", "/wire-roundtrip"):
            return handleWireRoundtrip()
        case ("GET", "/wire-v2-selftest"):
            return await handleWireV2SelfTest()
        case ("POST", "/relisten-peertalk"):
            return handleRelistenPeertalk()
        default:
            if request.oidParam > 0, request.path.hasSuffix("/attributes") {
                if request.method == "GET" {
                    return handleGetAttributes(oid: request.oidParam)
                }
                if request.method == "POST" {
                    return await handleModifyAttribute(oid: request.oidParam, body: request.jsonBody)
                }
            }

            if request.oidParam > 0, request.method == "GET", request.path.hasSuffix("/screenshot") {
                return handleScreenshot(oid: request.oidParam)
            }

            if request.method == "POST", request.path == "/tap" {
                return handleTap(body: request.jsonBody)
            }

            if request.method == "POST", request.path == "/swipe" {
                return await handleSwipe(body: request.jsonBody)
            }

            if request.method == "POST", request.path == "/type-text" {
                return handleTypeText(body: request.jsonBody)
            }

            if request.method == "POST", request.path == "/keyboard" {
                return handleKeyboard(body: request.jsonBody)
            }

            if request.method == "POST", request.path == "/long-press" {
                return await handleLongPress(body: request.jsonBody)
            }

            if request.method == "POST", request.path == "/find-view" {
                return handleFindView(body: request.jsonBody)
            }

            if request.method == "POST", request.path == "/view-at-point" {
                return handleViewAtPoint(body: request.jsonBody)
            }

            if request.method == "POST", request.path == "/tap-by-label" {
                return handleTapByLabel(body: request.jsonBody)
            }

            if request.method == "POST", request.path == "/wait-for-view" {
                return await handleWaitForView(body: request.jsonBody)
            }

            if request.method == "POST", request.path == "/double-tap" {
                return await handleDoubleTap(body: request.jsonBody)
            }

            if request.method == "POST", request.path == "/drag" {
                return await handleSwipe(body: request.jsonBody)
            }

            if request.method == "POST", request.path == "/pinch" {
                return handlePinch(body: request.jsonBody)
            }

            if request.method == "POST", request.path == "/scroll" {
                return handleScroll(body: request.jsonBody)
            }

            if request.method == "POST", request.path == "/toggle" {
                return handleToggle(body: request.jsonBody)
            }

            if request.method == "POST", request.path == "/select-row" {
                return handleSelectRow(body: request.jsonBody)
            }

            if request.method == "POST", request.path == "/clear-text" {
                return handleClearText(body: request.jsonBody)
            }

            if request.method == "POST", request.path == "/invoke-method" {
                return handleInvokeMethod(body: request.jsonBody)
            }

            if request.method == "POST", request.path == "/selectors" {
                return handleSelectors(body: request.jsonBody)
            }

            if request.oidParam > 0, request.method == "GET", request.path.hasSuffix("/custom-info") {
                return handleCustomInfo(oid: request.oidParam)
            }

            if request.oidParam > 0, request.method == "GET", request.path.hasSuffix("/hierarchy-details") {
                return handleHierarchyDetails(oid: request.oidParam)
            }

            if request.oidParam > 0, request.method == "POST", request.path.hasSuffix("/custom-attributes") {
                return handleModifyCustomAttribute(oid: request.oidParam, body: request.jsonBody)
            }

            return .error(message: "Not found", statusCode: 404)
        }
    }

    private func handleRelistenPeertalk() -> MCPHTTPResponse {
        LKS_ConnectionManager.sharedInstance.prepareForNewMacClientConnection()
        return .ok(data: ["relisten": true])
    }

    private func handleStatus() -> MCPHTTPResponse {
        let manager = LKS_ConnectionManager.sharedInstance
        manager.nudgePeertalkListenForLaunchScreenDiscoveryIfNeeded()
        let appInfo = LKAppInfo.currentInfo(withScreenshot: false, icon: false, localIdentifiers: nil)

        let data: [String: Any] = [
            "active": manager.applicationIsActive,
            "appName": appInfo.appName ?? "",
            "bundleId": appInfo.appBundleIdentifier ?? "",
            "osDescription": appInfo.osDescription ?? "",
            "deviceDescription": appInfo.deviceDescription ?? "",
            "screenWidth": appInfo.screenWidth,
            "screenHeight": appInfo.screenHeight,
            "screenScale": appInfo.screenScale,
            "peertalkListenPort": manager.mcpPeertalkListenPort(),
            "peertalkConnected": manager.mcpPeertalkIsConnected(),
        ]
        return .ok(data: data)
    }

    private func handleWireV2SelfTest() async -> MCPHTTPResponse {
        let tag: UInt32 = 424_242
        let pingJSON = Data(
            "{\"requestType\":200,\"tag\":\(tag),\"wireVersion\":\(LookinWireFormat.version)}".utf8
        )

        let extracted: Data
        let payloadBytesMatch: Bool
        if let dispatchRef = (pingJSON as NSData).createReferencingDispatchData() as dispatch_data_t? {
            let ptData = LookinPTData(
                mappedDispatchData: dispatchRef,
                data: nil,
                length: pingJSON.count
            )
            extracted = ptData.lookinPayloadBytes()
            payloadBytesMatch = extracted == pingJSON
        } else {
            extracted = pingJSON
            payloadBytesMatch = true
        }

        let requestEnvelope: WireRequestEnvelope
        do {
            requestEnvelope = try LKWireCodecV2.decodeJSON(WireRequestEnvelope.self, from: extracted)
        } catch {
            return .error(
                message: "WireRequestEnvelope decode failed: \(error.localizedDescription)",
                statusCode: 500
            )
        }

        let decodeOk = requestEnvelope.requestType == UInt32(LookinRequestTypePing)
            && requestEnvelope.tag == tag
            && requestEnvelope.wireVersion == LookinWireFormat.version

        var attachment = LookinConnectionResponseAttachment()
        attachment.appIsInBackground = UIApplication.shared.applicationState == .background
        guard let responseEnvelope = WireRequestResponseMapper.responseEnvelope(
            from: attachment,
            requestType: UInt32(LookinRequestTypePing),
            tag: tag
        ) else {
            return .error(message: "Wire ping response mapper failed", statusCode: 500)
        }

        let responseJSON: Data
        do {
            responseJSON = try LKWireCodecV2.encodeJSON(responseEnvelope)
        } catch {
            return .error(
                message: "Wire ping response encode failed: \(error.localizedDescription)",
                statusCode: 500
            )
        }

        let responseIsJSON = responseJSON.first == UInt8(ascii: "{")
        let responseHasPing = responseJSON.contains(UInt8(ascii: "p")) // "ping" key in JSON

        let manager = LKS_ConnectionManager.sharedInstance
        await manager.handleWireJSONRequest(requestEnvelope, tag: tag)

        return .ok(data: [
            "decodeOk": decodeOk,
            "payloadBytesMatch": payloadBytesMatch,
            "payloadLength": extracted.count,
            "requestType": requestEnvelope.requestType,
            "responseIsJSON": responseIsJSON,
            "responseHasPingField": responseHasPing,
            "responseLength": responseJSON.count,
            "lkjsFrameType": LookinWireFormat.frameTypeJSON,
            "lkjsFrameTypeHex": "4C4B4A53",
            "wireVersionExpected": LookinWireFormat.version,
        ])
    }

    private func handleWireRoundtrip() -> MCPHTTPResponse {
        let info = LKHierarchyInfo.staticInfo(withLookinVersion: nil)
        let preCount = info.displayItems?.count ?? 0
        var attachment = LookinConnectionResponseAttachment()
        attachment.data = info

        do {
            guard let envelope = WireRequestResponseMapper.responseEnvelope(
                from: attachment,
                requestType: UInt32(LookinRequestTypeHierarchy),
                tag: 1
            ) else {
                return .error(message: "Wire hierarchy response mapper failed", statusCode: 500)
            }
            let jsonData = try LKWireCodecV2.encodeJSON(envelope)
            let decoded = try LKWireCodecV2.decodeJSON(WireResponseEnvelope.self, from: jsonData)
            var roundtripAttachment = LookinConnectionResponseAttachment()
            guard WireRequestResponseMapper.applyResponseEnvelope(decoded, to: &roundtripAttachment),
                  let hierarchy = roundtripAttachment.data as? LookinHierarchyInfo else {
                return .error(message: "Wire JSON roundtrip apply failed", statusCode: 500)
            }
            let postCount = hierarchy.displayItems?.count ?? 0
            return .ok(data: [
                "preArchiveRoots": preCount,
                "iosUnarchiveRoots": postCount,
                "wirePayloadBase64": jsonData.base64EncodedString(),
                "wireFormat": "json_v2",
            ])
        } catch {
            return .error(message: "Wire roundtrip failed: \(error.localizedDescription)", statusCode: 500)
        }
    }

    private func handleHierarchy() -> MCPHTTPResponse {
        let info = LKHierarchyInfo.staticInfo(withLookinVersion: nil)
        guard let items = info.displayItems, !items.isEmpty else {
            return .error(message: "Hierarchy is empty. Make sure the app is in the foreground.", statusCode: 503)
        }

        let serialized = items.map { serialize(item: $0) }
        return .ok(data: [
            "appName": info.appInfo?.appName ?? "",
            "items": serialized,
        ])
    }

    private func serialize(item: LKDisplayItem) -> [String: Any] {
        var dict: [String: Any] = [:]

        let displayObject = item.displayingObject()
        let oid = displayObject?.oid ?? 0
        dict["oid"] = oid

        dict["className"] = displayObject?.rawClassName() ?? ""
        if let memoryAddress = displayObject?.memoryAddress, !memoryAddress.isEmpty {
            dict["memoryAddress"] = memoryAddress
        }

        if item.isHidden { dict["hidden"] = true }
        if item.alpha < 0.999 { dict["alpha"] = item.alpha }

        let frame = item.frame
        dict["frame"] = [frame.origin.x, frame.origin.y, frame.size.width, frame.size.height]

        if let title = item.customDisplayTitle, !title.isEmpty {
            dict["customTitle"] = title
        }

        if let viewObject = item.viewObject,
           let view = NSObject.lks_object(withOid: viewObject.oid) as? UIView {
            dict["userInteractionEnabled"] = view.isUserInteractionEnabled
            dict["isControl"] = view is UIControl
            dict["gestureRecognizerCount"] = view.gestureRecognizers?.count ?? 0
        }

        let children = (item.subitems ?? []).map { serialize(item: $0) }
        dict["children"] = children
        return dict
    }

    private func handleGetAttributes(oid: UInt) -> MCPHTTPResponse {
        guard let obj = NSObject.lks_object(withOid: oid) else {
            return .error(message: "Object with oid \(oid) not found or already released", statusCode: 404)
        }

        let layer: CALayer?
        if let calayer = obj as? CALayer {
            layer = calayer
        } else if let view = obj as? UIView {
            layer = view.layer
        } else {
            layer = nil
        }

        guard let layer else {
            return .error(message: "Object is not a UIView or CALayer", statusCode: 400)
        }

        let groups = LKS_AttrGroupsMaker.attrGroups(for: layer) ?? []
        let groupsJSON = groups.map { group -> [String: Any] in
            var groupDict: [String: Any] = [
                "identifier": group.identifier ?? "",
                "title": group.userCustomTitle ?? group.identifier ?? "",
            ]

            let sections = (group.attrSections ?? []).map { section -> [String: Any] in
                let attrs = (section.attributes ?? []).compactMap { serialize(attribute: $0) }
                return [
                    "identifier": section.identifier ?? "",
                    "attributes": attrs,
                ]
            }
            groupDict["sections"] = sections
            return groupDict
        }

        return .ok(data: ["oid": oid, "groups": groupsJSON])
    }

    func serialize(attribute: LKAttribute) -> [String: Any]? {
        guard let identifier = attribute.identifier else { return nil }

        var dict: [String: Any] = [
            "identifier": identifier,
            "attrType": attribute.attrType.rawValue,
            "typeDescription": LookinAttrType.description(for: attribute.attrType.rawValue),
            "value": WireAttributeMapper.mcpJSONObject(from: attribute.value),
        ]

        if let title = attribute.displayTitle, !title.isEmpty {
            dict["displayTitle"] = title
        }
        return dict
    }

    private func handleModifyAttribute(oid: UInt, body: [String: Any]?) async -> MCPHTTPResponse {
        guard let body,
              body["setterSelector"] != nil,
              body["attrType"] != nil,
              body["value"] != nil else {
            return .error(message: "Required fields: setterSelector, attrType, value", statusCode: 400)
        }

        guard NSObject.lks_object(withOid: oid) != nil else {
            return .error(message: "Object with oid \(oid) not found", statusCode: 404)
        }

        var mod = LKAttributeModification()
        mod.clientReadableVersion = "mcp"
        mod.targetOid = oid
        mod.setterSelector = NSSelectorFromString(body["setterSelector"] as? String ?? "")
        let attrTypeRaw = (body["attrType"] as? NSNumber)?.intValue ?? 0
        mod.attrType = LKAttrType(rawValue: attrTypeRaw) ?? .none
        mod.value = WireAttributeMapper.lookinValue(fromMCPJSON: body["value"], attrType: mod.attrType)

        guard mod.value != nil else {
            return .error(message: "Failed to parse 'value' for the given attrType", statusCode: 400)
        }

        LookinDiagLog.log("MCP modify oid=\(oid) sel=\(body["setterSelector"] ?? "?") attrType=\(attrTypeRaw)")
        do {
            _ = try await LKS_InbuiltAttrModificationHandler.handleModification(mod)
            LookinDiagLog.log("MCP modify OK oid=\(oid)")
            return .ok(data: ["modified": true])
        } catch {
            LookinDiagLog.log("MCP modify FAIL oid=\(oid) \(error.localizedDescription)")
            return .error(message: error.localizedDescription, statusCode: 500)
        }
    }

    private func handleScreenshot(oid: UInt) -> MCPHTTPResponse {
        guard let obj = NSObject.lks_object(withOid: oid) else {
            return .error(message: "Object with oid \(oid) not found", statusCode: 404)
        }

        let layer: CALayer?
        if let view = obj as? UIView {
            layer = view.layer
        } else if let calayer = obj as? CALayer {
            layer = calayer
        } else {
            layer = nil
        }

        guard let layer else {
            return .error(message: "Object is not a UIView or CALayer", statusCode: 400)
        }

        let bounds = layer.bounds
        if bounds.isEmpty {
            return .error(message: "Layer has empty bounds, cannot capture screenshot", statusCode: 400)
        }

        UIGraphicsBeginImageContextWithOptions(bounds.size, false, UIScreen.main.scale)
        defer { UIGraphicsEndImageContext() }

        guard let ctx = UIGraphicsGetCurrentContext() else {
            return .error(message: "Failed to create graphics context", statusCode: 500)
        }

        layer.render(in: ctx)
        guard let image = UIGraphicsGetImageFromCurrentImageContext(),
              let pngData = image.pngData() else {
            return .error(message: "Failed to render layer", statusCode: 500)
        }

        return .ok(data: [
            "imageBase64": pngData.base64EncodedString(),
            "mimeType": "image/png",
            "width": bounds.width,
            "height": bounds.height,
        ])
    }

    // MARK: - GET /text-inputs

    private func handleTextInputs() -> MCPHTTPResponse {
        guard let keyWindow = LKS_MultiplatformAdapter.keyWindow() else {
            return .error(message: "No key window found", statusCode: 503)
        }
        var inputs: [[String: Any]] = []
        collectTextInputs(in: keyWindow, window: keyWindow, inputs: &inputs, maxResults: 100)
        return .ok(data: ["count": inputs.count, "inputs": inputs])
    }

    // MARK: - GET /tap-targets

    private func handleTapTargets() -> MCPHTTPResponse {
        guard let keyWindow = LKS_MultiplatformAdapter.keyWindow() else {
            return .error(message: "No key window found", statusCode: 503)
        }
        var targets: [[String: Any]] = []
        collectTapTargets(in: keyWindow, window: keyWindow, targets: &targets)
        return .ok(data: ["count": targets.count, "targets": targets])
    }

    private func collectTapTargets(in view: UIView, window: UIWindow, targets: inout [[String: Any]]) {
        if isCollectibleTapView(view) {
            if let info = tapTargetInfo(for: view, window: window) {
                targets.append(info)
            }
        }
        for subview in view.subviews {
            collectTapTargets(in: subview, window: window, targets: &targets)
        }
    }

    private func isCollectibleTapView(_ view: UIView) -> Bool {
        if view.isHidden || view.alpha < 0.05 || !view.isUserInteractionEnabled {
            return false
        }
        let bounds = view.bounds
        if bounds.width < 4 || bounds.height < 4 {
            return false
        }
        var ancestor: UIView? = view.superview
        while let current = ancestor {
            if current.isHidden || current.alpha < 0.05 {
                return false
            }
            ancestor = current.superview
        }
        return true
    }

    private func tapTargetInfo(for view: UIView, window: UIWindow) -> [String: Any]? {
        if let control = view as? UIControl {
            guard control.isEnabled, !hasEnabledAncestorControl(excluding: control) else {
                return nil
            }
            var dict = baseTapTargetDict(for: view, window: window)
            dict["action"] = "controlTap"
            dict["effect"] = "Fire UIControl touchUpInside (sendActions)"
            if let title = controlTitle(for: control), !title.isEmpty {
                dict["title"] = title
            }
            return dict
        }

        if hasEnabledTapGesture(on: view), !hasEnabledAncestorControl(excluding: view) {
            var dict = baseTapTargetDict(for: view, window: window)
            dict["action"] = "tapGesture"
            dict["effect"] = "Recognize UITapGestureRecognizer on this view"
            dict["tapGestureCount"] = enabledTapGestureCount(on: view)
            return dict
        }

        if view is UITableViewCell || view is UICollectionViewCell {
            var dict = baseTapTargetDict(for: view, window: window)
            dict["action"] = "cellTap"
            dict["effect"] = "Synthetic tap at cell center (may select row/item)"
            return dict
        }

        return nil
    }

    private func baseTapTargetDict(for view: UIView, window: UIWindow) -> [String: Any] {
        let oid = view.lks_registerOid()
        let frame = view.convert(view.bounds, to: window)
        var dict: [String: Any] = [
            "oid": oid,
            "className": NSStringFromClass(type(of: view)),
            "frame": [
                "x": frame.origin.x,
                "y": frame.origin.y,
                "width": frame.size.width,
                "height": frame.size.height,
            ],
        ]
        if let label = view.accessibilityLabel, !label.isEmpty {
            dict["accessibilityLabel"] = label
        }
        if let identifier = view.accessibilityIdentifier, !identifier.isEmpty {
            dict["accessibilityIdentifier"] = identifier
        }
        return dict
    }

    private func hasEnabledAncestorControl(excluding view: UIView) -> Bool {
        var ancestor = view.superview
        while let current = ancestor {
            if let control = current as? UIControl,
               control !== view,
               control.isEnabled,
               control.isUserInteractionEnabled,
               !control.isHidden {
                return true
            }
            ancestor = current.superview
        }
        return false
    }

    private func hasEnabledTapGesture(on view: UIView) -> Bool {
        enabledTapGestureCount(on: view) > 0
    }

    private func enabledTapGestureCount(on view: UIView) -> Int {
        guard let gestures = view.gestureRecognizers else { return 0 }
        return gestures.filter { gr in
            gr is UITapGestureRecognizer && gr.isEnabled
        }.count
    }

    func controlTitle(for control: UIControl) -> String? {
        if let button = control as? UIButton {
            if let title = button.currentTitle, !title.isEmpty {
                return title
            }
            if #available(iOS 15.0, *), let title = button.configuration?.title, !title.isEmpty {
                return title
            }
            return nil
        }
        if let textField = control as? UITextField {
            return textField.text ?? textField.placeholder
        }
        return control.accessibilityLabel
    }

    // MARK: - POST /tap

    func handleTap(body: [String: Any]?) -> MCPHTTPResponse {
        var tapPoint: CGPoint?

        // Priority 1: tap by oid
        if let oidValue = body?["oid"], !(oidValue is NSNull) {
            let oid = UInt(truncatingIfNeeded: (oidValue as? UInt64) ?? UInt64((oidValue as? Int) ?? 0))
            guard let obj = NSObject.lks_object(withOid: oid) else {
                return .error(message: "Object with oid \(oid) not found", statusCode: 404)
            }
            let view: UIView?
            if let v = obj as? UIView {
                view = v
            } else if let l = obj as? CALayer {
                view = l.lks_hostView
            } else {
                view = nil
            }
            guard let v = view else {
                return .error(message: "View is not attached to a window", statusCode: 400)
            }
            let window = (v as? UIWindow) ?? v.window
            guard let w = window else {
                return .error(message: "View is not attached to a window", statusCode: 400)
            }
            let boundsInWindow = v.convert(v.bounds, to: w)
            tapPoint = CGPoint(x: boundsInWindow.midX, y: boundsInWindow.midY)
        }

        // Priority 2: tap by x/y
        if tapPoint == nil {
            guard let x = body?["x"] as? CGFloat, let y = body?["y"] as? CGFloat else {
                return .error(message: "Provide either 'oid' or 'x'+'y' coordinates", statusCode: 400)
            }
            tapPoint = CGPoint(x: x, y: y)
        }

        let point = tapPoint!
        guard let keyWindow = LKS_MultiplatformAdapter.keyWindow() else {
            return .error(message: "No key window found", statusCode: 503)
        }
        if sendSyntheticTap(at: point, in: keyWindow) {
            return .ok(data: ["tapped": true, "x": point.x, "y": point.y])
        }
        return .error(message: "Failed to synthesize tap event", statusCode: 500)
    }

    // MARK: - POST /swipe

    private func handleSwipe(body: [String: Any]?) async -> MCPHTTPResponse {
        var fromPoint: CGPoint?
        var toPoint: CGPoint?

        // Priority 1: by oid + direction
        if let oidValue = body?["oid"], !(oidValue is NSNull) {
            let oid = UInt(truncatingIfNeeded: (oidValue as? UInt64) ?? UInt64((oidValue as? Int) ?? 0))
            guard let obj = NSObject.lks_object(withOid: oid) else {
                return .error(message: "Object with oid \(oid) not found", statusCode: 404)
            }
            let view: UIView?
            if let v = obj as? UIView { view = v }
            else if let l = obj as? CALayer { view = l.lks_hostView }
            else { view = nil }

            let window = (view as? UIWindow) ?? view?.window
            guard let v = view, window != nil else {
                return .error(message: "View is not attached to a window", statusCode: 400)
            }
            let boundsInWindow = v.convert(v.bounds, to: window)
            let midX = boundsInWindow.midX, midY = boundsInWindow.midY
            let w = boundsInWindow.width, h = boundsInWindow.height
            let fraction: CGFloat = 0.35
            let direction = (body?["direction"] as? String) ?? "up"
            switch direction {
            case "left":
                fromPoint = CGPoint(x: midX + w * fraction, y: midY)
                toPoint   = CGPoint(x: midX - w * fraction, y: midY)
            case "right":
                fromPoint = CGPoint(x: midX - w * fraction, y: midY)
                toPoint   = CGPoint(x: midX + w * fraction, y: midY)
            case "down":
                fromPoint = CGPoint(x: midX, y: midY - h * fraction)
                toPoint   = CGPoint(x: midX, y: midY + h * fraction)
            default: // "up"
                fromPoint = CGPoint(x: midX, y: midY + h * fraction)
                toPoint   = CGPoint(x: midX, y: midY - h * fraction)
            }
        }

        // Priority 2: explicit coordinates
        if fromPoint == nil {
            guard let fx = body?["fromX"] as? CGFloat, let fy = body?["fromY"] as? CGFloat,
                  let tx = body?["toX"] as? CGFloat,   let ty = body?["toY"] as? CGFloat else {
                return .error(
                    message: "Provide 'oid' (+ optional 'direction': up/down/left/right) or 'fromX'+'fromY'+'toX'+'toY'",
                    statusCode: 400
                )
            }
            fromPoint = CGPoint(x: fx, y: fy)
            toPoint   = CGPoint(x: tx, y: ty)
        }

        let from = fromPoint!, to = toPoint!
        var duration = (body?["duration"] as? TimeInterval) ?? 0.3
        duration = min(max(duration, 0.05), 3.0)

        guard let keyWindow = LKS_MultiplatformAdapter.keyWindow() else {
            return .error(message: "No key window found", statusCode: 503)
        }

        let hitView = keyWindow.hitTest(from, with: nil)
        var scrollView: UIScrollView?
        var candidate: UIView? = hitView
        while let c = candidate {
            if let sv = c as? UIScrollView { scrollView = sv; break }
            candidate = c.superview
        }

        if let sv = scrollView {
            let delta = CGPoint(x: from.x - to.x, y: from.y - to.y)
            let maxX = max(0, sv.contentSize.width - sv.bounds.width)
            let maxY = max(0, sv.contentSize.height - sv.bounds.height)
            let newOffset = CGPoint(
                x: min(max(sv.contentOffset.x + delta.x, 0), maxX),
                y: min(max(sv.contentOffset.y + delta.y, 0), maxY)
            )
            UIView.animate(withDuration: duration) { sv.contentOffset = newOffset }
            NSLog("LookinServer MCP - swipe ScrollView offset→(%.1f,%.1f)", newOffset.x, newOffset.y)
        } else if let view = hitView {
            var handled = false
            var responder: UIView? = view
            while let r = responder {
                for gr in r.gestureRecognizers ?? [] {
                    if gr is UIPanGestureRecognizer || gr is UISwipeGestureRecognizer {
                        let setSel = NSSelectorFromString("setState:")
                        if gr.responds(to: setSel) {
                            gr.perform(setSel, with: NSNumber(value: UIGestureRecognizer.State.recognized.rawValue))
                            handled = true
                            break
                        }
                    }
                }
                if handled { break }
                responder = r.superview
            }
            if !handled {
                view.touchesBegan([], with: UIEvent())
                view.touchesEnded([], with: UIEvent())
            }
            NSLog("LookinServer MCP - swipe synthetic on %@", NSStringFromClass(type(of: view)))
        }

        let settleDelay = duration + 0.05
        try? await Task.sleep(nanoseconds: UInt64(settleDelay * 1_000_000_000))
        return .ok(data: [
            "swiped": true,
            "fromX": from.x,
            "fromY": from.y,
            "toX": to.x,
            "toY": to.y,
            "duration": duration,
        ])
    }

    func sendSyntheticTap(at point: CGPoint, in window: UIWindow) -> Bool {
        let hitView = window.hitTest(point, with: nil)

        // Path 1: UIControl
        if let control = hitView as? UIControl {
            control.sendActions(for: .touchUpInside)
            NSLog("LookinServer MCP - tap UIControl %@ at (%.1f, %.1f)", NSStringFromClass(type(of: control)), point.x, point.y)
            return true
        }

        // Path 2: UITapGestureRecognizer
        var responder: UIView? = hitView
        while let r = responder {
            for gr in r.gestureRecognizers ?? [] {
                if gr is UITapGestureRecognizer {
                    let setSel = NSSelectorFromString("setState:")
                    if gr.responds(to: setSel) {
                        gr.perform(setSel, with: NSNumber(value: UIGestureRecognizer.State.recognized.rawValue))
                        NSLog("LookinServer MCP - tap UITapGestureRecognizer on %@", NSStringFromClass(type(of: r)))
                        return true
                    }
                }
            }
            responder = r.superview
        }

        // Path 3: direct touches callback
        if let view = hitView {
            view.touchesBegan([], with: UIEvent())
            view.touchesEnded([], with: UIEvent())
            NSLog("LookinServer MCP - tap via touchesBegan/Ended on %@", NSStringFromClass(type(of: view)))
            return true
        }

        return false
    }

    // MARK: - POST /type-text

    func handleTypeText(body: [String: Any]?) -> MCPHTTPResponse {
        guard let text = body?["text"] as? String, !text.isEmpty else {
            return .error(message: "Provide non-empty 'text'", statusCode: 400)
        }

        let replace = (body?["replace"] as? Bool) ?? true
        let focus = (body?["focus"] as? Bool) ?? true

        var inputView: UIView?
        if let oidValue = body?["oid"], !(oidValue is NSNull) {
            let oid = UInt(truncatingIfNeeded: (oidValue as? UInt64) ?? UInt64((oidValue as? Int) ?? 0))
            inputView = textInputView(forOid: oid)
            if inputView == nil {
                return .error(message: "No text input found for oid \(oid)", statusCode: 404)
            }
        } else {
            inputView = firstResponderTextInput()
            if inputView == nil {
                return .error(message: "No focused text field — provide 'oid' or tap a field first", statusCode: 400)
            }
        }

        guard let input = inputView else {
            return .error(message: "Text input not available", statusCode: 500)
        }

        if focus {
            _ = input.becomeFirstResponder()
        }

        if let textField = input as? UITextField {
            let newText = replace ? text : (textField.text ?? "") + text
            textField.text = newText
            textField.sendActions(for: .editingChanged)
            NSLog("LookinServer MCP - typeText UITextField %@", NSStringFromClass(type(of: textField)))
            return .ok(data: [
                "typed": true,
                "text": newText,
                "className": NSStringFromClass(type(of: textField)),
            ])
        }

        if let textView = input as? UITextView {
            let newText = replace ? text : (textView.text ?? "") + text
            textView.text = newText
            NotificationCenter.default.post(name: UITextView.textDidChangeNotification, object: textView)
            NSLog("LookinServer MCP - typeText UITextView %@", NSStringFromClass(type(of: textView)))
            return .ok(data: [
                "typed": true,
                "text": newText,
                "className": NSStringFromClass(type(of: textView)),
            ])
        }

        if let textInput = input as? UIResponder & UITextInput {
            let newText: String
            if replace {
                let start = textInput.beginningOfDocument
                let end = textInput.endOfDocument
                if let range = textInput.textRange(from: start, to: end) {
                    textInput.replace(range, withText: text)
                }
                newText = text
            } else {
                textInput.insertText(text)
                newText = currentTextContent(for: input) ?? text
            }
            NSLog("LookinServer MCP - typeText UITextInput %@", NSStringFromClass(type(of: input)))
            return .ok(data: [
                "typed": true,
                "text": newText,
                "className": NSStringFromClass(type(of: input)),
            ])
        }

        return .error(message: "Unsupported text input type", statusCode: 400)
    }

    // MARK: - POST /keyboard

    private func handleKeyboard(body: [String: Any]?) -> MCPHTTPResponse {
        let action = (body?["action"] as? String) ?? "dismiss"

        switch action {
        case "dismiss":
            guard let keyWindow = LKS_MultiplatformAdapter.keyWindow() else {
                return .error(message: "No key window found", statusCode: 503)
            }
            keyWindow.endEditing(true)
            NSLog("LookinServer MCP - keyboard dismiss")
            return .ok(data: ["keyboard": true, "action": "dismiss"])

        case "return":
            guard let textField = firstResponderTextInput() as? UITextField else {
                return .error(message: "No focused UITextField for return action", statusCode: 400)
            }
            var handled = false
            if let delegate = textField.delegate {
                handled = delegate.textFieldShouldReturn?(textField) ?? false
            }
            if !handled {
                _ = textField.resignFirstResponder()
            }
            NSLog("LookinServer MCP - keyboard return handled=%d", handled ? 1 : 0)
            return .ok(data: ["keyboard": true, "action": "return", "handled": handled])

        case "insert":
            guard let key = body?["key"] as? String, !key.isEmpty else {
                return .error(message: "Provide 'key' for insert action", statusCode: 400)
            }
            guard let input = firstResponderTextInput() as? UIResponder & UITextInput else {
                return .error(message: "No focused text input for insert", statusCode: 400)
            }
            input.insertText(key)
            NSLog("LookinServer MCP - keyboard insert len=%lu", key.count)
            return .ok(data: ["keyboard": true, "action": "insert", "inserted": key])

        case "delete":
            guard let input = firstResponderTextInput() as? UIResponder & UITextInput else {
                return .error(message: "No focused text input for delete", statusCode: 400)
            }
            input.deleteBackward()
            NSLog("LookinServer MCP - keyboard delete")
            return .ok(data: ["keyboard": true, "action": "delete"])

        default:
            return .error(
                message: "Unknown action '\(action)'. Use dismiss, return, insert, or delete",
                statusCode: 400
            )
        }
    }

    // MARK: - POST /long-press

    private func handleLongPress(body: [String: Any]?) async -> MCPHTTPResponse {
        guard let point = resolveWindowPoint(from: body) else {
            return .error(message: "Provide 'oid' or 'x'+'y' coordinates", statusCode: 400)
        }
        guard let keyWindow = LKS_MultiplatformAdapter.keyWindow() else {
            return .error(message: "No key window found", statusCode: 503)
        }

        var duration = doubleValue(from: body?["duration"]) ?? 0.6
        duration = min(max(duration, 0.2), 5.0)

        if await sendSyntheticLongPress(at: point, in: keyWindow, duration: duration) {
            return .ok(data: [
                "longPressed": true,
                "x": point.x,
                "y": point.y,
                "duration": duration,
            ])
        }
        return .error(message: "Failed to synthesize long press", statusCode: 500)
    }

    func view(forOid oid: UInt) -> UIView? {
        guard let obj = NSObject.lks_object(withOid: oid) else { return nil }
        if let v = obj as? UIView { return v }
        if let l = obj as? CALayer { return l.lks_hostView }
        return nil
    }

    func doubleValue(from value: Any?) -> Double? {
        if let v = value as? Double { return v }
        if let v = value as? Int { return Double(v) }
        if let v = value as? NSNumber { return v.doubleValue }
        if let v = value as? CGFloat { return Double(v) }
        return nil
    }

    func resolveWindowPoint(from body: [String: Any]?) -> CGPoint? {
        guard let body else { return nil }
        if let oidValue = body["oid"], !(oidValue is NSNull) {
            let oid = UInt(truncatingIfNeeded: (oidValue as? UInt64) ?? UInt64((oidValue as? Int) ?? 0))
            guard let view = view(forOid: oid) else { return nil }
            let window = (view as? UIWindow) ?? view.window
            guard let w = window else { return nil }
            let boundsInWindow = view.convert(view.bounds, to: w)
            return CGPoint(x: boundsInWindow.midX, y: boundsInWindow.midY)
        }
        if let x = doubleValue(from: body["x"]), let y = doubleValue(from: body["y"]) {
            return CGPoint(x: x, y: y)
        }
        return nil
    }

    private func textInputView(forOid oid: UInt) -> UIView? {
        guard let view = view(forOid: oid) else { return nil }
        if isTextInputView(view) { return view }
        return findTextInput(in: view)
    }

    private func findTextInput(in view: UIView) -> UIView? {
        if isTextInputView(view) { return view }
        for subview in view.subviews {
            if let found = findTextInput(in: subview) { return found }
        }
        return nil
    }

    private func firstResponderTextInput() -> UIView? {
        guard let keyWindow = LKS_MultiplatformAdapter.keyWindow() else { return nil }
        return findFirstResponderTextInput(in: keyWindow)
    }

    private func findFirstResponderTextInput(in view: UIView) -> UIView? {
        if view.isFirstResponder && isTextInputView(view) {
            return view
        }
        for subview in view.subviews {
            if let found = findFirstResponderTextInput(in: subview) { return found }
        }
        return nil
    }

    func sendSyntheticLongPress(at point: CGPoint, in window: UIWindow, duration: TimeInterval) async -> Bool {
        let hitView = window.hitTest(point, with: nil)
        let setSel = NSSelectorFromString("setState:")

        var responder: UIView? = hitView
        while let r = responder {
            for gr in r.gestureRecognizers ?? [] {
                if gr is UILongPressGestureRecognizer, gr.responds(to: setSel) {
                    gr.perform(setSel, with: NSNumber(value: UIGestureRecognizer.State.began.rawValue))
                    try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                    gr.perform(setSel, with: NSNumber(value: UIGestureRecognizer.State.ended.rawValue))
                    NSLog("LookinServer MCP - longPress UILongPressGestureRecognizer on %@", NSStringFromClass(type(of: r)))
                    return true
                }
            }
            responder = r.superview
        }

        if let view = hitView {
            view.touchesBegan([], with: UIEvent())
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            view.touchesEnded([], with: UIEvent())
            NSLog("LookinServer MCP - longPress touches on %@", NSStringFromClass(type(of: view)))
            return true
        }

        return false
    }
}
#endif
