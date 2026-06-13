#if SHOULD_COMPILE_LOOKIN_SERVER

import QuartzCore
import XCTest
@testable import LookinServer

@MainActor
final class LKS_RequestHandlerTests: XCTestCase {

    private var retainedLayers: [CALayer] = []

    func testCanHandlePingAndHierarchyDetails() async {
        let handler = LKS_RequestHandler()
        XCTAssertTrue(handler.canHandleRequestType(UInt32(LookinRequestTypePing)))
        XCTAssertTrue(handler.canHandleRequestType(UInt32(LookinRequestTypeHierarchyDetails)))
        XCTAssertFalse(handler.canHandleRequestType(999_999))
    }

    func testHierarchyDetailsEmptyPackagesRespondsWithoutCrashing() async {
        let handler = LKS_RequestHandler()
        await handler.handleHierarchyDetails(object: [], tag: 42)
    }

    func testHierarchyDetailsHandlerYieldsOneDetailPerTaskInOrder() async {
        let layers = (0..<3).map { _ in CALayer() }
        let oids = layers.map { register(layer: $0) }

        var packages: [LookinStaticAsyncUpdateTasksPackage] = []
        for oid in oids {
            var task = LookinStaticAsyncUpdateTask()
            task.oid = oid
            task.taskType = .noScreenshot
            task.attrRequest = .notNeed
            var package = LookinStaticAsyncUpdateTasksPackage()
            package.tasks = [task]
            packages.append(package)
        }

        let handler = LKS_HierarchyDetailsHandler()
        var yieldedOids: [UInt] = []
        for await details in handler.generateDetails(for: packages) {
            XCTAssertEqual(details.count, 1)
            yieldedOids.append(details[0].displayItemOid)
        }

        XCTAssertEqual(yieldedOids, oids)
    }

    func testCancelHierarchyDetailsStopsFurtherYields() async {
        let layers = (0..<5).map { _ in CALayer() }
        let oids = layers.map { register(layer: $0) }

        var package = LookinStaticAsyncUpdateTasksPackage()
        package.tasks = oids.map { oid in
            var task = LookinStaticAsyncUpdateTask()
            task.oid = oid
            task.taskType = .noScreenshot
            task.attrRequest = .notNeed
            return task
        }

        let detailsHandler = LKS_HierarchyDetailsHandler()
        var yieldedCount = 0
        for await _ in detailsHandler.generateDetails(for: [package]) {
            yieldedCount += 1
            if yieldedCount == 2 {
                detailsHandler.cancel()
            }
        }
        XCTAssertEqual(yieldedCount, 2)
    }

    func testCancelHierarchyDetailsRequestClearsInFlightWork() async {
        let layer = CALayer()
        let oid = register(layer: layer)
        var task = LookinStaticAsyncUpdateTask()
        task.oid = oid
        task.taskType = .noScreenshot
        task.attrRequest = .notNeed
        var package = LookinStaticAsyncUpdateTasksPackage()
        package.tasks = (0..<20).map { _ in task }

        let handler = LKS_RequestHandler()
        await handler.handleHierarchyDetails(object: [package], tag: 11)
        await handler.handleRequestType(UInt32(LookinPush_CanceHierarchyDetails), tag: 0, object: nil)
        await Task.yield()
    }

    func testPingDuringHierarchyDetailsDoesNotDeadlock() async {
        let layer = CALayer()
        let oid = register(layer: layer)
        var task = LookinStaticAsyncUpdateTask()
        task.oid = oid
        task.taskType = .noScreenshot
        task.attrRequest = .notNeed
        var package = LookinStaticAsyncUpdateTasksPackage()
        package.tasks = [task]

        let handler = LKS_RequestHandler()
        async let details: Void = handler.handleHierarchyDetails(object: [package], tag: 99)
        async let ping: Void = handler.handleRequestType(UInt32(LookinRequestTypePing), tag: 1, object: nil)
        _ = await (details, ping)
    }

    // MARK: - Helpers

    @discardableResult
    private func register(layer: CALayer) -> UInt {
        retainedLayers.append(layer)
        return LKS_ObjectRegistry.sharedInstance.addObject(layer)
    }
}

#endif
