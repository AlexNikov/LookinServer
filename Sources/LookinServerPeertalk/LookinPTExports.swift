#if SHOULD_COMPILE_LOOKIN_SERVER

import Foundation

public let kLookinPTProtocolErrorDomain = "PTProtocolError"
public let kLookinPTUSBHubErrorDomain = "PTUSBHubError"
public let kLookinPTUSBDeviceDidAttachNotification = "Lookin_PTUSBDeviceDidAttachNotification"
public let kLookinPTUSBDeviceDidDetachNotification = "Lookin_PTUSBDeviceDidDetachNotification"

/// Legacy names used by Lookin mac client (`LookinDefines.h` era).
public let Lookin_PTUSBDeviceDidAttachNotification = kLookinPTUSBDeviceDidAttachNotification
public let Lookin_PTUSBDeviceDidDetachNotification = kLookinPTUSBDeviceDidDetachNotification

#endif /* SHOULD_COMPILE_LOOKIN_SERVER */
