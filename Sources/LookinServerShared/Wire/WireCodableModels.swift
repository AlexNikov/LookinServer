import Foundation

extension NSValue {
    var lookinCGRectValue: CGRect {
        #if os(macOS)
        return rectValue
        #else
        return cgRectValue
        #endif
    }
}

public struct Rect: Codable, Equatable {
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    public init(_ rect: CGRect) {
        x = Double(rect.origin.x)
        y = Double(rect.origin.y)
        width = Double(rect.size.width)
        height = Double(rect.size.height)
    }

    public var cgRect: CGRect {
        CGRect(x: x, y: y, width: width, height: height)
    }
}

public struct WireIvarTrace: Codable, Equatable {
    public var relation: String?
    public var hostClassName: String?
    public var ivarName: String?

    public init(
        relation: String? = nil,
        hostClassName: String? = nil,
        ivarName: String? = nil
    ) {
        self.relation = relation
        self.hostClassName = hostClassName
        self.ivarName = ivarName
    }
}

public struct WireObjectRef: Codable, Equatable {
    public var oid: UInt
    public var classChainList: [String]?
    public var memoryAddress: String?
    public var specialTrace: String?
    public var ivarTraces: [WireIvarTrace]?

    public init(
        oid: UInt,
        classChainList: [String]? = nil,
        memoryAddress: String? = nil,
        specialTrace: String? = nil,
        ivarTraces: [WireIvarTrace]? = nil
    ) {
        self.oid = oid
        self.classChainList = classChainList
        self.memoryAddress = memoryAddress
        self.specialTrace = specialTrace
        self.ivarTraces = ivarTraces
    }
}

public struct WireCustomDisplayItemInfo: Codable, Equatable {
    public var frameInWindow: Rect?
    public var title: String?
    public var subtitle: String?
    public var danceuiSource: String?

    public init(
        frameInWindow: Rect? = nil,
        title: String? = nil,
        subtitle: String? = nil,
        danceuiSource: String? = nil
    ) {
        self.frameInWindow = frameInWindow
        self.title = title
        self.subtitle = subtitle
        self.danceuiSource = danceuiSource
    }
}

public struct WireDisplayItem: Codable, Equatable {
    public var oid: UInt
    public var frame: Rect
    public var bounds: Rect
    public var isHidden: Bool
    public var alpha: Float
    public var shouldCaptureImage: Bool
    public var customDisplayTitle: String?
    public var representedAsKeyWindow: Bool?
    public var layerRef: WireObjectRef?
    public var viewRef: WireObjectRef?
    /// Host view controller for `viewController.view` rows (tree icon + subtitle).
    public var hostViewControllerRef: WireObjectRef?
    /// User custom subview info (LookinCustomDisplayItemInfo).
    public var customInfo: WireCustomDisplayItemInfo?
    /// Custom attribute groups attached to the item (used when `customInfo != nil`).
    public var customAttrGroupList: [WireAttributesGroup]?
    /// Preview plane fallback color when screenshot is unavailable (`[r,g,b,a]` in 0...1).
    public var backgroundColorRGBA: [Double]?
    public var subitems: [WireDisplayItem]?

    public init(
        oid: UInt,
        frame: Rect,
        bounds: Rect,
        isHidden: Bool,
        alpha: Float,
        shouldCaptureImage: Bool,
        customDisplayTitle: String? = nil,
        representedAsKeyWindow: Bool? = nil,
        layerRef: WireObjectRef? = nil,
        viewRef: WireObjectRef? = nil,
        hostViewControllerRef: WireObjectRef? = nil,
        customInfo: WireCustomDisplayItemInfo? = nil,
        customAttrGroupList: [WireAttributesGroup]? = nil,
        backgroundColorRGBA: [Double]? = nil,
        subitems: [WireDisplayItem]? = nil
    ) {
        self.oid = oid
        self.frame = frame
        self.bounds = bounds
        self.isHidden = isHidden
        self.alpha = alpha
        self.shouldCaptureImage = shouldCaptureImage
        self.customDisplayTitle = customDisplayTitle
        self.representedAsKeyWindow = representedAsKeyWindow
        self.layerRef = layerRef
        self.viewRef = viewRef
        self.hostViewControllerRef = hostViewControllerRef
        self.customInfo = customInfo
        self.customAttrGroupList = customAttrGroupList
        self.backgroundColorRGBA = backgroundColorRGBA
        self.subitems = subitems
    }
}

public struct WireHierarchyPayload: Codable, Equatable {
    public var wireVersion: Int
    public var serverVersion: Int32
    public var displayItems: [WireDisplayItem]
    public var collapsedClassList: [String]?
    /// Screen size and device metadata for mac client preview centering.
    public var appInfo: WireAppInfoPayload?

    public init(
        wireVersion: Int = LookinWireFormat.version,
        serverVersion: Int32,
        displayItems: [WireDisplayItem],
        collapsedClassList: [String]? = nil,
        appInfo: WireAppInfoPayload? = nil
    ) {
        self.wireVersion = wireVersion
        self.serverVersion = serverVersion
        self.displayItems = displayItems
        self.collapsedClassList = collapsedClassList
        self.appInfo = appInfo
    }
}

public struct WireDisplayItemDetailPayload: Codable, Equatable {
    public var displayItemOid: UInt
    public var frame: Rect?
    public var bounds: Rect?
    public var isHidden: Bool?
    public var alpha: Float?
    public var failureCode: Int?
    public var customDisplayTitle: String?
    public var danceUISource: String?
    public var attributesGroupList: [WireAttributesGroup]?
    public var customAttrGroupList: [WireAttributesGroup]?
    public var subitems: [WireDisplayItem]?

    public init(displayItemOid: UInt) {
        self.displayItemOid = displayItemOid
    }
}

public struct WireErrorPayload: Codable, Equatable {
    public var code: Int
    public var message: String?

    public init(code: Int, message: String? = nil) {
        self.code = code
        self.message = message
    }
}

/// Server → client JSON frame body.
public struct WireResponseEnvelope: Codable, Equatable {
    public var wireVersion: Int
    public var requestType: UInt32
    public var tag: UInt32
    public var error: WireErrorPayload?
    public var hierarchy: WireHierarchyPayload?
    public var detail: WireDisplayItemDetailPayload?
    public var dataTotalCount: UInt?
    public var currentDataCount: UInt?
    public var ping: WirePingPayload?
    public var app: WireAppInfoPayload?
    public var object: WireObjectPayload?
    public var attributeGroups: [WireAttributesGroup]?
    public var stringList: [String]?
    public var invokeResult: WireInvokeResultPayload?
    public var pngDataBase64: String?
    public var boolValue: Bool?

    public init(
        wireVersion: Int = LookinWireFormat.version,
        requestType: UInt32,
        tag: UInt32,
        error: WireErrorPayload? = nil,
        hierarchy: WireHierarchyPayload? = nil,
        detail: WireDisplayItemDetailPayload? = nil,
        dataTotalCount: UInt? = nil,
        currentDataCount: UInt? = nil,
        ping: WirePingPayload? = nil,
        app: WireAppInfoPayload? = nil,
        object: WireObjectPayload? = nil,
        attributeGroups: [WireAttributesGroup]? = nil,
        stringList: [String]? = nil,
        invokeResult: WireInvokeResultPayload? = nil,
        pngDataBase64: String? = nil,
        boolValue: Bool? = nil
    ) {
        self.wireVersion = wireVersion
        self.requestType = requestType
        self.tag = tag
        self.error = error
        self.hierarchy = hierarchy
        self.detail = detail
        self.dataTotalCount = dataTotalCount
        self.currentDataCount = currentDataCount
        self.ping = ping
        self.app = app
        self.object = object
        self.attributeGroups = attributeGroups
        self.stringList = stringList
        self.invokeResult = invokeResult
        self.pngDataBase64 = pngDataBase64
        self.boolValue = boolValue
    }
}

/// Client → server JSON request (ping, hierarchy, …).
public struct WireHierarchyRequestParams: Codable, Equatable {
    public var clientVersion: String?
    public var minWireVersion: Int

    public init(clientVersion: String? = nil, minWireVersion: Int = LookinWireFormat.version) {
        self.clientVersion = clientVersion
        self.minWireVersion = minWireVersion
    }
}

public struct WireRequestEnvelope: Codable, Equatable {
    public var wireVersion: Int
    public var requestType: UInt32
    public var tag: UInt32
    public var hierarchyParams: WireHierarchyRequestParams?
    public var detailPackages: [WireStaticAsyncUpdateTasksPackage]?
    public var patchTasks: [WireStaticAsyncUpdateTask]?
    public var appParams: WireAppRequestParams?
    public var oid: UInt?
    public var selectorQuery: WireSelectorQueryParams?
    public var invokeParams: WireInvokeParams?
    public var recognizerParams: WireRecognizerParams?
    public var inbuiltModification: WireAttributeModificationPayload?
    public var customModification: WireCustomAttrModificationPayload?

    public init(
        wireVersion: Int = LookinWireFormat.version,
        requestType: UInt32,
        tag: UInt32,
        hierarchyParams: WireHierarchyRequestParams? = nil,
        detailPackages: [WireStaticAsyncUpdateTasksPackage]? = nil,
        patchTasks: [WireStaticAsyncUpdateTask]? = nil,
        appParams: WireAppRequestParams? = nil,
        oid: UInt? = nil,
        selectorQuery: WireSelectorQueryParams? = nil,
        invokeParams: WireInvokeParams? = nil,
        recognizerParams: WireRecognizerParams? = nil,
        inbuiltModification: WireAttributeModificationPayload? = nil,
        customModification: WireCustomAttrModificationPayload? = nil
    ) {
        self.wireVersion = wireVersion
        self.requestType = requestType
        self.tag = tag
        self.hierarchyParams = hierarchyParams
        self.detailPackages = detailPackages
        self.patchTasks = patchTasks
        self.appParams = appParams
        self.oid = oid
        self.selectorQuery = selectorQuery
        self.invokeParams = invokeParams
        self.recognizerParams = recognizerParams
        self.inbuiltModification = inbuiltModification
        self.customModification = customModification
    }
}

/// Client → server JSON command (screenshot fetch, etc.).
public struct WireCommand: Codable, Equatable {
    public enum Op: String, Codable {
        case screenshot
    }

    public var op: Op
    public var oid: UInt
    public var kind: WireScreenshotKind
    public var lowQuality: Bool

    public init(op: Op, oid: UInt, kind: WireScreenshotKind, lowQuality: Bool = false) {
        self.op = op
        self.oid = oid
        self.kind = kind
        self.lowQuality = lowQuality
    }
}
