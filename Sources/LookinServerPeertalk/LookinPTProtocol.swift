#if SHOULD_COMPILE_LOOKIN_SERVER

import Darwin
import Dispatch
import Foundation

private let ptProtocolVersion1: UInt32 = 1

// Error domain string is declared in Lookin_PTProtocol.h (Peertalk Swift port).

private struct PTFrame {
    var version: UInt32
    var type: UInt32
    var tag: UInt32
    var payloadSize: UInt32
}

private final class LookinRQueueLocalIOFrameProtocol: LookinPTProtocol {
    override var queue: DispatchQueue {
        get { super.queue }
        set { /* queue is fixed for queue-local instance */ }
    }
}

@objc(Lookin_PTProtocol)
public class LookinPTProtocol: NSObject {
    @objc public var queue: DispatchQueue {
        get {
            if let q = queue_ {
                return q
            }
            return DispatchQueue.main
        }
        set {
            queue_ = newValue
        }
    }

    fileprivate var queue_: DispatchQueue?
    private var nextFrameTag_: UInt32 = 0

    private static let currentQueueFrameProtocolKey = DispatchSpecificKey<Unmanaged<LookinPTProtocol>>()

    @objc(sharedProtocolForQueue:)
    public class func sharedProtocol(forQueue queue: DispatchQueue) -> LookinPTProtocol {
        if let existing = queue.getSpecific(key: currentQueueFrameProtocolKey)?.takeUnretainedValue() {
            return existing
        }
        let protocol_ = LookinRQueueLocalIOFrameProtocol()
        protocol_.queue_ = queue
        queue.setSpecific(key: currentQueueFrameProtocolKey, value: Unmanaged.passRetained(protocol_))
        return queue.getSpecific(key: currentQueueFrameProtocolKey)!.takeUnretainedValue()
    }

    @objc(initWithDispatchQueue:)
    public init(dispatchQueue queue: DispatchQueue) {
        queue_ = queue
        super.init()
    }

    public override init() {
        queue_ = DispatchQueue.main
        super.init()
    }

    @objc
    public func newTag() -> UInt32 {
        nextFrameTag_ &+= 1
        return nextFrameTag_
    }

    private func createDispatchData(frameType type: UInt32, frameTag: UInt32, payload: DispatchData?) -> DispatchData {
        var frame = PTFrame(version: 0, type: 0, tag: 0, payloadSize: 0)
        frame.version = ptProtocolVersion1.bigEndian
        frame.type = type.bigEndian
        frame.tag = frameTag.bigEndian

        let payloadSize: UInt32
        if let payload, !payload.isEmpty {
            let size = payload.count
            assert(size <= UInt32.max)
            payloadSize = UInt32(size).bigEndian
        } else {
            payloadSize = 0
        }
        frame.payloadSize = payloadSize

        var frameCopy = frame
        let frameData = withUnsafePointer(to: &frameCopy) { ptr -> DispatchData in
            DispatchData(bytes: UnsafeRawBufferPointer(start: ptr, count: MemoryLayout<PTFrame>.size))
        }

        guard let payload, !payload.isEmpty, payloadSize != 0 else {
            return frameData
        }
        var combined = frameData
        combined.append(payload)
        return combined
    }

    @objc(sendFrameOfType:tag:withPayload:overChannel:callback:)
    public func sendFrame(
        ofType frameType: UInt32,
        tag: UInt32,
        withPayload payload: dispatch_data_t?,
        overChannel channel: DispatchIO,
        callback: ((NSError?) -> Void)?
    ) {
        let frame = createDispatchData(frameType: frameType, frameTag: tag, payload: lookinDispatchData(from: payload))
        let queue = queue_ ?? DispatchQueue.main
        channel.write(offset: 0, data: frame, queue: queue) { done, _, errno in
            if done, let callback {
                if errno == 0 {
                    callback(nil)
                } else {
                    callback(NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil))
                }
            }
        }
    }

    @objc(readFrameOverChannel:callback:)
    public func readFrame(
        overChannel channel: DispatchIO,
        callback: @escaping (NSError?, UInt32, UInt32, UInt32) -> Void
    ) {
        var allData: DispatchData?
        let queue = queue_ ?? DispatchQueue.main

        channel.read(offset: 0, length: MemoryLayout<PTFrame>.size, queue: queue) { done, data, error in
            let dataSize = data?.count ?? 0

            if let data, dataSize > 0 {
                if allData == nil {
                    allData = data
                } else {
                    var combined = allData!
                    combined.append(data)
                    allData = combined
                }
            }

            guard done else { return }

            if error != 0 {
                callback(NSError(domain: NSPOSIXErrorDomain, code: Int(error), userInfo: nil), 0, 0, 0)
                return
            }

            if dataSize == 0 {
                callback(nil, 0, 0, 0) // PTFrameTypeEndOfStream
                return
            }

            guard let allData, allData.count >= MemoryLayout<PTFrame>.size else {
                callback(NSError(domain: kLookinPTProtocolErrorDomain, code: 0, userInfo: nil), 0, 0, 0)
                return
            }

            let frame = allData.lookinCopyBytes().withUnsafeBytes { $0.load(as: PTFrame.self) }
            let version = UInt32(bigEndian: frame.version)
            guard version == ptProtocolVersion1 else {
                callback(NSError(domain: kLookinPTProtocolErrorDomain, code: 0, userInfo: nil), 0, 0, 0)
                return
            }
            let type = UInt32(bigEndian: frame.type)
            let tag = UInt32(bigEndian: frame.tag)
            let payloadSize = UInt32(bigEndian: frame.payloadSize)
            callback(nil, type, tag, payloadSize)
        }
    }

    @objc(readPayloadOfSize:overChannel:callback:)
    public func readPayload(
        ofSize payloadSize: Int,
        overChannel channel: DispatchIO,
        callback: @escaping (NSError?, dispatch_data_t?, UnsafePointer<UInt8>?, Int) -> Void
    ) {
        var allData: DispatchData?
        let queue = queue_ ?? DispatchQueue.main

        channel.read(offset: 0, length: payloadSize, queue: queue) { done, data, error in
            let dataSize = data?.count ?? 0

            if let data, dataSize > 0 {
                if allData == nil {
                    allData = data
                } else {
                    var combined = allData!
                    combined.append(data)
                    allData = combined
                }
            }

            guard done else { return }

            if error != 0 {
                callback(NSError(domain: NSPOSIXErrorDomain, code: Int(error), userInfo: nil), nil, nil, 0)
                return
            }

            if dataSize == 0 {
                callback(nil, nil, nil, 0)
                return
            }

            guard let allData else {
                callback(nil, nil, nil, 0)
                return
            }

            let copied = allData.lookinCopyBytes()
            copied.withUnsafeBytes { raw in
                let buffer = raw.baseAddress?.assumingMemoryBound(to: UInt8.self)
                callback(nil, allData.lookinDispatchDataRef, buffer, raw.count)
            }
        }
    }

    @objc(readAndDiscardDataOfSize:overChannel:callback:)
    public func readAndDiscardData(
        ofSize size: Int,
        overChannel channel: DispatchIO,
        callback: ((NSError?, Bool) -> Void)?
    ) {
        let queue = queue_ ?? DispatchQueue.main
        channel.read(offset: 0, length: size, queue: queue) { done, data, error in
            guard done, let callback else { return }
            let dataSize = data?.count ?? 0
            if error == 0 {
                callback(nil, dataSize == 0)
            } else {
                callback(NSError(domain: NSPOSIXErrorDomain, code: Int(error), userInfo: nil), dataSize == 0)
            }
        }
    }

    @objc(readFramesOverChannel:onFrame:)
    public func readFrames(
        overChannel channel: DispatchIO,
        onFrame: @escaping (NSError?, UInt32, UInt32, UInt32, @escaping () -> Void) -> Void
    ) {
        readFrame(overChannel: channel) { error, type, tag, payloadSize in
            onFrame(error, type, tag, payloadSize) {
                guard type != 0 else { return } // PTFrameTypeEndOfStream
                self.readFrames(overChannel: channel, onFrame: onFrame)
            }
        }
    }
}

#endif /* SHOULD_COMPILE_LOOKIN_SERVER */
