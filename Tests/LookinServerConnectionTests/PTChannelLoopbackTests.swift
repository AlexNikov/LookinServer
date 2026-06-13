#if SHOULD_COMPILE_LOOKIN_SERVER

import XCTest
@testable import LookinServer

final class PTChannelLoopbackTests: XCTestCase {
    func testLoopbackEchoFrame() async throws {
#if os(iOS)
        throw XCTSkip("TCP listen is EPERM in iOS XCTest; loopback body runs on macOS Peertalk-only target")
#else
        let port: UInt16 = 47_299
        let server = PTChannel()
        let accepted = await server.acceptedChannels()
        let echoTask = Task {
            for await peer in accepted {
                let frames = await peer.frames()
                for try await frame in frames {
                    try await peer.send(type: frame.type, tag: frame.tag, payload: frame.payload)
                }
                await peer.close()
                break
            }
        }

        try await server.listen(onPort: port)

        let client = PTChannel()
        let payload = Data([1, 2, 3])
        let clientFrames = await client.frames()
        let readTask = Task {
            for try await frame in clientFrames {
                XCTAssertEqual(frame.type, 42)
                XCTAssertEqual(frame.tag, 7)
                XCTAssertEqual(frame.payload, payload)
                return
            }
            XCTFail("no frame received")
        }

        try await client.connect(toPort: port)
        try await client.send(type: 42, tag: 7, payload: payload)
        _ = try await readTask.value
        _ = await echoTask.result

        await client.close()
        await server.close()
#endif
    }
}

#endif
