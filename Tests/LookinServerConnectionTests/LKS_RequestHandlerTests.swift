#if SHOULD_COMPILE_LOOKIN_SERVER

import XCTest
@testable import LookinServerConnection

@MainActor
final class LKS_RequestHandlerTests: XCTestCase {

    func testCanHandlePingAndHierarchyDetails() async {
        let handler = LKS_RequestHandler()
        XCTAssertTrue(await handler.canHandleRequestType(UInt32(LookinRequestTypePing)))
        XCTAssertTrue(await handler.canHandleRequestType(UInt32(LookinRequestTypeHierarchyDetails)))
        XCTAssertFalse(await handler.canHandleRequestType(999_999))
    }

    func testHierarchyDetailsEmptyPackagesRespondsWithoutCrashing() async {
        let handler = LKS_RequestHandler()
        await handler.handleHierarchyDetails(object: [], tag: 42)
    }
}

#endif
