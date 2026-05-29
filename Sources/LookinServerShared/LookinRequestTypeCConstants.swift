import Foundation

/// Integer request types (legacy `LookinDefines.h` removed; Swift is source of truth).
public let LookinRequestTypePing = 200
public let LookinRequestTypeApp = 201
public let LookinRequestTypeHierarchy = 202
public let LookinRequestTypeHierarchyDetails = 203
public let LookinRequestTypeInbuiltAttrModification = 204
public let LookinRequestTypeAttrModificationPatch = 205
public let LookinRequestTypeInvokeMethod = 206
public let LookinRequestTypeFetchObject = 207
public let LookinRequestTypeFetchImageViewImage = 208
public let LookinRequestTypeModifyRecognizerEnable = 209
public let LookinRequestTypeAllAttrGroups = 210
public let LookinRequestTypeAllSelectorNames = 213
public let LookinRequestTypeCustomAttrModification = 214
public let LookinPushBringForwardScreenshotTask = 303
public let LookinPushCancelHierarchyDetails = 304
/// Typo preserved from legacy header (`Cance` not `Cancel`).
public let LookinPush_CanceHierarchyDetails = LookinPushCancelHierarchyDetails
