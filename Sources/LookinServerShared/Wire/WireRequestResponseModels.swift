import Foundation

// MARK: - Request payloads

public struct WireAppRequestParams: Codable, Equatable {
    public var needImages: Bool
    public var localIdentifiers: [UInt]?

    public init(needImages: Bool = false, localIdentifiers: [UInt]? = nil) {
        self.needImages = needImages
        self.localIdentifiers = localIdentifiers
    }
}

public struct WireSelectorQueryParams: Codable, Equatable {
    public var className: String
    public var hasArg: Bool

    public init(className: String, hasArg: Bool) {
        self.className = className
        self.hasArg = hasArg
    }
}

public struct WireInvokeParams: Codable, Equatable {
    public var oid: UInt
    public var text: String

    public init(oid: UInt, text: String) {
        self.oid = oid
        self.text = text
    }
}

public struct WireRecognizerParams: Codable, Equatable {
    public var oid: UInt
    public var enable: Bool

    public init(oid: UInt, enable: Bool) {
        self.oid = oid
        self.enable = enable
    }
}

public struct WireAttributeModificationPayload: Codable, Equatable {
    public var targetOid: UInt
    public var setterSelector: String
    public var attrType: Int
    public var value: WireAttrValue?
    public var clientReadableVersion: String?
    public var attrIdentifier: String?

    public init(
        targetOid: UInt,
        setterSelector: String,
        attrType: Int,
        value: WireAttrValue? = nil,
        clientReadableVersion: String? = nil,
        attrIdentifier: String? = nil
    ) {
        self.targetOid = targetOid
        self.setterSelector = setterSelector
        self.attrType = attrType
        self.value = value
        self.clientReadableVersion = clientReadableVersion
        self.attrIdentifier = attrIdentifier
    }
}

public struct WireCustomAttrModificationPayload: Codable, Equatable {
    public var attrType: Int
    public var customSetterID: String?
    public var value: WireAttrValue?

    public init(attrType: Int, customSetterID: String? = nil, value: WireAttrValue? = nil) {
        self.attrType = attrType
        self.customSetterID = customSetterID
        self.value = value
    }
}

// MARK: - Response payloads

public struct WirePingPayload: Codable, Equatable {
    public var appIsInBackground: Bool

    public init(appIsInBackground: Bool = false) {
        self.appIsInBackground = appIsInBackground
    }
}

public struct WireAppInfoPayload: Codable, Equatable {
    public var appInfoIdentifier: UInt
    public var shouldUseCache: Bool
    public var serverVersion: Int32
    public var serverReadableVersion: String?
    public var swiftEnabledInLookinServer: Int32
    public var appName: String?
    public var appBundleIdentifier: String?
    public var deviceDescription: String?
    public var osDescription: String?
    public var osMainVersion: UInt
    public var deviceType: Int
    public var screenWidth: Double
    public var screenHeight: Double
    public var screenScale: Double
    public var screenshotPNGBase64: String?
    public var appIconPNGBase64: String?

    public init(
        appInfoIdentifier: UInt = 0,
        shouldUseCache: Bool = false,
        serverVersion: Int32 = 0,
        serverReadableVersion: String? = nil,
        swiftEnabledInLookinServer: Int32 = 0,
        appName: String? = nil,
        appBundleIdentifier: String? = nil,
        deviceDescription: String? = nil,
        osDescription: String? = nil,
        osMainVersion: UInt = 0,
        deviceType: Int = 0,
        screenWidth: Double = 0,
        screenHeight: Double = 0,
        screenScale: Double = 0,
        screenshotPNGBase64: String? = nil,
        appIconPNGBase64: String? = nil
    ) {
        self.appInfoIdentifier = appInfoIdentifier
        self.shouldUseCache = shouldUseCache
        self.serverVersion = serverVersion
        self.serverReadableVersion = serverReadableVersion
        self.swiftEnabledInLookinServer = swiftEnabledInLookinServer
        self.appName = appName
        self.appBundleIdentifier = appBundleIdentifier
        self.deviceDescription = deviceDescription
        self.osDescription = osDescription
        self.osMainVersion = osMainVersion
        self.deviceType = deviceType
        self.screenWidth = screenWidth
        self.screenHeight = screenHeight
        self.screenScale = screenScale
        self.screenshotPNGBase64 = screenshotPNGBase64
        self.appIconPNGBase64 = appIconPNGBase64
    }
}

public struct WireObjectPayload: Codable, Equatable {
    public var oid: UInt
    public var memoryAddress: String?
    public var classChainList: [String]?
    public var specialTrace: String?

    public init(
        oid: UInt,
        memoryAddress: String? = nil,
        classChainList: [String]? = nil,
        specialTrace: String? = nil
    ) {
        self.oid = oid
        self.memoryAddress = memoryAddress
        self.classChainList = classChainList
        self.specialTrace = specialTrace
    }
}

public struct WireInvokeResultPayload: Codable, Equatable {
    public var description: String?
    public var object: WireObjectPayload?

    public init(description: String? = nil, object: WireObjectPayload? = nil) {
        self.description = description
        self.object = object
    }
}

/// Client → server push (cancel detail fetch, …). Peertalk frame type stays `LookinPush_*`; payload is JSON.
public struct WirePushEnvelope: Codable, Equatable {
    public var wireVersion: Int
    public var pushType: UInt32

    public init(wireVersion: Int = LookinWireFormat.version, pushType: UInt32) {
        self.wireVersion = wireVersion
        self.pushType = pushType
    }
}

/// Peertalk push frame types (see `LookinDefines.h`).
public enum LookinWirePushTypes {
    public static let bringForwardScreenshotTask: UInt32 = 303
    public static let cancelHierarchyDetails: UInt32 = 304

    public static let all: Set<UInt32> = [
        bringForwardScreenshotTask,
        cancelHierarchyDetails,
    ]
}
