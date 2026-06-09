#if SHOULD_COMPILE_LOOKIN_SERVER

import Foundation
import UIKit

@MainActor
public final class LKS_RequestHandler {

    private let validRequestTypes: Set<UInt32>
    private var activeDetailTasks: [UUID: Task<Void, Never>] = [:]

    public init() {
        validRequestTypes = Set([
            UInt32(LookinRequestTypePing),
            UInt32(LookinRequestTypeApp),
            UInt32(LookinRequestTypeHierarchy),
            UInt32(LookinRequestTypeInbuiltAttrModification),
            UInt32(LookinRequestTypeCustomAttrModification),
            UInt32(LookinRequestTypeAttrModificationPatch),
            UInt32(LookinRequestTypeHierarchyDetails),
            UInt32(LookinRequestTypeFetchObject),
            UInt32(LookinRequestTypeAllAttrGroups),
            UInt32(LookinRequestTypeAllSelectorNames),
            UInt32(LookinRequestTypeInvokeMethod),
            UInt32(LookinRequestTypeFetchImageViewImage),
            UInt32(LookinRequestTypeModifyRecognizerEnable),
            UInt32(LookinPush_CanceHierarchyDetails),
        ])
    }

    public func canHandleRequestType(_ requestType: UInt32) -> Bool {
        validRequestTypes.contains(requestType)
    }

    public func handleRequestType(_ requestType: UInt32, tag: UInt32, object: Any?) async {
        switch requestType {
        case UInt32(LookinRequestTypePing):
            var responseAttachment = LKConnectionResponseAttachment()
            if !LKS_ConnectionManager.sharedInstance.applicationIsActive {
                responseAttachment.appIsInBackground = true
            }
            LKS_ConnectionManager.sharedInstance.respond(responseAttachment, requestType: requestType, tag: tag)

        case UInt32(LookinRequestTypeApp):
            guard let params = object as? [String: Any] else {
                submitResponseWithError(LookinConnectionErrors.inner, requestType: requestType, tag: tag)
                return
            }
            let needImages = (params["needImages"] as? NSNumber)?.boolValue ?? false
            let localIdentifiers = params["local"] as? [NSNumber]
            let appInfo = LKAppInfo.currentInfo(withScreenshot: needImages, icon: needImages, localIdentifiers: localIdentifiers)

            var responseAttachment = LKConnectionResponseAttachment()
            responseAttachment.data = appInfo
            LKS_ConnectionManager.sharedInstance.respond(responseAttachment, requestType: requestType, tag: tag)

        case UInt32(LookinRequestTypeHierarchy):
            var clientVersion: String?
            if let params = object as? [String: Any], let version = params["clientVersion"] as? String {
                clientVersion = version
            }
            var responseAttachment = LKConnectionResponseAttachment()
            responseAttachment.data = LKHierarchyInfo.staticInfo(withLookinVersion: clientVersion)
            LKS_ConnectionManager.sharedInstance.respond(responseAttachment, requestType: requestType, tag: tag)

        case UInt32(LookinRequestTypeInbuiltAttrModification):
            guard let modification = object as? LookinAttributeModification else {
                LookinDiagLog.log("Peertalk inbuilt req tag=\(tag) reject — not LookinAttributeModification")
                submitResponseWithError(LookinConnectionErrors.inner, requestType: requestType, tag: tag)
                return
            }
            LookinDiagLog.log(
                "Peertalk inbuilt req tag=\(tag) targetOid=\(modification.targetOid) attr=\(modification.attrIdentifier ?? "?")"
            )
            do {
                let detail = try await LKS_InbuiltAttrModificationHandler.handleModification(modification)
                LookinDiagLog.log(
                    "Peertalk inbuilt resp OK tag=\(tag) detailOid=\(detail.displayItemOid)"
                )
                var attachment = LKConnectionResponseAttachment()
                attachment.data = detail
                LKS_ConnectionManager.sharedInstance.respond(attachment, requestType: requestType, tag: tag)
            } catch {
                LookinDiagLog.log(
                    "Peertalk inbuilt resp ERROR tag=\(tag) code=\((error as NSError).code) \(error.localizedDescription)"
                )
                submitResponseWithError(error, requestType: requestType, tag: tag)
            }

        case UInt32(LookinRequestTypeCustomAttrModification):
            let custom = object as? LookinCustomAttrModification
            LookinDiagLog.log(
                "Peertalk custom req tag=\(tag) setterID=\(custom?.customSetterID ?? "?") attrType=\(custom?.attrType.rawValue ?? -1)"
            )
            let success = LKS_CustomAttrModificationHandler.handleModification(custom)
            if success {
                LookinDiagLog.log("Peertalk custom resp OK tag=\(tag) (empty ACK)")
                submitResponseWithData(nil, requestType: requestType, tag: tag)
            } else {
                LookinDiagLog.log("Peertalk custom resp FAIL tag=\(tag)")
                submitResponseWithError(LookinConnectionErrors.inner, requestType: requestType, tag: tag)
            }

        case UInt32(LookinRequestTypeAttrModificationPatch):
            guard let tasks = object as? [LookinStaticAsyncUpdateTask], !tasks.isEmpty else { return }
            let dataTotalCount = tasks.count
            for await detail in LKS_ConnectionRuntimeBridge.handlePatch(with: tasks) {
                var attrAttachment = LKConnectionResponseAttachment()
                attrAttachment.data = detail
                attrAttachment.dataTotalCount = UInt(dataTotalCount)
                attrAttachment.currentDataCount = 1
                LKS_ConnectionManager.sharedInstance.respond(
                    attrAttachment,
                    requestType: UInt32(LookinRequestTypeAttrModificationPatch),
                    tag: tag
                )
            }

        case UInt32(LookinRequestTypeHierarchyDetails):
            await handleHierarchyDetails(object: object, tag: tag)

        case UInt32(LookinRequestTypeFetchObject):
            let oid = (object as? NSNumber)?.uintValue ?? 0
            let targetObject = NSObject.lks_object(withOid: oid)
            var attach = LKConnectionResponseAttachment()
            if let targetObject {
                attach.data = LookinObject.instance(with: targetObject)
            }
            LKS_ConnectionManager.sharedInstance.respond(attach, requestType: requestType, tag: tag)

        case UInt32(LookinRequestTypeAllAttrGroups):
            let oid = (object as? NSNumber)?.uintValue ?? 0
            guard let layer = NSObject.lks_object(withOid: oid) as? CALayer else {
                submitResponseWithError(LookinConnectionErrors.objectNotFound, requestType: requestType, tag: tag)
                return
            }
            let list = LKS_AttrGroupsMaker.attrGroups(for: layer)
            submitResponseWithData(list as NSObject?, requestType: requestType, tag: tag)

        case UInt32(LookinRequestTypeAllSelectorNames):
            guard let params = object as? [String: Any] else {
                submitResponseWithError(LookinConnectionErrors.inner, requestType: requestType, tag: tag)
                return
            }
            guard let className = params["className"] as? String,
                  let targetClass = NSClassFromString(className) else {
                let errorMsg = String(
                    format: lksLocalized("Didn't find the class named \"%@\". Please input another class and try again."),
                    (object as? String) ?? ""
                )
                submitResponseWithError(LookinConnectionErrors.make(title: errorMsg), requestType: requestType, tag: tag)
                return
            }
            let hasArg = (params["hasArg"] as? NSNumber)?.boolValue ?? false
            let selNames = LKS_ConnectionRuntimeBridge.methodNameList(for: targetClass, hasArg: hasArg)
            submitResponseWithData(selNames as NSObject, requestType: requestType, tag: tag)

        case UInt32(LookinRequestTypeInvokeMethod):
            guard let param = object as? [String: Any] else {
                submitResponseWithError(LookinConnectionErrors.inner, requestType: requestType, tag: tag)
                return
            }
            let oid = (param["oid"] as? NSNumber)?.uintValue ?? 0
            guard let text = param["text"] as? String, !text.isEmpty else {
                submitResponseWithError(LookinConnectionErrors.inner, requestType: requestType, tag: tag)
                return
            }
            guard let targetObj = NSObject.lks_object(withOid: oid) else {
                submitResponseWithError(LookinConnectionErrors.objectNotFound, requestType: requestType, tag: tag)
                return
            }

            let targetSelector = NSSelectorFromString(text)
            if targetSelector != NSSelectorFromString(""), targetObj.responds(to: targetSelector) {
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
                    submitResponseWithError(error, requestType: requestType, tag: tag)
                    return
                }
                var responseData: [String: Any] = [:]
                if let resultDescription {
                    responseData["description"] = resultDescription
                }
                if let resultObject {
                    responseData["object"] = resultObject
                }
                submitResponseWithData(responseData as NSObject, requestType: requestType, tag: tag)
            } else {
                let errMsg = String(
                    format: lksLocalized("%@ doesn't have an instance method called \"%@\"."),
                    NSStringFromClass(type(of: targetObj)),
                    text
                )
                submitResponseWithError(LookinConnectionErrors.make(title: errMsg), requestType: requestType, tag: tag)
            }

        case UInt32(LookinPush_CanceHierarchyDetails):
            for task in activeDetailTasks.values {
                task.cancel()
            }
            activeDetailTasks.removeAll()

        case UInt32(LookinRequestTypeFetchImageViewImage):
            guard let oidNumber = object as? NSNumber else {
                submitResponseWithError(LookinConnectionErrors.inner, requestType: requestType, tag: tag)
                return
            }
            guard let imageView = NSObject.lks_object(withOid: oidNumber.uintValue) as? UIImageView else {
                submitResponseWithError(
                    imageViewExists(object: object) ? LookinConnectionErrors.inner : LookinConnectionErrors.objectNotFound,
                    requestType: requestType,
                    tag: tag
                )
                return
            }
            let imageData = imageView.image?.lookin_data()
            submitResponseWithData(imageData as NSObject?, requestType: requestType, tag: tag)

        case UInt32(LookinRequestTypeModifyRecognizerEnable):
            guard let params = object as? [String: NSNumber] else {
                submitResponseWithError(LookinConnectionErrors.inner, requestType: requestType, tag: tag)
                return
            }
            let recognizerOid = params["oid"]?.uintValue ?? 0
            let shouldBeEnabled = params["enable"]?.boolValue ?? false
            guard let recognizer = NSObject.lks_object(withOid: recognizerOid) as? UIGestureRecognizer else {
                submitResponseWithError(
                    recognizerExists(oid: recognizerOid) ? LookinConnectionErrors.inner : LookinConnectionErrors.objectNotFound,
                    requestType: requestType,
                    tag: tag
                )
                return
            }
            recognizer.isEnabled = shouldBeEnabled
            await Task.yield()
            submitResponseWithData(NSNumber(value: recognizer.isEnabled), requestType: requestType, tag: tag)

        default:
            break
        }
    }

    public func handleHierarchyDetails(object: Any?, tag: UInt32) async {
        let packages = Self.taskPackages(from: object)
        let responsesDataTotalCount = (packages as NSArray?)?.lookin_reduceInteger({ accumulator, _, package in
            guard let package = package as? LookinStaticAsyncUpdateTasksPackage else { return accumulator }
            return accumulator + (package.tasks?.count ?? 0)
        }, initialAccumlator: 0) ?? 0

        guard let packages else {
            submitResponseWithError(LookinConnectionErrors.inner, requestType: UInt32(LookinRequestTypeHierarchyDetails), tag: tag)
            return
        }

        if responsesDataTotalCount == 0 {
            var attachment = LKConnectionResponseAttachment()
            attachment.data = NSArray()
            attachment.dataTotalCount = 0
            attachment.currentDataCount = 0
            LKS_ConnectionManager.sharedInstance.respond(
                attachment,
                requestType: UInt32(LookinRequestTypeHierarchyDetails),
                tag: tag
            )
            return
        }

        let taskID = UUID()
        let detailTask = Task { @MainActor in
            let handler = LKS_HierarchyDetailsHandler()
            for await details in handler.generateDetails(for: packages) {
                if Task.isCancelled { break }
                var attachment = LKConnectionResponseAttachment()
                attachment.data = details
                attachment.dataTotalCount = UInt(responsesDataTotalCount)
                attachment.currentDataCount = UInt(details.count)
                LKS_ConnectionManager.sharedInstance.respond(
                    attachment,
                    requestType: UInt32(LookinRequestTypeHierarchyDetails),
                    tag: tag
                )
            }
            await self.finishDetailTask(taskID)
        }
        activeDetailTasks[taskID] = detailTask
    }

    private func finishDetailTask(_ id: UUID) {
        activeDetailTasks.removeValue(forKey: id)
    }

    private static func taskPackages(from object: Any?) -> [LookinStaticAsyncUpdateTasksPackage]? {
        if let packages = object as? [LookinStaticAsyncUpdateTasksPackage] {
            return packages
        }
        if let nsArray = object as? NSArray {
            return nsArray.compactMap { $0 as? LookinStaticAsyncUpdateTasksPackage }
        }
        return nil
    }

    private func imageViewExists(object: Any?) -> Bool {
        guard let oidNumber = object as? NSNumber else { return false }
        return NSObject.lks_object(withOid: oidNumber.uintValue) != nil
    }

    private func recognizerExists(oid: UInt) -> Bool {
        NSObject.lks_object(withOid: oid) != nil
    }

    private func submitResponseWithError(_ error: Error, requestType: UInt32, tag: UInt32) {
        var attachment = LKConnectionResponseAttachment()
        attachment.error = error as NSError
        LKS_ConnectionManager.sharedInstance.respond(attachment, requestType: requestType, tag: tag)
    }

    private func submitResponseWithData(_ data: NSObject?, requestType: UInt32, tag: UInt32) {
        var attachment = LKConnectionResponseAttachment()
        attachment.data = data
        LKS_ConnectionManager.sharedInstance.respond(attachment, requestType: requestType, tag: tag)
    }

    private func lksLocalized(_ key: String) -> String {
        NSLocalizedString(key, tableName: nil, bundle: LKS_Helper.bundle(), comment: "")
    }
}

#endif
