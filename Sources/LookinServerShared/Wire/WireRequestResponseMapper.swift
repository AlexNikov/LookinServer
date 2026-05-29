import Foundation

public enum WireRequestResponseMapper {
    // MARK: - Requests (client → server)

    public static func requestEnvelope(
        requestType: UInt32,
        tag: UInt32,
        data: Any?
    ) -> WireRequestEnvelope {
        var envelope = WireRequestEnvelope(requestType: requestType, tag: tag)
        switch requestType {
        case UInt32(LookinRequestTypePing):
            break
        case UInt32(LookinRequestTypeHierarchy):
            envelope.hierarchyParams = hierarchyParams(from: data)
        case UInt32(LookinRequestTypeHierarchyDetails):
            envelope.detailPackages = WireAsyncTaskMapper.wirePackages(from: data) ?? []
        case UInt32(LookinRequestTypeAttrModificationPatch):
            envelope.patchTasks = WireAsyncTaskMapper.wirePatchTasks(from: data) ?? []
        case UInt32(LookinRequestTypeApp):
            envelope.appParams = appParams(from: data)
        case UInt32(LookinRequestTypeFetchObject),
             UInt32(LookinRequestTypeAllAttrGroups),
             UInt32(LookinRequestTypeFetchImageViewImage):
            envelope.oid = (data as? NSNumber)?.uintValue
        case UInt32(LookinRequestTypeAllSelectorNames):
            if let dict = data as? [String: Any], let className = dict["className"] as? String {
                let hasArg = (dict["hasArg"] as? NSNumber)?.boolValue ?? (dict["hasArg"] as? Bool) ?? false
                envelope.selectorQuery = WireSelectorQueryParams(className: className, hasArg: hasArg)
            }
        case UInt32(LookinRequestTypeInvokeMethod):
            if let dict = data as? [String: Any],
               let text = dict["text"] as? String {
                let oid = (dict["oid"] as? NSNumber)?.uintValue ?? 0
                envelope.invokeParams = WireInvokeParams(oid: oid, text: text)
            }
        case UInt32(LookinRequestTypeModifyRecognizerEnable):
            if let dict = data as? [String: NSNumber] {
                let oid = dict["oid"]?.uintValue ?? 0
                let enable = dict["enable"]?.boolValue ?? false
                envelope.recognizerParams = WireRecognizerParams(oid: oid, enable: enable)
            }
        case UInt32(LookinRequestTypeInbuiltAttrModification):
            if let mod = data as? LookinAttributeModification {
                envelope.inbuiltModification = wireModification(from: mod)
            }
        case UInt32(LookinRequestTypeCustomAttrModification):
            if let mod = data as? LookinCustomAttrModification {
                envelope.customModification = wireCustomModification(from: mod)
            }
        default:
            break
        }
        return envelope
    }

    public static func requestObject(from envelope: WireRequestEnvelope) -> Any? {
        switch envelope.requestType {
        case UInt32(LookinRequestTypePing):
            return nil
        case UInt32(LookinRequestTypeHierarchy):
            var params: [String: Any] = [:]
            if let clientVersion = envelope.hierarchyParams?.clientVersion {
                params["clientVersion"] = clientVersion
            }
            return params
        case UInt32(LookinRequestTypeHierarchyDetails):
            return (envelope.detailPackages ?? []).map { WireAsyncTaskMapper.lookinPackage(from: $0) }
        case UInt32(LookinRequestTypeAttrModificationPatch):
            return (envelope.patchTasks ?? []).map { WireAsyncTaskMapper.lookinTask(from: $0) }
        case UInt32(LookinRequestTypeApp):
            guard let appParams = envelope.appParams else { return nil }
            var dict: [String: Any] = ["needImages": appParams.needImages]
            if let locals = appParams.localIdentifiers {
                dict["local"] = locals.map { NSNumber(value: $0) }
            }
            return dict
        case UInt32(LookinRequestTypeFetchObject),
             UInt32(LookinRequestTypeAllAttrGroups),
             UInt32(LookinRequestTypeFetchImageViewImage):
            guard let oid = envelope.oid else { return nil }
            return NSNumber(value: oid)
        case UInt32(LookinRequestTypeAllSelectorNames):
            guard let query = envelope.selectorQuery else { return nil }
            return ["className": query.className, "hasArg": query.hasArg] as [String: Any]
        case UInt32(LookinRequestTypeInvokeMethod):
            guard let invoke = envelope.invokeParams else { return nil }
            return ["oid": NSNumber(value: invoke.oid), "text": invoke.text] as [String: Any]
        case UInt32(LookinRequestTypeModifyRecognizerEnable):
            guard let params = envelope.recognizerParams else { return nil }
            return ["oid": NSNumber(value: params.oid), "enable": NSNumber(value: params.enable)] as [String: NSNumber]
        case UInt32(LookinRequestTypeInbuiltAttrModification):
            guard let wire = envelope.inbuiltModification else { return nil }
            return lookinModification(from: wire)
        case UInt32(LookinRequestTypeCustomAttrModification):
            guard let wire = envelope.customModification else { return nil }
            return lookinCustomModification(from: wire)
        default:
            return nil
        }
    }

    // MARK: - Responses (server → client)

    public static func responseEnvelope(
        from attachment: LookinConnectionResponseAttachment,
        requestType: UInt32,
        tag: UInt32
    ) -> WireResponseEnvelope? {
        if let error = attachment.error {
            return WireResponseEnvelope(
                requestType: requestType,
                tag: tag,
                error: WireErrorPayload(code: error.code, message: error.localizedDescription)
            )
        }

        if requestType == UInt32(LookinRequestTypePing) {
            return WireResponseEnvelope(
                requestType: requestType,
                tag: tag,
                ping: WirePingPayload(appIsInBackground: attachment.appIsInBackground)
            )
        }

        if let info = attachment.data as? LookinHierarchyInfo {
            return WireResponseEnvelope(
                requestType: requestType,
                tag: tag,
                hierarchy: WireHierarchyMapper.wirePayload(from: info)
            )
        }

        if let detail = attachment.data as? LookinDisplayItemDetail {
            return WireResponseEnvelope(
                requestType: requestType,
                tag: tag,
                detail: WireHierarchyMapper.wireDetail(from: detail),
                dataTotalCount: attachment.dataTotalCount > 0 ? attachment.dataTotalCount : nil,
                currentDataCount: attachment.currentDataCount > 0 ? attachment.currentDataCount : nil
            )
        }

        if let app = attachment.data as? LookinAppInfo {
            return WireResponseEnvelope(requestType: requestType, tag: tag, app: wireAppInfo(from: app))
        }

        if let object = attachment.data as? LookinObject {
            return WireResponseEnvelope(requestType: requestType, tag: tag, object: wireObject(from: object))
        }

        if let groups = attachment.data as? [LookinAttributesGroup] {
            return WireResponseEnvelope(
                requestType: requestType,
                tag: tag,
                attributeGroups: groups.map { WireAttributeMapper.wireGroup(from: $0) }
            )
        }

        if let groups = attachment.data as? NSArray {
            let list = groups.compactMap { $0 as? LookinAttributesGroup }
            if !list.isEmpty {
                return WireResponseEnvelope(
                    requestType: requestType,
                    tag: tag,
                    attributeGroups: list.map { WireAttributeMapper.wireGroup(from: $0) }
                )
            }
        }

        if let names = attachment.data as? [String] {
            return WireResponseEnvelope(requestType: requestType, tag: tag, stringList: names)
        }

        if let names = attachment.data as? NSArray {
            let list = names.compactMap { $0 as? String }
            if !list.isEmpty {
                return WireResponseEnvelope(requestType: requestType, tag: tag, stringList: list)
            }
        }

        if let dict = attachment.data as? [String: Any] {
            var description: String?
            var object: WireObjectPayload?
            if let desc = dict["description"] as? String {
                description = desc
            } else if let desc = dict["description"] as? NSString {
                description = desc as String
            }
            if let obj = dict["object"] as? LookinObject {
                object = wireObject(from: obj)
            }
            return WireResponseEnvelope(
                requestType: requestType,
                tag: tag,
                invokeResult: WireInvokeResultPayload(description: description, object: object)
            )
        }

        if let data = attachment.data as? Data {
            return WireResponseEnvelope(
                requestType: requestType,
                tag: tag,
                pngDataBase64: data.base64EncodedString()
            )
        }

        if let data = attachment.data as? NSData {
            return WireResponseEnvelope(
                requestType: requestType,
                tag: tag,
                pngDataBase64: (data as Data).base64EncodedString()
            )
        }

        if let number = attachment.data as? NSNumber {
            return WireResponseEnvelope(requestType: requestType, tag: tag, boolValue: number.boolValue)
        }

        if attachment.data == nil || attachment.data is NSNull {
            return WireResponseEnvelope(requestType: requestType, tag: tag)
        }

        return nil
    }

    public static func applyResponseEnvelope(
        _ envelope: WireResponseEnvelope,
        to attachment: LookinConnectionResponseAttachment
    ) -> Bool {
        if let error = envelope.error {
            attachment.error = NSError(
                domain: "LookinWireV2",
                code: error.code,
                userInfo: [NSLocalizedDescriptionKey: error.message ?? "Wire error"]
            )
            return true
        }

        if let ping = envelope.ping {
            attachment.appIsInBackground = ping.appIsInBackground
            return true
        }

        if let hierarchy = envelope.hierarchy {
            attachment.data = WireHierarchyMapper.lookinHierarchy(from: hierarchy)
            return true
        }

        if let wireDetail = envelope.detail {
            attachment.data = WireHierarchyMapper.lookinDetail(from: wireDetail)
            if let total = envelope.dataTotalCount {
                attachment.dataTotalCount = total
            }
            if let current = envelope.currentDataCount {
                attachment.currentDataCount = current
            }
            return true
        }

        if let app = envelope.app {
            attachment.data = lookinAppInfo(from: app)
            return true
        }

        if let object = envelope.object {
            attachment.data = lookinObject(from: object)
            return true
        }

        if let groups = envelope.attributeGroups {
            attachment.data = groups.map { WireAttributeMapper.lookinGroup(from: $0) }
            return true
        }

        if let strings = envelope.stringList {
            attachment.data = strings as NSArray
            return true
        }

        if let invoke = envelope.invokeResult {
            var dict: [String: Any] = [:]
            if let description = invoke.description {
                dict["description"] = description
            }
            if let object = invoke.object {
                dict["object"] = lookinObject(from: object)
            }
            attachment.data = dict as NSDictionary
            return true
        }

        if let base64 = envelope.pngDataBase64, let data = Data(base64Encoded: base64) {
            attachment.data = data as NSData
            return true
        }

        if let boolValue = envelope.boolValue {
            attachment.data = NSNumber(value: boolValue)
            return true
        }

        // Wire v2 ACK with no body (e.g. CustomAttrModification success).
        attachment.data = nil
        return true
    }

    // MARK: - Private helpers

    private static func hierarchyParams(from data: Any?) -> WireHierarchyRequestParams {
        var params = WireHierarchyRequestParams(minWireVersion: LookinWireFormat.version)
        if let dict = data as? [String: Any] {
            if let clientVersion = dict["clientVersion"] as? String {
                params.clientVersion = clientVersion
            }
            if let minWire = dict["minWireVersion"] as? Int {
                params.minWireVersion = minWire
            } else if let minWire = (dict["minWireVersion"] as? NSNumber)?.intValue {
                params.minWireVersion = minWire
            }
        }
        return params
    }

    private static func appParams(from data: Any?) -> WireAppRequestParams? {
        guard let dict = data as? [String: Any] else { return nil }
        let needImages = (dict["needImages"] as? NSNumber)?.boolValue ?? (dict["needImages"] as? Bool) ?? false
        var locals: [UInt]?
        if let numbers = dict["local"] as? [NSNumber] {
            locals = numbers.map(\.uintValue)
        } else if let numbers = dict["local"] as? NSArray {
            locals = numbers.compactMap { ($0 as? NSNumber)?.uintValue }
        }
        return WireAppRequestParams(needImages: needImages, localIdentifiers: locals)
    }

    public static func wireModification(from mod: LookinAttributeModification) -> WireAttributeModificationPayload {
        WireAttributeModificationPayload(
            targetOid: mod.targetOid,
            setterSelector: NSStringFromSelector(mod.setterSelector),
            attrType: mod.attrType.rawValue,
            value: WireAttributeMapper.wireValue(from: mod.value),
            clientReadableVersion: mod.clientReadableVersion,
            attrIdentifier: mod.attrIdentifier
        )
    }

    public static func lookinModification(from wire: WireAttributeModificationPayload) -> LookinAttributeModification {
        var mod = LookinAttributeModification()
        mod.targetOid = wire.targetOid
        mod.setterSelector = NSSelectorFromString(wire.setterSelector)
        mod.attrIdentifier = wire.attrIdentifier
        let attrType = LookinAttrType(rawValue: wire.attrType) ?? .none
        mod.attrType = attrType
        mod.value = WireAttributeMapper.lookinValue(from: wire.value, attrType: attrType)
        mod.clientReadableVersion = wire.clientReadableVersion
        return mod
    }

    public static func wireCustomModification(from mod: LookinCustomAttrModification) -> WireCustomAttrModificationPayload {
        WireCustomAttrModificationPayload(
            attrType: mod.attrType.rawValue,
            customSetterID: mod.customSetterID,
            value: WireAttributeMapper.wireValue(from: mod.value)
        )
    }

    public static func lookinCustomModification(from wire: WireCustomAttrModificationPayload) -> LookinCustomAttrModification {
        var mod = LookinCustomAttrModification()
        let attrType = LookinAttrType(rawValue: wire.attrType) ?? .none
        mod.attrType = attrType
        mod.customSetterID = wire.customSetterID
        mod.value = WireAttributeMapper.lookinValue(from: wire.value, attrType: attrType)
        return mod
    }

    public static func wireAppInfo(from app: LookinAppInfo) -> WireAppInfoPayload {
        WireAppInfoPayload(
            appInfoIdentifier: app.appInfoIdentifier,
            shouldUseCache: app.shouldUseCache,
            serverVersion: app.serverVersion,
            serverReadableVersion: app.serverReadableVersion,
            swiftEnabledInLookinServer: app.swiftEnabledInLookinServer,
            appName: app.appName,
            appBundleIdentifier: app.appBundleIdentifier,
            deviceDescription: app.deviceDescription,
            osDescription: app.osDescription,
            osMainVersion: app.osMainVersion,
            deviceType: app.deviceType.rawValue,
            screenWidth: app.screenWidth,
            screenHeight: app.screenHeight,
            screenScale: app.screenScale,
            screenshotPNGBase64: app.screenshot.flatMap { $0.lookin_pngData()?.base64EncodedString() },
            appIconPNGBase64: app.appIcon.flatMap { $0.lookin_pngData()?.base64EncodedString() }
        )
    }

    public static func lookinAppInfo(from wire: WireAppInfoPayload) -> LookinAppInfo {
        let app = LookinAppInfo()
        app.appInfoIdentifier = wire.appInfoIdentifier
        app.shouldUseCache = wire.shouldUseCache
        app.serverVersion = wire.serverVersion
        app.serverReadableVersion = wire.serverReadableVersion
        app.swiftEnabledInLookinServer = wire.swiftEnabledInLookinServer
        app.appName = wire.appName
        app.appBundleIdentifier = wire.appBundleIdentifier
        app.deviceDescription = wire.deviceDescription
        app.osDescription = wire.osDescription
        app.osMainVersion = wire.osMainVersion
        app.deviceType = LookinAppInfoDevice(rawValue: wire.deviceType) ?? .others
        app.screenWidth = wire.screenWidth
        app.screenHeight = wire.screenHeight
        app.screenScale = wire.screenScale
        if let base64 = wire.screenshotPNGBase64, let data = Data(base64Encoded: base64) {
            app.screenshot = LookinImage.lookin_image(with: data)
        }
        if let base64 = wire.appIconPNGBase64, let data = Data(base64Encoded: base64) {
            app.appIcon = LookinImage.lookin_image(with: data)
        }
        return app
    }

    public static func wireObject(from object: LookinObject) -> WireObjectPayload {
        WireObjectPayload(
            oid: object.oid,
            memoryAddress: object.memoryAddress,
            classChainList: object.classChainList,
            specialTrace: object.specialTrace
        )
    }

    public static func lookinObject(from wire: WireObjectPayload) -> LookinObject {
        let object = LookinObject()
        object.oid = wire.oid
        object.memoryAddress = wire.memoryAddress
        object.classChainList = wire.classChainList
        object.specialTrace = wire.specialTrace
        return object
    }
}
