import Foundation

// Connection ports (from LookinDefines.h; not in LookinVersion.swift).
public let lookinUSBDeviceIPv4PortNumberStart = 47175
public let lookinUSBDeviceIPv4PortNumberEnd = 47179
public let lookinSimulatorIPv4PortNumberStart = 47164
public let lookinSimulatorIPv4PortNumberEnd = 47169

public let lookinNodeImageMaxLengthInPx: Double = 16384

public enum LookinPreviewBitMask: UInt {
    case none = 0
    case selectable = 2
    case unselectable = 4
    case hasLight = 8
    case noLight = 16
}

// MARK: - Legacy C names (Lookin mac client)

public let LOOKIN_CLIENT_VERSION = lookinClientVersion
public let LOOKIN_SUPPORTED_SERVER_MIN = lookinSupportedServerMin
public let LOOKIN_SUPPORTED_SERVER_MAX = lookinSupportedServerMax

public let LookinUSBDeviceIPv4PortNumberStart = lookinUSBDeviceIPv4PortNumberStart
public let LookinUSBDeviceIPv4PortNumberEnd = lookinUSBDeviceIPv4PortNumberEnd
public let LookinSimulatorIPv4PortNumberStart = lookinSimulatorIPv4PortNumberStart
public let LookinSimulatorIPv4PortNumberEnd = lookinSimulatorIPv4PortNumberEnd

public let LookinErrorDomain = lookinErrorDomain
public let LookinStringFlag_VoidReturn = lookinStringFlagVoidReturn
public let LookinNodeImageMaxLengthInPx = lookinNodeImageMaxLengthInPx

public let LookinErrCode_Default = LookinSharedErrCode.default.rawValue
public let LookinErrCode_Inner = LookinSharedErrCode.inner.rawValue
public let LookinErrCode_PeerTalk = LookinSharedErrCode.peerTalk.rawValue
public let LookinErrCode_NoConnect = LookinSharedErrCode.noConnect.rawValue
public let LookinErrCode_PingFailForTimeout = LookinSharedErrCode.pingFailForTimeout.rawValue
public let LookinErrCode_Timeout = LookinSharedErrCode.timeout.rawValue
public let LookinErrCode_Discard = LookinSharedErrCode.discard.rawValue
public let LookinErrCode_PingFailForBackgroundState = LookinSharedErrCode.pingFailForBackgroundState.rawValue
public let LookinErrCode_ObjectNotFound = LookinSharedErrCode.objectNotFound.rawValue
public let LookinErrCode_ModifyValueTypeInvalid = LookinSharedErrCode.modifyValueTypeInvalid.rawValue
public let LookinErrCode_Exception = LookinSharedErrCode.exception.rawValue
public let LookinErrCode_ServerVersionTooHigh = LookinSharedErrCode.serverVersionTooHigh.rawValue
public let LookinErrCode_ServerVersionTooLow = LookinSharedErrCode.serverVersionTooLow.rawValue
public let LookinErrCode_UnsupportedFileType = LookinSharedErrCode.unsupportedFileType.rawValue
