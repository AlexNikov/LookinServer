#if SHOULD_COMPILE_LOOKIN_SERVER

import Foundation
import UIKit

public typealias LKS_HierarchyDetailsHandler_ProgressBlock = ([LookinDisplayItemDetail]) -> Void
public typealias LKS_HierarchyDetailsHandler_FinishBlock = () -> Void

@objc(LKS_HierarchyDetailsHandler)
public final class LKS_HierarchyDetailsHandler: NSObject {

    private var taskPackages: [LookinStaticAsyncUpdateTasksPackage] = []
    private var attrGroupsSyncedOids = Set<NSNumber>()
    private var progressBlock: LKS_HierarchyDetailsHandler_ProgressBlock?
    private var finishBlock: LKS_HierarchyDetailsHandler_FinishBlock?

    public override init() {
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(_handleConnectionDidEnd(_:)),
            name: NSNotification.Name(rawValue: LKS_ConnectionDidEndNotificationName as String),
            object: nil
        )
    }

    @objc(startWithPackages:block:finishedBlock:)
    public func start(
        with packages: [LookinStaticAsyncUpdateTasksPackage],
        block progressBlock: @escaping LKS_HierarchyDetailsHandler_ProgressBlock,
        finishedBlock finishBlock: @escaping LKS_HierarchyDetailsHandler_FinishBlock
    ) {
        guard Optional(progressBlock) != nil, Optional(finishBlock) != nil else {
            assertionFailure()
            return
        }
        if packages.isEmpty {
            finishBlock()
            return
        }
        taskPackages = packages
        self.progressBlock = progressBlock
        self.finishBlock = finishBlock

        runOnMainAsync { [weak self] in
            guard let self else { return }
            UIView.lks_rebuildGlobalInvolvedRawConstraints()
            self._dequeueAndHandlePackage()
        }
    }

    @objc public func cancel() {
        taskPackages.removeAll()
    }

    private func _dequeueAndHandlePackage() {
        runOnMainAsync { [weak self] in
            guard let self else { return }
            guard let package = self.taskPackages.first else {
                self.finishBlock?()
                self.finishBlock = nil
                self.progressBlock = nil
                return
            }

            let tasks = package.tasks ?? []
            self.taskPackages.removeFirst()

            guard !tasks.isEmpty else {
                self._dequeueAndHandlePackage()
                return
            }

            // Process tasks one-at-a-time so each DispatchQueue.main.async yields allow
            // AllAttrGroups and other lightweight requests to be handled between tasks.
            self._processTasksOneByOne(tasks)
        }
    }

    private func _processTasksOneByOne(_ tasks: [LookinStaticAsyncUpdateTask]) {
        guard !tasks.isEmpty else {
            _dequeueAndHandlePackage()
            return
        }
        runOnMainAsync { [weak self] in
            guard let self else { return }
            let detail = self._makeDetail(for: tasks[0])
            self.progressBlock?([detail])
            self._processTasksOneByOne(Array(tasks.dropFirst()))
        }
    }

    private func runOnMainAsync(_ work: @escaping () -> Void) {
        DispatchQueue.main.async(execute: work)
    }

    private func _makeDetail(for task: LookinStaticAsyncUpdateTask) -> LookinDisplayItemDetail {
        let itemDetail = LookinDisplayItemDetail()
        itemDetail.displayItemOid = task.oid

        guard let object = NSObject.lks_object(withOid: task.oid) as? CALayer else {
            itemDetail.failureCode = -1
            return itemDetail
        }

        switch task.taskType {
        case .soloScreenshot:
            itemDetail.soloScreenshot = object.lks_soloScreenshot(withLowQuality: false)
        case .groupScreenshot:
            itemDetail.groupScreenshot = object.lks_groupScreenshot(withLowQuality: false)
        default:
            break
        }

        if queryIfShouldMakeAttrs(from: task) {
            itemDetail.attributesGroupList = LKS_AttrGroupsMaker.attrGroups(for: object)

            if let version = task.clientReadableVersion, !version.isEmpty {
                if Self.lookinNumericOSVersion(version) >= 10004 {
                    let maker = LKS_CustomAttrGroupsMaker(layer: object)
                    maker.execute()
                    itemDetail.customAttrGroupList = (maker.getGroups() as NSArray?) as? [LookinAttributesGroup]
                    itemDetail.customDisplayTitle = maker.getCustomDisplayTitle()
                    itemDetail.danceUISource = maker.getDanceUISource()
                }
            }
            attrGroupsSyncedOids.insert(NSNumber(value: task.oid))
        }

        if task.needBasisVisualInfo {
            itemDetail.frameValue = NSValue(cgRect: object.frame)
            itemDetail.boundsValue = NSValue(cgRect: object.bounds)
            itemDetail.hiddenValue = NSNumber(value: object.isHidden)
            itemDetail.alphaValue = NSNumber(value: object.opacity)
        }

        if task.needSubitems {
            itemDetail.subitems = LKS_HierarchyDisplayItemsMaker.subitems(of: object)
        }

        return itemDetail
    }

    private func queryIfShouldMakeAttrs(from task: LookinStaticAsyncUpdateTask) -> Bool {
        switch task.attrRequest {
        case .automatic:
            return !attrGroupsSyncedOids.contains(NSNumber(value: task.oid))
        case .need:
            return true
        case .notNeed:
            return false
        @unknown default:
            assertionFailure()
            return true
        }
    }

    @objc private func _handleConnectionDidEnd(_ obj: Any?) {
        cancel()
    }

    private static func lookinNumericOSVersion(_ version: String) -> Int {
        let parts = version.split(separator: ".")
        guard parts.count == 3 else { return 0 }
        var numeric = 0
        for (index, part) in parts.prefix(3).enumerated() {
            guard let value = Int(part) else { return 0 }
            numeric += value * Int(pow(10, Double(4 - index * 2)))
        }
        return numeric
    }
}

#endif
