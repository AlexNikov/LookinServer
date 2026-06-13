#if SHOULD_COMPILE_LOOKIN_SERVER
import Foundation
import UIKit
#if canImport(LookinShared)
import LookinShared
#endif

@MainActor
extension MCPHTTPHandler {

    // MARK: - Search / hit-test

    func handleFindView(body: [String: Any]?) -> MCPHTTPResponse {
        guard let keyWindow = LKS_MultiplatformAdapter.keyWindow() else {
            return .error(message: "No key window found", statusCode: 503)
        }
        let maxResults = min(max(Int((body?["maxResults"] as? NSNumber)?.intValue ?? 20), 1), 100)
        var matches: [[String: Any]] = []
        collectMatchingViews(in: keyWindow, window: keyWindow, body: body, matches: &matches, maxResults: maxResults)
        return .ok(data: ["count": matches.count, "matches": matches])
    }

    func handleViewAtPoint(body: [String: Any]?) -> MCPHTTPResponse {
        guard let x = doubleValue(from: body?["x"]), let y = doubleValue(from: body?["y"]) else {
            return .error(message: "Provide 'x' and 'y'", statusCode: 400)
        }
        guard let keyWindow = LKS_MultiplatformAdapter.keyWindow() else {
            return .error(message: "No key window found", statusCode: 503)
        }
        let point = CGPoint(x: x, y: y)
        guard let hit = keyWindow.hitTest(point, with: nil) else {
            return .ok(data: ["found": false, "x": x, "y": y])
        }
        return .ok(data: [
            "found": true,
            "x": x,
            "y": y,
            "view": viewSummary(for: hit, window: keyWindow),
        ])
    }

    func handleTapByLabel(body: [String: Any]?) -> MCPHTTPResponse {
        let findResponse = handleFindView(body: body)
        guard findResponse.statusCode == 200,
              let data = findResponse.jsonBody["data"] as? [String: Any],
              let matches = data["matches"] as? [[String: Any]],
              let first = matches.first,
              let oid = first["oid"] as? UInt64 ?? (first["oid"] as? Int).map({ UInt64($0) }) else {
            return .error(message: "No matching view found for tap-by-label criteria", statusCode: 404)
        }
        return handleTap(body: ["oid": oid])
    }

    func handleWaitForView(body: [String: Any]?) async -> MCPHTTPResponse {
        var timeout = doubleValue(from: body?["timeout"]) ?? 10.0
        timeout = min(max(timeout, 0.5), 60.0)
        let interval = 0.3
        let start = Date()
        while Date().timeIntervalSince(start) < timeout {
            let result = handleFindView(body: body)
            if result.statusCode == 200,
               let data = result.jsonBody["data"] as? [String: Any],
               let count = data["count"] as? Int, count > 0 {
                return .ok(data: [
                    "found": true,
                    "elapsed": Date().timeIntervalSince(start),
                    "matches": data["matches"] ?? [],
                ])
            }
            try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
        }
        return .ok(data: ["found": false, "elapsed": timeout])
    }

    // MARK: - Gestures

    func handleDoubleTap(body: [String: Any]?) async -> MCPHTTPResponse {
        guard let point = resolveWindowPoint(from: body) else {
            return .error(message: "Provide 'oid' or 'x'+'y'", statusCode: 400)
        }
        guard let keyWindow = LKS_MultiplatformAdapter.keyWindow() else {
            return .error(message: "No key window found", statusCode: 503)
        }
        guard sendSyntheticTap(at: point, in: keyWindow) else {
            return .error(message: "First tap failed", statusCode: 500)
        }
        try? await Task.sleep(nanoseconds: 120_000_000)
        guard sendSyntheticTap(at: point, in: keyWindow) else {
            return .error(message: "Second tap failed", statusCode: 500)
        }
        return .ok(data: ["doubleTapped": true, "x": point.x, "y": point.y])
    }

    func handlePinch(body: [String: Any]?) -> MCPHTTPResponse {
        guard let point = resolveWindowPoint(from: body) else {
            return .error(message: "Provide 'oid' or 'x'+'y'", statusCode: 400)
        }
        guard let keyWindow = LKS_MultiplatformAdapter.keyWindow() else {
            return .error(message: "No key window found", statusCode: 503)
        }
        let direction = (body?["direction"] as? String) ?? "out"
        let factor = doubleValue(from: body?["scale"]) ?? (direction == "in" ? 1.5 : 0.67)

        if let scrollView = scrollView(at: point, in: keyWindow) {
            var newScale = scrollView.zoomScale * CGFloat(factor)
            newScale = min(max(newScale, scrollView.minimumZoomScale), scrollView.maximumZoomScale)
            scrollView.setZoomScale(newScale, animated: true)
            return .ok(data: [
                "pinched": true,
                "zoomScale": newScale,
                "className": NSStringFromClass(type(of: scrollView)),
            ])
        }

        let hitView = keyWindow.hitTest(point, with: nil)
        let setSel = NSSelectorFromString("setState:")
        var responder: UIView? = hitView
        while let r = responder {
            for gr in r.gestureRecognizers ?? [] {
                if gr is UIPinchGestureRecognizer, gr.responds(to: setSel) {
                    gr.perform(setSel, with: NSNumber(value: UIGestureRecognizer.State.began.rawValue))
                    gr.perform(setSel, with: NSNumber(value: UIGestureRecognizer.State.changed.rawValue))
                    gr.perform(setSel, with: NSNumber(value: UIGestureRecognizer.State.ended.rawValue))
                    return .ok(data: ["pinched": true, "method": "UIPinchGestureRecognizer"])
                }
            }
            responder = r.superview
        }
        return .error(message: "No UIScrollView or UIPinchGestureRecognizer at point", statusCode: 404)
    }

    func handleScroll(body: [String: Any]?) -> MCPHTTPResponse {
        var targetScrollView: UIScrollView?
        if let oidValue = body?["oid"], !(oidValue is NSNull) {
            let oid = UInt(truncatingIfNeeded: (oidValue as? UInt64) ?? UInt64((oidValue as? Int) ?? 0))
            if let view = view(forOid: oid) {
                targetScrollView = findScrollView(in: view) ?? view as? UIScrollView
            }
        } else if let x = doubleValue(from: body?["x"]), let y = doubleValue(from: body?["y"]),
                  let keyWindow = LKS_MultiplatformAdapter.keyWindow() {
            targetScrollView = scrollView(at: CGPoint(x: x, y: y), in: keyWindow)
        }
        guard let sv = targetScrollView else {
            return .error(message: "Provide scroll view 'oid' or point 'x'+'y'", statusCode: 400)
        }

        var offset = sv.contentOffset
        if let offsetX = doubleValue(from: body?["offsetX"]), let offsetY = doubleValue(from: body?["offsetY"]) {
            offset = CGPoint(x: offsetX, y: offsetY)
        } else {
            let delta = doubleValue(from: body?["delta"]) ?? 120
            let direction = (body?["direction"] as? String) ?? "down"
            switch direction {
            case "up": offset.y -= CGFloat(delta)
            case "left": offset.x -= CGFloat(delta)
            case "right": offset.x += CGFloat(delta)
            default: offset.y += CGFloat(delta)
            }
        }
        let maxX = max(0, sv.contentSize.width - sv.bounds.width)
        let maxY = max(0, sv.contentSize.height - sv.bounds.height)
        offset.x = min(max(offset.x, 0), maxX)
        offset.y = min(max(offset.y, 0), maxY)
        let animated = (body?["animated"] as? Bool) ?? true
        sv.setContentOffset(offset, animated: animated)
        return .ok(data: [
            "scrolled": true,
            "contentOffset": ["x": offset.x, "y": offset.y],
            "className": NSStringFromClass(type(of: sv)),
        ])
    }

    // MARK: - Controls / text

    func handleToggle(body: [String: Any]?) -> MCPHTTPResponse {
        guard let oidValue = body?["oid"], !(oidValue is NSNull) else {
            return .error(message: "Provide 'oid'", statusCode: 400)
        }
        let oid = UInt(truncatingIfNeeded: (oidValue as? UInt64) ?? UInt64((oidValue as? Int) ?? 0))
        guard let view = view(forOid: oid) else {
            return .error(message: "Object with oid \(oid) not found", statusCode: 404)
        }

        if let sw = view as? UISwitch {
            let on = (body?["on"] as? Bool) ?? !sw.isOn
            sw.setOn(on, animated: true)
            sw.sendActions(for: .valueChanged)
            return .ok(data: ["toggled": true, "type": "UISwitch", "on": on])
        }

        if let seg = view as? UISegmentedControl {
            let segment: Int
            if let index = (body?["segment"] as? NSNumber)?.intValue {
                segment = index
            } else {
                segment = (seg.selectedSegmentIndex + 1) % max(seg.numberOfSegments, 1)
            }
            guard segment >= 0, segment < seg.numberOfSegments else {
                return .error(message: "Invalid segment index", statusCode: 400)
            }
            seg.selectedSegmentIndex = segment
            seg.sendActions(for: .valueChanged)
            return .ok(data: ["toggled": true, "type": "UISegmentedControl", "segment": segment])
        }

        return .error(message: "View is not UISwitch or UISegmentedControl", statusCode: 400)
    }

    func handleSelectRow(body: [String: Any]?) -> MCPHTTPResponse {
        guard let oidValue = body?["oid"], !(oidValue is NSNull) else {
            return .error(message: "Provide table/collection 'oid'", statusCode: 400)
        }
        let oid = UInt(truncatingIfNeeded: (oidValue as? UInt64) ?? UInt64((oidValue as? Int) ?? 0))
        guard let view = view(forOid: oid) else {
            return .error(message: "Object with oid \(oid) not found", statusCode: 404)
        }
        let section = (body?["section"] as? NSNumber)?.intValue ?? 0
        let row = (body?["row"] as? NSNumber)?.intValue ?? 0
        let indexPath = IndexPath(row: row, section: section)

        if let table = view as? UITableView {
            guard section < table.numberOfSections, row < table.numberOfRows(inSection: section) else {
                return .error(message: "IndexPath out of range", statusCode: 400)
            }
            table.selectRow(at: indexPath, animated: true, scrollPosition: .middle)
            table.delegate?.tableView?(table, didSelectRowAt: indexPath)
            return .ok(data: ["selected": true, "type": "UITableView", "section": section, "row": row])
        }

        if let collection = view as? UICollectionView {
            collection.selectItem(at: indexPath, animated: true, scrollPosition: .centeredVertically)
            collection.delegate?.collectionView?(collection, didSelectItemAt: indexPath)
            return .ok(data: ["selected": true, "type": "UICollectionView", "section": section, "row": row])
        }

        return .error(message: "View is not UITableView or UICollectionView", statusCode: 400)
    }

    func handleClearText(body: [String: Any]?) -> MCPHTTPResponse {
        var bodyCopy = body ?? [:]
        bodyCopy["text"] = ""
        bodyCopy["replace"] = true
        return handleTypeText(body: bodyCopy)
    }

    // MARK: - Inspector / runtime

    func handleCustomInfo(oid: UInt) -> MCPHTTPResponse {
        guard let layer = layer(forOid: oid) else {
            return .error(message: "Object with oid \(oid) not found", statusCode: 404)
        }
        let maker = LKS_CustomAttrGroupsMaker(layer: layer)
        maker.execute()
        let groups = (maker.getGroups() as NSArray?) as? [LookinAttributesGroup] ?? []
        return .ok(data: [
            "oid": oid,
            "customDisplayTitle": maker.getCustomDisplayTitle() ?? "",
            "groups": serializeAttrGroups(groups),
        ])
    }

    func handleHierarchyDetails(oid: UInt) -> MCPHTTPResponse {
        guard let layer = layer(forOid: oid) else {
            return .error(message: "Object with oid \(oid) not found", statusCode: 404)
        }
        let inbuilt = LKS_AttrGroupsMaker.attrGroups(for: layer) ?? []
        let maker = LKS_CustomAttrGroupsMaker(layer: layer)
        maker.execute()
        let custom = (maker.getGroups() as NSArray?) as? [LookinAttributesGroup] ?? []
        var data: [String: Any] = [
            "oid": oid,
            "frame": ["x": layer.frame.origin.x, "y": layer.frame.origin.y,
                      "width": layer.frame.width, "height": layer.frame.height],
            "hidden": layer.isHidden,
            "alpha": layer.opacity,
            "attributesGroupList": serializeAttrGroups(inbuilt),
            "customAttrGroupList": serializeAttrGroups(custom),
            "customDisplayTitle": maker.getCustomDisplayTitle() ?? "",
        ]
        if let obj = NSObject.lks_object(withOid: oid) {
            data["className"] = NSStringFromClass(type(of: obj))
            if let view = obj as? UIView {
                data.merge(mcpViewInteractionFields(for: view)) { _, new in new }
            } else {
                data["enabled"] = true
            }
        }
        return .ok(data: data)
    }

    func handleAllProperties(oid: UInt) -> MCPHTTPResponse {
        guard let obj = NSObject.lks_object(withOid: oid) else {
            return .error(message: "Object with oid \(oid) not found or already released", statusCode: 404)
        }
        guard let layer = layer(forOid: oid) else {
            return .error(message: "Object is not a UIView or CALayer", statusCode: 400)
        }

        let inbuilt = LKS_AttrGroupsMaker.attrGroups(for: layer) ?? []
        let maker = LKS_CustomAttrGroupsMaker(layer: layer)
        maker.execute()
        let custom = (maker.getGroups() as NSArray?) as? [LookinAttributesGroup] ?? []
        let inbuiltGroups = serializeAttrGroups(inbuilt)
        let customGroups = serializeAttrGroups(custom)

        var data: [String: Any] = [
            "oid": oid,
            "className": NSStringFromClass(type(of: obj)),
            "frame": [
                "x": layer.frame.origin.x,
                "y": layer.frame.origin.y,
                "width": layer.frame.width,
                "height": layer.frame.height,
            ],
            "hidden": layer.isHidden,
            "alpha": layer.opacity,
            "inbuiltGroups": inbuiltGroups,
            "customGroups": customGroups,
            "customDisplayTitle": maker.getCustomDisplayTitle() ?? "",
            "allAttributes": flattenSerializedAttributes(
                inbuiltGroups: inbuiltGroups,
                customGroups: customGroups
            ),
        ]
        if let view = obj as? UIView {
            data.merge(mcpViewInteractionFields(for: view)) { _, new in new }
        } else {
            data["enabled"] = true
        }
        return .ok(data: data)
    }

    func handleModifyCustomAttribute(oid: UInt, body: [String: Any]?) -> MCPHTTPResponse {
        guard NSObject.lks_object(withOid: oid) != nil else {
            return .error(message: "Object with oid \(oid) not found", statusCode: 404)
        }
        guard let body,
              let setterID = body["customSetterID"] as? String, !setterID.isEmpty,
              body["attrType"] != nil else {
            return .error(message: "Required: customSetterID, attrType, value?", statusCode: 400)
        }
        var mod = LookinCustomAttrModification()
        let attrTypeRaw = (body["attrType"] as? NSNumber)?.intValue ?? 0
        mod.attrType = LookinAttrType(rawValue: attrTypeRaw) ?? .none
        mod.customSetterID = setterID
        if body["value"] != nil {
            mod.value = WireAttributeMapper.lookinValue(fromMCPJSON: body["value"], attrType: mod.attrType)
        }
        let ok = LKS_CustomAttrModificationHandler.handleModification(mod)
        if ok {
            return .ok(data: ["modified": true, "customSetterID": setterID])
        }
        return .error(message: "Custom attribute modification failed", statusCode: 500)
    }

    func handleInvokeMethod(body: [String: Any]?) -> MCPHTTPResponse {
        guard let body,
              let oidValue = body["oid"], !(oidValue is NSNull),
              let selectorName = body["selector"] as? String, !selectorName.isEmpty else {
            return .error(message: "Required: oid, selector", statusCode: 400)
        }
        let oid = UInt(truncatingIfNeeded: (oidValue as? UInt64) ?? UInt64((oidValue as? Int) ?? 0))
        guard let targetObj = NSObject.lks_object(withOid: oid) else {
            return .error(message: "Object with oid \(oid) not found", statusCode: 404)
        }
        let targetSelector = NSSelectorFromString(selectorName)
        guard targetSelector != NSSelectorFromString(""), targetObj.responds(to: targetSelector) else {
            return .error(
                message: "\(NSStringFromClass(type(of: targetObj))) does not respond to \(selectorName)",
                statusCode: 400
            )
        }
        var resultDescription: NSString?
        var resultObject: LookinObject?
        var error: NSError?
        LKS_ConnectionRuntimeBridge.handleInvoke(
            with: targetObj,
            selector: targetSelector,
            resultDescription: &resultDescription,
            resultObject: &resultObject,
            error: &error
        )
        if let error {
            return .error(message: error.localizedDescription, statusCode: 500)
        }
        var data: [String: Any] = ["invoked": true, "selector": selectorName]
        if let resultDescription {
            data["description"] = resultDescription
        }
        if let resultObject {
            data["resultOid"] = resultObject.oid
            data["resultClassName"] = resultObject.rawClassName() ?? ""
        }
        return .ok(data: data)
    }

    func handleSelectors(body: [String: Any]?) -> MCPHTTPResponse {
        guard let className = body?["className"] as? String, !className.isEmpty,
              let targetClass = NSClassFromString(className) else {
            return .error(message: "Provide valid 'className'", statusCode: 400)
        }
        let hasArg = (body?["hasArg"] as? Bool) ?? false
        let names = LKS_ConnectionRuntimeBridge.methodNameList(for: targetClass, hasArg: hasArg)
        return .ok(data: ["className": className, "hasArg": hasArg, "selectors": names])
    }

    // MARK: - Helpers

    func mcpEnabled(for view: UIView) -> Bool {
        (view as? UIControl)?.isEnabled ?? true
    }

    func mcpViewInteractionFields(for view: UIView) -> [String: Any] {
        [
            "enabled": mcpEnabled(for: view),
            "userInteractionEnabled": view.isUserInteractionEnabled,
            "isControl": view is UIControl,
            "gestureRecognizerCount": view.gestureRecognizers?.count ?? 0,
        ]
    }

    func mcpAttributeMetaFields(for attribute: LKAttribute) -> [String: Any] {
        var fields: [String: Any] = [:]
        if attribute.isUserCustom() || !(attribute.customSetterID ?? "").isEmpty {
            let customSetterID = attribute.customSetterID ?? ""
            fields["enabled"] = !customSetterID.isEmpty
            if !customSetterID.isEmpty {
                fields["customSetterID"] = customSetterID
            }
            fields["source"] = "custom"
        } else if let identifier = attribute.identifier {
            if let setter = LookinDashboardBlueprint.setter(withAttrID: identifier) {
                fields["enabled"] = true
                fields["setterSelector"] = NSStringFromSelector(setter)
            } else {
                fields["enabled"] = false
            }
            fields["source"] = "inbuilt"
        } else {
            fields["enabled"] = false
            fields["source"] = "inbuilt"
        }
        return fields
    }

    func flattenSerializedAttributes(
        inbuiltGroups: [[String: Any]],
        customGroups: [[String: Any]]
    ) -> [[String: Any]] {
        var flat: [[String: Any]] = []
        appendSerializedAttributes(from: inbuiltGroups, source: "inbuilt", into: &flat)
        appendSerializedAttributes(from: customGroups, source: "custom", into: &flat)
        return flat
    }

    private func appendSerializedAttributes(
        from groups: [[String: Any]],
        source: String,
        into flat: inout [[String: Any]]
    ) {
        for group in groups {
            let groupIdentifier = group["identifier"] as? String ?? ""
            let groupTitle = group["title"] as? String ?? ""
            guard let sections = group["sections"] as? [[String: Any]] else { continue }
            for section in sections {
                let sectionIdentifier = section["identifier"] as? String ?? ""
                guard let attributes = section["attributes"] as? [[String: Any]] else { continue }
                for var attribute in attributes {
                    attribute["source"] = source
                    attribute["groupIdentifier"] = groupIdentifier
                    attribute["groupTitle"] = groupTitle
                    attribute["sectionIdentifier"] = sectionIdentifier
                    flat.append(attribute)
                }
            }
        }
    }

    func layer(forOid oid: UInt) -> CALayer? {
        guard let obj = NSObject.lks_object(withOid: oid) else { return nil }
        if let layer = obj as? CALayer { return layer }
        if let view = obj as? UIView { return view.layer }
        return nil
    }

    func serializeAttrGroups(_ groups: [LookinAttributesGroup]) -> [[String: Any]] {
        groups.map { group -> [String: Any] in
            var groupDict: [String: Any] = [
                "identifier": group.identifier ?? "",
                "title": group.userCustomTitle ?? group.identifier ?? "",
            ]
            let sections = (group.attrSections ?? []).map { section -> [String: Any] in
                let attrs = (section.attributes ?? []).compactMap { serialize(attribute: $0) }
                return ["identifier": section.identifier ?? "", "attributes": attrs]
            }
            groupDict["sections"] = sections
            return groupDict
        }
    }

    func scrollView(at point: CGPoint, in window: UIWindow) -> UIScrollView? {
        let hit = window.hitTest(point, with: nil)
        var candidate: UIView? = hit
        while let c = candidate {
            if let sv = c as? UIScrollView { return sv }
            candidate = c.superview
        }
        return nil
    }

    func findScrollView(in view: UIView) -> UIScrollView? {
        if let sv = view as? UIScrollView { return sv }
        for sub in view.subviews {
            if let found = findScrollView(in: sub) { return found }
        }
        return nil
    }

    func collectMatchingViews(
        in view: UIView,
        window: UIWindow,
        body: [String: Any]?,
        matches: inout [[String: Any]],
        maxResults: Int
    ) {
        if matches.count >= maxResults { return }
        if viewMatchesCriteria(view, body: body), !view.isHidden, view.alpha > 0.05 {
            matches.append(viewSummary(for: view, window: window))
        }
        for subview in view.subviews {
            collectMatchingViews(in: subview, window: window, body: body, matches: &matches, maxResults: maxResults)
            if matches.count >= maxResults { return }
        }
    }

    func viewMatchesCriteria(_ view: UIView, body: [String: Any]?) -> Bool {
        guard let body else { return false }
        let className = NSStringFromClass(type(of: view))
        if let exact = body["className"] as? String, !exact.isEmpty, className != exact {
            return false
        }
        if let contains = body["classNameContains"] as? String, !contains.isEmpty,
           !className.localizedCaseInsensitiveContains(contains) {
            return false
        }
        if let id = body["accessibilityIdentifier"] as? String, !id.isEmpty,
           view.accessibilityIdentifier != id {
            return false
        }
        if let label = body["accessibilityLabel"] as? String, !label.isEmpty {
            guard let viewLabel = view.accessibilityLabel, viewLabel.localizedCaseInsensitiveContains(label) else {
                return false
            }
        }
        if let title = body["title"] as? String, !title.isEmpty {
            let viewTitle = controlTitle(for: view) ?? ""
            if !viewTitle.localizedCaseInsensitiveContains(title) { return false }
        }
        if let text = body["textContains"] as? String, !text.isEmpty {
            var texts: [String] = []
            if let tf = view as? UITextField {
                texts.append(tf.text ?? "")
                texts.append(tf.placeholder ?? "")
            }
            if let tv = view as? UITextView { texts.append(tv.text ?? "") }
            if let btn = view as? UIButton { texts.append(btn.currentTitle ?? "") }
            texts.append(view.accessibilityLabel ?? "")
            let joined = texts.joined(separator: " ")
            if !joined.localizedCaseInsensitiveContains(text) { return false }
        }
        return body["className"] != nil || body["classNameContains"] != nil
            || body["accessibilityIdentifier"] != nil || body["accessibilityLabel"] != nil
            || body["title"] != nil || body["textContains"] != nil
    }

    func viewSummary(for view: UIView, window: UIWindow) -> [String: Any] {
        let frame = view.convert(view.bounds, to: window)
        var dict: [String: Any] = [
            "oid": view.lks_registerOid(),
            "className": NSStringFromClass(type(of: view)),
            "frame": ["x": frame.origin.x, "y": frame.origin.y,
                      "width": frame.size.width, "height": frame.size.height],
        ]
        dict.merge(mcpViewInteractionFields(for: view)) { _, new in new }
        if let label = view.accessibilityLabel, !label.isEmpty { dict["accessibilityLabel"] = label }
        if let id = view.accessibilityIdentifier, !id.isEmpty { dict["accessibilityIdentifier"] = id }
        if let title = controlTitle(for: view), !title.isEmpty { dict["title"] = title }
        return dict
    }

    func controlTitle(for view: UIView) -> String? {
        if let control = view as? UIControl { return controlTitle(for: control) }
        return view.accessibilityLabel
    }

    // MARK: - Text inputs

    func isTextInputView(_ view: UIView) -> Bool {
        if view is UITextField || view is UITextView { return true }
        guard let responder = view as? UIResponder else { return false }
        return responder.conforms(to: UITextInput.self)
    }

    func textInputKind(for view: UIView) -> String {
        if view is UITextField { return "UITextField" }
        if view is UITextView { return "UITextView" }
        let className = NSStringFromClass(type(of: view))
        if className.contains("TextField") || className.contains("_UITextField") {
            return "SwiftUITextField"
        }
        if className.contains("TextEditor") || className.contains("TextView") {
            return "SwiftUITextView"
        }
        return "UITextInput"
    }

    func currentTextContent(for view: UIView) -> String? {
        if let textField = view as? UITextField {
            return textField.text
        }
        if let textView = view as? UITextView {
            return textView.text
        }
        if let textInput = view as? UIResponder & UITextInput {
            let start = textInput.beginningOfDocument
            let end = textInput.endOfDocument
            if let range = textInput.textRange(from: start, to: end) {
                return textInput.text(in: range)
            }
        }
        return nil
    }

    func placeholderForTextInput(_ view: UIView) -> String? {
        if let textField = view as? UITextField {
            return textField.placeholder
        }
        return nil
    }

    func isEditableTextInput(_ view: UIView) -> Bool {
        if let textField = view as? UITextField {
            return textField.isEnabled
        }
        if let textView = view as? UITextView {
            return textView.isEditable
        }
        return true
    }

    func isCollectibleTextInputView(_ view: UIView) -> Bool {
        guard isTextInputView(view) else { return false }
        if view.isHidden || view.alpha < 0.05 { return false }
        let bounds = view.bounds
        if bounds.width < 4 || bounds.height < 4 { return false }
        var ancestor: UIView? = view.superview
        while let current = ancestor {
            if current.isHidden || current.alpha < 0.05 {
                return false
            }
            ancestor = current.superview
        }
        return true
    }

    func collectTextInputs(
        in view: UIView,
        window: UIWindow,
        inputs: inout [[String: Any]],
        maxResults: Int
    ) {
        if inputs.count >= maxResults { return }
        if isCollectibleTextInputView(view), let summary = textInputSummary(for: view, window: window) {
            inputs.append(summary)
        }
        for subview in view.subviews {
            collectTextInputs(in: subview, window: window, inputs: &inputs, maxResults: maxResults)
            if inputs.count >= maxResults { return }
        }
    }

    func textInputSummary(for view: UIView, window: UIWindow) -> [String: Any]? {
        guard isTextInputView(view) else { return nil }
        let frame = view.convert(view.bounds, to: window)
        var dict: [String: Any] = [
            "oid": view.lks_registerOid(),
            "className": NSStringFromClass(type(of: view)),
            "inputKind": textInputKind(for: view),
            "text": currentTextContent(for: view) ?? "",
            "isFirstResponder": view.isFirstResponder,
            "isEditable": isEditableTextInput(view),
            "enabled": mcpEnabled(for: view),
            "frame": [
                "x": frame.origin.x,
                "y": frame.origin.y,
                "width": frame.size.width,
                "height": frame.size.height,
            ],
        ]
        if let placeholder = placeholderForTextInput(view), !placeholder.isEmpty {
            dict["placeholder"] = placeholder
        }
        if let label = view.accessibilityLabel, !label.isEmpty {
            dict["accessibilityLabel"] = label
        }
        if let identifier = view.accessibilityIdentifier, !identifier.isEmpty {
            dict["accessibilityIdentifier"] = identifier
        }
        return dict
    }
}
#endif
