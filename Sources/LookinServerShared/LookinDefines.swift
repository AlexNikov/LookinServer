import Foundation

// MARK: - Version

public let lookinServerVersion = 7
public let lookinServerReadableVersion = "1.2.8"
public let lookinClientVersion = 7
public let lookinSupportedServerMin = 7
public let lookinSupportedServerMax = 7

// MARK: - Connection

public let lookinUSBDeviceIPv4PortNumberStart = 47175
public let lookinUSBDeviceIPv4PortNumberEnd = 47179
public let lookinSimulatorIPv4PortNumberStart = 47164
public let lookinSimulatorIPv4PortNumberEnd = 47169

public enum LookinRequestType: Int {
    case ping = 200
    case app = 201
    case hierarchy = 202
    case hierarchyDetails = 203
    case inbuiltAttrModification = 204
    case attrModificationPatch = 205
    case invokeMethod = 206
    case fetchObject = 207
    case fetchImageViewImage = 208
    case modifyRecognizerEnable = 209
    case allAttrGroups = 210
    case allSelectorNames = 213
    case customAttrModification = 214
    case pushBringForwardScreenshotTask = 303
    case pushCancelHierarchyDetails = 304
}

public let lookinParamViewLayerTag = "tag"
public let lookinParamSelectorName = "sn"
public let lookinParamMethodType = "mt"
public let lookinParamSelectorClassName = "scn"
public let lookinStringFlagVoidReturn = "LOOKIN_TAG_RETURN_VALUE_VOID"

// MARK: - Error

public let lookinErrorDomain = "LookinError"

public enum LookinErrCode: Int {
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

// MARK: - Preview

public let lookinNodeImageMaxLengthInPx: Double = 16384

public enum LookinPreviewBitMask: UInt {
    case none = 0
    case selectable = 2
    case unselectable = 4
    case hasLight = 8
    case noLight = 16
}
