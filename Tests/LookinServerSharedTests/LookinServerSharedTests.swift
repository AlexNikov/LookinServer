import XCTest
@testable import LookinServer

final class LookinServerSharedTests: XCTestCase {
    func testObjCExceptionBridgeCatchesRaisedException() {
        let exception = LookinObjCExceptionBridge.catchException {
            NSException(name: NSExceptionName.genericException, reason: "lookin-test", userInfo: nil).raise()
        }
        XCTAssertNotNil(exception)
        XCTAssertEqual(exception?.reason, "lookin-test")
    }

    func testObjCExceptionBridgeTryExecuteThrowsNSError() {
        XCTAssertThrowsError(try LookinObjCExceptionBridge.tryExecute {
            NSException(name: NSExceptionName.genericException, reason: "setter-fail", userInfo: nil).raise()
        }) { error in
            let ns = error as NSError
            XCTAssertEqual(ns.domain, LookinErrorDomain)
            XCTAssertEqual(ns.code, LookinSharedErrCode.exception.rawValue)
            XCTAssertEqual(ns.localizedRecoverySuggestion, "setter-fail")
        }
    }

    func testLookinAttrTypeMapping() {
        XCTAssertEqual(LookinAttrTypeMapping.description(for: 14), "BOOL")
        XCTAssertEqual(LookinAttrTypeMapping.description(for: 20), "CGRect")
        XCTAssertEqual(LookinAttrType.description(for: 14), "BOOL")
        XCTAssertEqual(LookinAttrType(rawValue: 20)?.typeDescription, "CGRect")
    }

    func testLookinObjectWireRoundTrip() throws {
        let obj = LookinObject()
        obj.oid = 42
        obj.memoryAddress = "0xdeadbeef"
        obj.classChainList = ["UILabel", "UIView"]

        let wire = WireRequestResponseMapper.wireObject(from: obj)
        let restored = WireRequestResponseMapper.lookinObject(from: wire)
        XCTAssertEqual(restored.oid, 42)
        XCTAssertEqual(restored.rawClassName(), "UILabel")
    }

    func testLookinAttributeWireRoundTrip() throws {
        let attr = LookinAttribute()
        attr.identifier = "test_id"
        attr.displayTitle = "Title"
        attr.attrType = .CGRect
        attr.value = .cgRect(CGRect(x: 1, y: 2, width: 3, height: 4))

        let wire = WireAttributeMapper.wireAttribute(from: attr)
        let decoded = WireAttributeMapper.lookinAttribute(from: wire)
        XCTAssertEqual(decoded.identifier, "test_id")
        XCTAssertEqual(decoded.attrType, .CGRect)
    }

    func testObjectRegistryAssignsOidAndResolvesObject() {
        let registry = LKS_ObjectRegistry.sharedInstance
        let object = NSObject()
        let oid = registry.addObject(object)
        XCTAssertGreaterThan(oid, 0)
        XCTAssertIdentical(registry.objectWithOid(oid), object)
    }

    func testObjectRegistryReturnsNilForInvalidOid() {
        let registry = LKS_ObjectRegistry.sharedInstance
        XCTAssertNil(registry.objectWithOid(999_999))
    }

    func testHierarchyResponseJSONRoundTrip() throws {
        let child = LookinDisplayItem()
        child.frame = CGRect(x: 1, y: 2, width: 3, height: 4)
        child.bounds = CGRect(x: 0, y: 0, width: 3, height: 4)
        child.viewObject = {
            let object = LookinObject()
            object.oid = 7
            object.memoryAddress = "0x1"
            object.classChainList = ["UIView", "UIResponder"]
            return object
        }()

        let root = LookinDisplayItem()
        root.subitems = [child]
        root.frame = CGRect(x: 0, y: 0, width: 320, height: 568)
        root.bounds = root.frame
        root.viewObject = {
            let object = LookinObject()
            object.oid = 1
            object.memoryAddress = "0x10"
            object.classChainList = ["UIWindow", "UIView"]
            return object
        }()

        let hierarchy = LookinHierarchyInfo()
        hierarchy.serverVersion = lookinServerVersionInt32
        hierarchy.displayItems = [root]
        hierarchy.collapsedClassList = ["UITableViewCell"]
        hierarchy.colorAlias = ["systemBlue": NSNumber(value: 0x007AFF)]

        var attachment = LookinConnectionResponseAttachment()
        attachment.data = hierarchy
        attachment.lookinServerVersion = lookinServerVersionInt32

        let envelope = try XCTUnwrap(
            WireRequestResponseMapper.responseEnvelope(
                from: attachment,
                requestType: UInt32(LookinRequestTypeHierarchy),
                tag: 1
            )
        )
        let jsonData = try LKWireCodecV2.encodeJSON(envelope)
        let decodedEnvelope = try LKWireCodecV2.decodeJSON(WireResponseEnvelope.self, from: jsonData)
        var roundtrip = LookinConnectionResponseAttachment()
        XCTAssertTrue(WireRequestResponseMapper.applyResponseEnvelope(decodedEnvelope, to: &roundtrip))

        let info = roundtrip.data as? LookinHierarchyInfo
        XCTAssertNotNil(info)
        XCTAssertEqual(info?.displayItems?.count, 1)
        XCTAssertEqual(info?.displayItems?.first?.subitems?.count, 1)
        XCTAssertEqual(info?.displayItems?.first?.subitems?.first?.frame, child.frame)
        XCTAssertEqual(info?.displayItems?.first?.subitems?.first?.viewObject?.oid, 7)
        XCTAssertEqual(LookinDisplayItem.flatItems(fromHierarchicalItems: info?.displayItems ?? []).count, 2)
    }

    func testWireAttributeMapperRoundTrip() throws {
        let attr = LookinAttribute()
        attr.identifier = "frame"
        attr.displayTitle = "Frame"
        attr.attrType = .CGRect
        attr.value = .cgRect(CGRect(x: 1, y: 2, width: 3, height: 4))

        let wire = WireAttributeMapper.wireAttribute(from: attr)
        let decoded = WireAttributeMapper.lookinAttribute(from: wire)
        XCTAssertEqual(decoded.identifier, "frame")
        XCTAssertEqual(decoded.attrType, .CGRect)
        guard case .cgRect(let rect)? = decoded.value else {
            XCTFail("expected cgRect value")
            return
        }
        XCTAssertEqual(rect, CGRect(x: 1, y: 2, width: 3, height: 4))
    }

    func testWireDetailPayloadRoundTrip() throws {
        let attr = LookinAttribute()
        attr.identifier = "hidden"
        attr.displayTitle = "Hidden"
        attr.attrType = .BOOL
        attr.value = .bool(true)

        var section = LookinAttributesSection()
        section.identifier = "sec"
        section.attributes = [attr]

        var group = LookinAttributesGroup()
        group.identifier = "group"
        group.attrSections = [section]

        var detail = LookinDisplayItemDetail()
        detail.displayItemOid = 99
        detail.customDisplayTitle = "Title"
        detail.attributesGroupList = [group]
        detail.frameValue = LookinGeometryCoding.nsValue(from: CGRect(x: 0, y: 0, width: 10, height: 20))

        let payload = WireDetailMapper.wireDetail(from: detail)
        let data = try JSONEncoder().encode(
            WireResponseEnvelope(requestType: 203, tag: 1, detail: payload)
        )
        let envelope = try JSONDecoder().decode(WireResponseEnvelope.self, from: data)
        let restored = WireDetailMapper.lookinDetail(from: try XCTUnwrap(envelope.detail))

        XCTAssertEqual(restored.displayItemOid, 99)
        XCTAssertEqual(restored.customDisplayTitle, "Title")
        XCTAssertEqual(restored.attributesGroupList?.count, 1)
        XCTAssertEqual(restored.attributesGroupList?.first?.attrSections?.first?.attributes?.first?.identifier, "hidden")
        XCTAssertEqual(restored.frameValue?.lookinCGRectValue.width, 10)
    }

    func testWireAppInfoRoundTrip() throws {
        let app = LookinAppInfo()
        app.appName = "Demo"
        app.serverVersion = 10004
        app.deviceType = .simulator
        app.screenWidth = 390
        app.screenHeight = 844

        let wire = WireRequestResponseMapper.wireAppInfo(from: app)
        let data = try JSONEncoder().encode(
            WireResponseEnvelope(requestType: 201, tag: 1, app: wire)
        )
        let envelope = try JSONDecoder().decode(WireResponseEnvelope.self, from: data)
        var attachment = LookinConnectionResponseAttachment()
        XCTAssertTrue(WireRequestResponseMapper.applyResponseEnvelope(try XCTUnwrap(envelope), to: &attachment))
        let restored = attachment.data as? LookinAppInfo
        XCTAssertEqual(restored?.appName, "Demo")
        XCTAssertEqual(restored?.deviceType, .simulator)
    }

    func testWirePingResponseRoundTrip() throws {
        var attachment = LookinConnectionResponseAttachment()
        attachment.appIsInBackground = true
        let wire = try XCTUnwrap(
            WireRequestResponseMapper.responseEnvelope(from: attachment, requestType: 200, tag: 1)
        )
        XCTAssertEqual(wire.ping?.appIsInBackground, true)
        var decoded = LookinConnectionResponseAttachment()
        XCTAssertTrue(WireRequestResponseMapper.applyResponseEnvelope(wire, to: &decoded))
        XCTAssertTrue(decoded.appIsInBackground)
    }

    func testWirePushEnvelopeRoundTrip() throws {
        let envelope = WirePushEnvelope(pushType: LookinWirePushTypes.cancelHierarchyDetails)
        let data = try JSONEncoder().encode(envelope)
        let decoded = try JSONDecoder().decode(WirePushEnvelope.self, from: data)
        XCTAssertEqual(decoded.pushType, 304)
    }

    func testWireHierarchyPayloadPreservesAppInfo() throws {
        let app = LookinAppInfo()
        app.screenWidth = 393
        app.screenHeight = 852
        app.screenScale = 3

        let info = LookinHierarchyInfo()
        info.serverVersion = lookinServerVersionInt32
        info.appInfo = app
        info.displayItems = []

        let payload = WireHierarchyMapper.wirePayload(from: info)
        let restored = WireHierarchyMapper.lookinHierarchy(from: payload)
        XCTAssertEqual(restored.appInfo?.screenWidth, 393)
        XCTAssertEqual(restored.appInfo?.screenHeight, 852)
        XCTAssertEqual(restored.appInfo?.screenScale, 3)
    }

    func testWireLookinFileRoundTrip() throws {
        let root = LookinDisplayItem()
        root.frame = CGRect(x: 0, y: 0, width: 320, height: 568)
        root.bounds = root.frame
        root.viewObject = {
            let object = LookinObject()
            object.oid = 1
            object.classChainList = ["UIWindow"]
            return object
        }()

        let info = LookinHierarchyInfo()
        info.serverVersion = lookinServerVersionInt32
        info.displayItems = [root]
        let app = LookinAppInfo()
        app.screenWidth = 320
        app.screenHeight = 568
        info.appInfo = app

        var file = LookinHierarchyFile()
        file.serverVersion = info.serverVersion
        file.hierarchyInfo = info
        file.soloScreenshots = [NSNumber(value: 1): Data([0x01, 0x02])]

        let data = try WireLookinFileCodec.data(from: file)
        XCTAssertTrue(WireLookinFileCodec.isV2Format(data))
        let restored = try WireLookinFileCodec.lookinHierarchyFile(from: data)
        XCTAssertEqual(restored.serverVersion, file.serverVersion)
        XCTAssertEqual(restored.soloScreenshots?[NSNumber(value: 1)], Data([0x01, 0x02]))
        XCTAssertEqual(restored.hierarchyInfo?.displayItems?.count, 1)
        XCTAssertEqual(restored.hierarchyInfo?.appInfo?.screenWidth, 320)
        XCTAssertEqual(restored.hierarchyInfo?.appInfo?.screenHeight, 568)
    }

    func testLookinJSONAttributeSupportInvalidJSON() {
        let state = LookinJSONAttributeSupport.dashboardParseState(from: "{not json")
        guard case .invalid(let message) = state else {
            XCTFail("expected invalid, got \(state)")
            return
        }
        XCTAssertTrue(message.contains("Malformed"))
    }

    func testLookinJSONAttributeSupportWrongSchema() {
        let state = LookinJSONAttributeSupport.dashboardParseState(from: #"{"only":"object"}"#)
        guard case .valid = state else {
            XCTFail("single object is wrapped as one row")
            return
        }
        let badArray = LookinJSONAttributeSupport.dashboardParseState(from: "123")
        guard case .invalid = badArray else {
            XCTFail("scalar JSON should be invalid for tree schema")
            return
        }
    }

    func testLookinJSONAttributeSupportTreeFromWireJSONKind() throws {
        let doc = #"[[{"title":"root","desc":"v","details":[]}]]"#
        let wire = WireAttrValue.json(doc)
        let attrValue = WireAttributeMapper.lookinValue(from: wire, attrType: .json)
        let roots = LookinJSONAttributeSupport.lookinTreeRootArray(from: attrValue)
        XCTAssertEqual(roots?.count, 1)
        XCTAssertEqual(roots?.first?["title"] as? String, "root")
    }

    func testLookinJSONAttributeSupportRawStringDocument() throws {
        let doc = #"[[{"title":"raw","desc":"ok"}]]"#
        let wire = WireAttrValue.string(doc)
        let attrValue = WireAttributeMapper.lookinValue(from: wire, attrType: .json)
        guard case .json(let docValue)? = attrValue else {
            XCTFail("expected json attribute value")
            return
        }
        XCTAssertEqual(docValue, doc)
        XCTAssertEqual(LookinJSONAttributeSupport.lookinTreeRootArray(from: attrValue)?.first?["title"] as? String, "raw")
    }

    func testWireJSONAttributeRoundTrip() throws {
        let jsonText = #"{"name":"Dog","count":3}"#
        let attr = LookinAttribute()
        attr.identifier = "dogJson"
        attr.attrType = .json
        attr.value = .json(jsonText)

        let wire = WireAttributeMapper.wireAttribute(from: attr)
        guard case .json(let encodedDoc)? = wire.value else {
            XCTFail("expected json wire value")
            return
        }
        XCTAssertEqual(encodedDoc, jsonText)

        let data = try LKWireCodecV2.encodeJSON(wire)
        let decodedWire = try LKWireCodecV2.decodeJSON(WireAttribute.self, from: data)
        guard case .json = decodedWire.value else {
            XCTFail("expected json wire value after decode")
            return
        }

        let restored = WireAttributeMapper.lookinAttribute(from: decodedWire)
        XCTAssertEqual(restored.attrType, .json)
        guard case .json(let restoredText)? = restored.value else {
            XCTFail("expected json attribute value")
            return
        }
        XCTAssertEqual(restoredText, jsonText)

        let mcpObject = WireAttributeMapper.mcpJSONObject(from: .json(jsonText)) as? [String: Any]
        XCTAssertEqual(mcpObject?["name"] as? String, "Dog")
        XCTAssertEqual(mcpObject?["count"] as? Int, 3)
    }

    func testWireClientRequestPayloadHierarchy() throws {
        let payload = WireClientRequestPayload.hierarchy(
            WireHierarchyRequestParams(clientVersion: "1.0.0", minWireVersion: 2)
        )
        let envelope = payload.envelope(requestType: UInt32(LookinRequestTypeHierarchy), tag: 7)
        let data = try LKWireCodecV2.encodeJSON(envelope)
        let decoded = try LKWireCodecV2.decodeJSON(WireRequestEnvelope.self, from: data)
        XCTAssertEqual(decoded.tag, 7)
        XCTAssertEqual(decoded.hierarchyParams?.minWireVersion, 2)
        XCTAssertEqual(decoded.hierarchyParams?.clientVersion, "1.0.0")
    }

    func testWireCustomObjectAttributeRoundTrip() {
        let attr = LookinAttribute()
        attr.attrType = .customObj
        let opaque = NSObject()
        attr.value = .customObject(opaque)

        let wire = WireAttributeMapper.wireAttribute(from: attr)
        guard case .custom = wire.value else {
            XCTFail("expected custom wire value")
            return
        }

        let restored = WireAttributeMapper.lookinAttribute(from: wire)
        XCTAssertEqual(restored.attrType, .customObj)
        guard case .string(let summary)? = restored.value else {
            XCTFail("expected string summary for custom object")
            return
        }
        XCTAssertEqual(summary, String(describing: opaque))
    }

    func testWireClassAttributeRoundTrip() {
        let attr = LookinAttribute()
        attr.identifier = LookinAttr_Class_Class_Class
        attr.attrType = .customObj
        let classChains: [[String]] = [
            ["UIView", "UIResponder", "NSObject"],
            ["LookinCollectionLayoutDemo.LKCollectionLayoutDemoViewController", "UIViewController", "UIResponder", "NSObject"],
        ]
        attr.value = .customObject(classChains)

        let wire = WireAttributeMapper.wireAttribute(from: attr)
        guard case .stringGroups = wire.value else {
            XCTFail("expected stringGroups wire value")
            return
        }

        let restored = WireAttributeMapper.lookinAttribute(from: wire)
        XCTAssertEqual(restored.attrType, .customObj)
        guard case .customObject(let restoredChains)? = restored.value,
              case .customObject(let originalChains)? = attr.value else {
            XCTFail("expected stringGroups custom object")
            return
        }
        XCTAssertEqual(restoredChains as? [[String]], originalChains as? [[String]])
    }

    func testWireRelationAttributeRoundTrip() {
        let attr = LookinAttribute()
        attr.identifier = LookinAttr_Relation_Relation_Relation
        attr.attrType = .customObj
        let relations = [
            "(LookinCollectionLayoutDemo.LKCollectionLayoutDemoViewController *).view",
            "(UIWindow *) -> _delegateViewController",
            "(UIWindow *) -> _rootViewController",
        ]
        attr.value = .customObject(relations)

        let wire = WireAttributeMapper.wireAttribute(from: attr)
        guard case .strings = wire.value else {
            XCTFail("expected strings wire value")
            return
        }

        let restored = WireAttributeMapper.lookinAttribute(from: wire)
        XCTAssertEqual(restored.attrType, .customObj)
        guard case .customObject(let restoredRelations)? = restored.value,
              case .customObject(let originalRelations)? = attr.value else {
            XCTFail("expected strings custom object")
            return
        }
        XCTAssertEqual(restoredRelations as? [String], originalRelations as? [String])
    }

    func testWireDisplayItemObjectMetadataAndBackgroundColorRoundTrip() {
        var ivarTrace = LookinIvarTrace()
        ivarTrace.hostClassName = "LKDemoLeftRailView"
        ivarTrace.ivarName = "leftRail"

        let viewObject = LookinObject()
        viewObject.oid = 13
        viewObject.classChainList = ["UILabel", "UIView", "UIResponder", "NSObject"]
        viewObject.memoryAddress = "0x600001a2b3c0"
        viewObject.specialTrace = "{ item:1, sec:0 }"
        viewObject.ivarTraces = [ivarTrace]

        let item = LookinDisplayItem()
        item.frame = CGRect(x: 0, y: 0, width: 120, height: 44)
        item.bounds = item.frame
        item.viewObject = viewObject
        item.backgroundColor = LookinColor(red: 1, green: 1, blue: 1, alpha: 1)

        let wire = WireHierarchyMapper.wireItem(from: item)
        XCTAssertEqual(wire.backgroundColorRGBA?.count, 4)
        XCTAssertEqual(wire.viewRef?.specialTrace, "{ item:1, sec:0 }")
        XCTAssertEqual(wire.viewRef?.ivarTraces?.first?.ivarName, "leftRail")

        let restored = WireHierarchyMapper.lookinItem(from: wire)
        XCTAssertEqual(restored.backgroundColor?.lookin_rgbaComponents.map(\.doubleValue), [1, 1, 1, 1])
        XCTAssertEqual(restored.viewObject?.specialTrace, "{ item:1, sec:0 }")
        XCTAssertEqual(restored.viewObject?.ivarTraces?.first?.ivarName, "leftRail")

        var wireWithoutBackground = wire
        wireWithoutBackground.backgroundColorRGBA = nil
        XCTAssertNil(WireHierarchyMapper.lookinItem(from: wireWithoutBackground).backgroundColor)
    }

    func testWireDisplayItemHostViewControllerRoundTrip() {
        let hostVC = LookinObject()
        hostVC.oid = 42
        hostVC.classChainList = [
            "LookinCollectionLayoutDemo.LKCollectionLayoutDemoViewController",
            "UIViewController",
            "UIResponder",
            "NSObject",
        ]

        let item = LookinDisplayItem()
        item.frame = CGRect(x: 0, y: 0, width: 320, height: 480)
        item.bounds = item.frame
        item.viewObject = LookinObject()
        item.viewObject?.oid = 13
        item.viewObject?.classChainList = ["UIView", "UIResponder", "NSObject"]
        item.hostViewControllerObject = hostVC

        let wire = WireHierarchyMapper.wireItem(from: item)
        XCTAssertEqual(wire.hostViewControllerRef?.oid, 42)
        XCTAssertEqual(
            wire.hostViewControllerRef?.classChainList?.first,
            "LookinCollectionLayoutDemo.LKCollectionLayoutDemoViewController"
        )

        let restored = WireHierarchyMapper.lookinItem(from: wire)
        XCTAssertEqual(restored.hostViewControllerObject?.oid, 42)
        XCTAssertEqual(
            restored.hostViewControllerObject?.classChainList?.first,
            "LookinCollectionLayoutDemo.LKCollectionLayoutDemoViewController"
        )
    }

    func testLKWireCodecV2RejectsInvalidJSON() {
        let garbage = Data("not-json".utf8)
        XCTAssertThrowsError(try LKWireCodecV2.decodeJSON(WireRequestEnvelope.self, from: garbage))
    }

    func testWireRequestEnvelopeWrongWireVersionDecodesButIsNotV2() throws {
        let json = Data("{\"requestType\":200,\"tag\":1,\"wireVersion\":1}".utf8)
        let envelope = try LKWireCodecV2.decodeJSON(WireRequestEnvelope.self, from: json)
        XCTAssertEqual(envelope.wireVersion, 1)
        XCTAssertNotEqual(envelope.wireVersion, LookinWireFormat.version)
    }

    func testLookinWireFormatValidateWireVersion() {
        XCTAssertTrue(LookinWireFormat.validateWireVersion(LookinWireFormat.version, context: "test"))
        XCTAssertFalse(LookinWireFormat.validateWireVersion(1, context: "test"))
    }

    func testLookinRequestTypeWireEnvelopeRoundTrips() throws {
        var asyncTask = LookinStaticAsyncUpdateTask()
        asyncTask.oid = 9
        var detailPackage = LookinStaticAsyncUpdateTasksPackage()
        detailPackage.tasks = [asyncTask]

        var inbuilt = LookinAttributeModification()
        inbuilt.targetOid = 1
        inbuilt.setterSelector = NSSelectorFromString("setHidden:")
        inbuilt.attrType = .BOOL
        inbuilt.value = .bool(true)

        var custom = LookinCustomAttrModification()
        custom.attrType = .NSString
        custom.customSetterID = "setTitle"
        custom.value = .string("hello")

        struct Case {
            let requestType: UInt32
            let data: Any?
            let expectsObject: Bool
        }

        let cases: [Case] = [
            Case(requestType: UInt32(LookinRequestTypePing), data: nil, expectsObject: false),
            Case(
                requestType: UInt32(LookinRequestTypeApp),
                data: ["needImages": true, "local": [NSNumber(value: 1)]] as NSObject,
                expectsObject: true
            ),
            Case(
                requestType: UInt32(LookinRequestTypeHierarchy),
                data: ["clientVersion": "1.0.0"] as NSObject,
                expectsObject: true
            ),
            Case(
                requestType: UInt32(LookinRequestTypeHierarchyDetails),
                data: [detailPackage] as NSObject,
                expectsObject: true
            ),
            Case(requestType: UInt32(LookinRequestTypeInbuiltAttrModification), data: inbuilt, expectsObject: true),
            Case(requestType: UInt32(LookinRequestTypeAttrModificationPatch), data: [asyncTask] as NSObject, expectsObject: true),
            Case(
                requestType: UInt32(LookinRequestTypeInvokeMethod),
                data: ["oid": NSNumber(value: 1), "text": "foo"] as NSObject,
                expectsObject: true
            ),
            Case(requestType: UInt32(LookinRequestTypeFetchObject), data: NSNumber(value: 7), expectsObject: true),
            Case(requestType: UInt32(LookinRequestTypeFetchImageViewImage), data: NSNumber(value: 8), expectsObject: true),
            Case(
                requestType: UInt32(LookinRequestTypeModifyRecognizerEnable),
                data: ["oid": NSNumber(value: 2), "enable": NSNumber(value: true)] as NSObject,
                expectsObject: true
            ),
            Case(requestType: UInt32(LookinRequestTypeAllAttrGroups), data: NSNumber(value: 3), expectsObject: true),
            Case(
                requestType: UInt32(LookinRequestTypeAllSelectorNames),
                data: ["className": "UIView", "hasArg": false] as NSObject,
                expectsObject: true
            ),
            Case(requestType: UInt32(LookinRequestTypeCustomAttrModification), data: custom, expectsObject: true),
        ]

        for item in cases {
            let envelope = WireRequestResponseMapper.requestEnvelope(
                requestType: item.requestType,
                tag: 99,
                data: item.data
            )
            XCTAssertEqual(envelope.wireVersion, LookinWireFormat.version)
            XCTAssertEqual(envelope.requestType, item.requestType)
            XCTAssertEqual(envelope.tag, 99)

            let json = try LKWireCodecV2.encodeJSON(envelope)
            let decoded = try LKWireCodecV2.decodeJSON(WireRequestEnvelope.self, from: json)
            XCTAssertEqual(decoded.wireVersion, LookinWireFormat.version)
            XCTAssertEqual(decoded.requestType, item.requestType)
            XCTAssertEqual(decoded.tag, 99)

            let object = WireRequestResponseMapper.requestObject(from: decoded)
            if item.expectsObject {
                XCTAssertNotNil(object, "requestType \(item.requestType)")
            } else {
                XCTAssertNil(object, "requestType \(item.requestType)")
            }
        }
    }

    func testWireRequestEnvelopeJSONRoundTrip() throws {
        let params: [String: Any] = ["needImages": true, "local": [NSNumber(value: 1)]]
        let envelope = WireRequestResponseMapper.requestEnvelope(
            requestType: 201,
            tag: 42,
            data: params as NSObject
        )
        let data = try LKWireCodecV2.encodeJSON(envelope)
        let preview = String(data: data, encoding: .utf8) ?? ""
        XCTAssertTrue(preview.contains("\"requestType\""))
        let decoded = try LKWireCodecV2.decodeJSON(WireRequestEnvelope.self, from: data)
        XCTAssertEqual(decoded.requestType, 201)
        XCTAssertEqual(decoded.tag, 42)
        XCTAssertEqual(decoded.wireVersion, LookinWireFormat.version)
        XCTAssertEqual(decoded.appParams?.needImages, true)
        XCTAssertEqual(decoded.appParams?.localIdentifiers, [1])

        let pingJSON = Data("{\"requestType\":200,\"tag\":1,\"wireVersion\":2}".utf8)
        let ping = try LKWireCodecV2.decodeJSON(WireRequestEnvelope.self, from: pingJSON)
        XCTAssertEqual(ping.requestType, 200)
    }
}
