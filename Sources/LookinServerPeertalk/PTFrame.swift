#if SHOULD_COMPILE_LOOKIN_SERVER

import Foundation

/// Application-layer Peertalk frame (replaces `LookinPTData` in async code paths).
public struct PTFrame: Sendable {
    public let type: UInt32
    public let tag: UInt32
    public let payload: Data

    public init(type: UInt32, tag: UInt32, payload: Data = Data()) {
        self.type = type
        self.tag = tag
        self.payload = payload
    }
}

#endif
