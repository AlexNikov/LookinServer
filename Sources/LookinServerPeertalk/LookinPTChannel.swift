#if SHOULD_COMPILE_LOOKIN_SERVER

import Darwin
import Dispatch
import Foundation
import ObjectiveC

private let kConnStateNone: UInt8 = 0
private let kConnStateConnecting: UInt8 = 1
private let kConnStateConnected: UInt8 = 2
private let kConnStateListening: UInt8 = 3

private let kDelegateFlagShouldAcceptFrame: UInt8 = 1
private let kDelegateFlagDidEndWithError: UInt8 = 2
private let kDelegateFlagDidAcceptConnection: UInt8 = 4

private var channelInstanceCount = 0
private var channelUniqueID = 0
private var kUserInfoKey: UInt8 = 0

@objc(Lookin_PTChannel)
public class LookinPTChannel: NSObject {
    @objc public weak var delegate: Lookin_PTChannelDelegate? {
        didSet { updateDelegateFlags() }
    }

    @objc(protocol)
    public var protocol_: LookinPTProtocol!

    @objc public private(set) var isListening = false
    @objc public private(set) var isConnected = false

    /// True while a live `DispatchIO` or listen `DispatchSource` is attached.
    @objc public var hasActiveTransport: Bool {
        dispatchChannel_ != nil || dispatchSource_ != nil
    }

    @objc public var userInfo: Any? {
        get { objc_getAssociatedObject(self, &kUserInfoKey) }
        set { objc_setAssociatedObject(self, &kUserInfoKey, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }

    @objc public var uniqueID: Int32 = 0
    @objc public var targetPort: Int = 0

    private var dispatchChannel_: DispatchIO?
    private var dispatchSource_: DispatchSourceRead?
    private var endError_: NSError?
    fileprivate var delegateFlags_: UInt8 = 0
    private var connState_: UInt8 = kConnStateNone

    @objc(channelWithDelegate:)
    public class func channel(withDelegate delegate: Lookin_PTChannelDelegate?) -> LookinPTChannel {
        let proto = LookinPTProtocol.sharedProtocol(forQueue: DispatchQueue.main)
        return LookinPTChannel(protocol: proto, delegate: delegate)
    }

    @objc(initWithProtocol:delegate:)
    public init(protocol protocol_: LookinPTProtocol, delegate: Lookin_PTChannelDelegate?) {
        self.protocol_ = protocol_
        super.init()
        self.delegate = delegate
        didInit()
    }

    @objc(initWithProtocol:)
    public init(protocol protocol_: LookinPTProtocol) {
        self.protocol_ = protocol_
        super.init()
        didInit()
    }

    public override init() {
        super.init()
        didInit()
        let proto = LookinPTProtocol.sharedProtocol(forQueue: DispatchQueue.main)
        self.protocol_ = proto
    }

    private func didInit() {
        channelUniqueID += 1
        channelInstanceCount += 1
        uniqueID = Int32(channelUniqueID)
    }

    deinit {
        channelInstanceCount -= 1
    }

    private func setConnState(_ state: UInt8) {
        connState_ = state
        isConnected = state == kConnStateConnecting || state == kConnStateConnected
        isListening = state == kConnStateListening
    }

    private func setDispatchChannel(_ channel: DispatchIO?) {
        assert(connState_ == kConnStateConnecting || connState_ == kConnStateConnected || connState_ == kConnStateNone)
        if dispatchChannel_ !== channel {
            dispatchChannel_ = channel
            if dispatchChannel_ == nil, dispatchSource_ == nil {
                connState_ = kConnStateNone
                updateConnectionFlags()
            }
        }
    }

    private func setDispatchSource(_ source: DispatchSourceRead?) {
        assert(connState_ == kConnStateListening || connState_ == kConnStateNone)
        if dispatchSource_ !== source {
            dispatchSource_ = source
            if dispatchChannel_ == nil, dispatchSource_ == nil {
                connState_ = kConnStateNone
                updateConnectionFlags()
            }
        }
    }

    private func updateConnectionFlags() {
        isConnected = connState_ == kConnStateConnecting || connState_ == kConnStateConnected
        isListening = connState_ == kConnStateListening
    }

    private func updateDelegateFlags() {
        guard delegate != nil else {
            delegateFlags_ = 0
            return
        }
        // Swift #selector on @objc optional protocol requirements is unreliable; enable all delegate hooks when a delegate is set.
        delegateFlags_ = kDelegateFlagShouldAcceptFrame | kDelegateFlagDidEndWithError | kDelegateFlagDidAcceptConnection
    }

    @objc
    public func debugTag() -> String {
        let state: String
        switch connState_ {
        case kConnStateNone: state = "None"
        case kConnStateConnecting: state = "Connecting"
        case kConnStateConnected: state = "Connected"
        case kConnStateListening: state = "Listening"
        default: state = "Undefined"
        }
        return "[\(uniqueID)-\(targetPort),\(state)]"
    }

    @objc(connectToPort:overUSBHub:deviceID:callback:)
    public func connect(
        toPort port: Int32,
        over usbHub: LookinPTUSBHub,
        deviceID: NSNumber,
        callback: ((NSError?) -> Void)?
    ) {
        assert(protocol_ != nil)
        guard connState_ == kConnStateNone else {
            callback?(NSError(domain: NSPOSIXErrorDomain, code: Int(EPERM), userInfo: nil))
            return
        }
        setConnState(kConnStateConnecting)

        usbHub.connect(toDevice: deviceID, port: Int(port), onStart: { err, dispatchChannel in
            var error = err
            if error == nil, let dispatchChannel {
                var nsError: NSError?
                if !self.startReading(fromConnectedChannel: dispatchChannel, error: &nsError) {
                    error = nsError
                }
            } else {
                self.connState_ = kConnStateNone
                self.updateConnectionFlags()
            }
            callback?(error)
        }, onEnd: { error in
            if self.delegateFlags_ & kDelegateFlagDidEndWithError != 0 {
                self.delegate?.ioFrameChannel?(self, didEndWithError: error)
            }
            self.endError_ = nil
        })
    }

    @objc(connectToPort:IPv4Address:callback:)
    public func connect(
        toPort port: UInt16,
        ipv4Address address: in_addr_t,
        callback: ((NSError?, LookinPTAddress?) -> Void)?
    ) {
        assert(protocol_ != nil)
        guard connState_ == kConnStateNone else {
            callback?(NSError(domain: NSPOSIXErrorDomain, code: Int(EPERM), userInfo: nil), nil)
            return
        }
        setConnState(kConnStateConnecting)

        let fd = socket(AF_INET, SOCK_STREAM, 0)
        if fd == -1 {
            callback?(NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil), nil)
            return
        }

        var addr = sockaddr_in()
        memset(&addr, 0, MemoryLayout<sockaddr_in>.size)
        addr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = LookinPTByteOrder.htons(port)
        addr.sin_addr.s_addr = in_addr_t(LookinPTByteOrder.htonl(UInt32(address)))

        var on: Int32 = 1
        setsockopt(fd, SOL_SOCKET, SO_NOSIGPIPE, &on, socklen_t(MemoryLayout.size(ofValue: on)))

        let connectResult = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                Darwin.connect(fd, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }

        if connectResult == -1 {
            let connectErrno = errno
            Darwin.close(fd)
            callback?(NSError(domain: NSPOSIXErrorDomain, code: Int(connectErrno), userInfo: nil), nil)
            return
        }

        let queue = protocol_.queue
        let dispatchChannel = DispatchIO(
            type: .stream,
            fileDescriptor: fd,
            queue: queue
        ) { error in
            Darwin.close(fd)
            if self.delegateFlags_ & kDelegateFlagDidEndWithError != 0 {
                let err: NSError? = error == 0
                    ? self.endError_
                    : NSError(domain: NSPOSIXErrorDomain, code: Int(error), userInfo: nil)
                self.delegate?.ioFrameChannel?(self, didEndWithError: err)
                self.endError_ = nil
            }
        }

        var storage = sockaddr_storage()
        memcpy(&storage, &addr, MemoryLayout<sockaddr_in>.size)
        storage.ss_len = UInt8(MemoryLayout<sockaddr_in>.size)
        storage.ss_family = sa_family_t(AF_INET)
        let ptAddr = LookinPTAddress(sockaddr: &storage)

        var err: NSError?
        _ = startReading(fromConnectedChannel: dispatchChannel, error: &err)
        callback?(err, ptAddr)
    }

    @objc(listenOnPort:IPv4Address:callback:)
    public func listen(
        onPort port: UInt16,
        ipv4Address address: in_addr_t,
        callback: ((NSError?) -> Void)?
    ) {
        assert(dispatchSource_ == nil)

        let fd = socket(AF_INET, SOCK_STREAM, 0)
        if fd == -1 {
            callback?(NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil))
            return
        }

        var addr = sockaddr_in()
        memset(&addr, 0, MemoryLayout<sockaddr_in>.size)
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = LookinPTByteOrder.htons(port)
        addr.sin_addr.s_addr = in_addr_t(LookinPTByteOrder.htonl(UInt32(address)))

        let socklen = socklen_t(MemoryLayout<sockaddr_in>.size)
        var on: Int32 = 1

        if setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &on, socklen_t(MemoryLayout.size(ofValue: on))) == -1 {
            Darwin.close(fd)
            callback?(NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil))
            return
        }

        if fcntl(fd, F_SETFL, O_NONBLOCK) == -1 {
            Darwin.close(fd)
            callback?(NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil))
            return
        }

        let bindResult = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                Darwin.bind(fd, $0, socklen_t(socklen))
            }
        }
        if bindResult != 0 {
            Darwin.close(fd)
            callback?(NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil))
            return
        }

        if Darwin.listen(fd, 512) != 0 {
            Darwin.close(fd)
            callback?(NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil))
            return
        }

        let source = DispatchSource.makeReadSource(fileDescriptor: fd, queue: protocol_.queue)
        // Strong capture matches ObjC Peertalk: dispatch handlers keep the channel alive until cancelled.
        source.setEventHandler {
            var nconns = source.data
            while true {
                if !self.acceptIncomingConnection(serverSocketFD: fd) {
                    break
                }
                if nconns > 0 {
                    nconns -= 1
                    if nconns == 0 {
                        break
                    }
                }
            }
        }
        source.setCancelHandler {
            self.dispatchSource_ = nil
            Darwin.close(fd)
            if self.delegateFlags_ & kDelegateFlagDidEndWithError != 0 {
                self.delegate?.ioFrameChannel?(self, didEndWithError: self.endError_)
                self.endError_ = nil
            }
        }
        source.resume()
        setDispatchSource(source)
        setConnState(kConnStateListening)
        callback?(nil)
    }

    @discardableResult
    private func acceptIncomingConnection(serverSocketFD fd: Int32) -> Bool {
        var addr = sockaddr_in()
        var addrLen = socklen_t(MemoryLayout<sockaddr_in>.size)
        let clientSocketFD = accept(fd, withUnsafeMutablePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { $0 }
        }, &addrLen)

        if clientSocketFD == -1 {
            if errno != EAGAIN && errno != EWOULDBLOCK {
                perror("accept()")
            }
            return false
        }

        var on: Int32 = 1
        setsockopt(clientSocketFD, SOL_SOCKET, SO_NOSIGPIPE, &on, socklen_t(MemoryLayout.size(ofValue: on)))

        if fcntl(clientSocketFD, F_SETFL, O_NONBLOCK) == -1 {
            perror("fcntl(.. O_NONBLOCK)")
            Darwin.close(clientSocketFD)
            return false
        }

        guard delegate != nil else {
            Darwin.close(clientSocketFD)
            return true
        }

        let peerChannel = LookinPTChannel(protocol: protocol_, delegate: delegate)
        let queue = protocol_.queue
        let dispatchChannel = DispatchIO(
            type: .stream,
            fileDescriptor: clientSocketFD,
            queue: queue
        ) { error in
            Darwin.close(clientSocketFD)
            if peerChannel.delegateFlags_ & kDelegateFlagDidEndWithError != 0 {
                let err: NSError? = error == 0
                    ? peerChannel.endError_
                    : NSError(domain: NSPOSIXErrorDomain, code: Int(error), userInfo: nil)
                peerChannel.delegate?.ioFrameChannel?(peerChannel, didEndWithError: err)
                peerChannel.endError_ = nil
            }
        }

        peerChannel.setConnState(kConnStateConnected)
        peerChannel.setDispatchChannel(dispatchChannel)

        var storage = sockaddr_storage()
        memcpy(&storage, &addr, MemoryLayout<sockaddr_in>.size)
        storage.ss_len = UInt8(addrLen)
        storage.ss_family = sa_family_t(AF_INET)
        let address = LookinPTAddress(sockaddr: &storage)
        delegate?.ioFrameChannel?(self, didAcceptConnection: peerChannel, fromAddress: address)

        var err: NSError?
        _ = peerChannel.startReading(fromConnectedChannel: dispatchChannel, error: &err)
        return true
    }

    @objc
    public func close() {
        if (connState_ == kConnStateConnecting || connState_ == kConnStateConnected), let channel = dispatchChannel_ {
            channel.close(flags: .stop)
            setDispatchChannel(nil)
        } else if connState_ == kConnStateListening, let source = dispatchSource_ {
            source.cancel()
        }
    }

    @objc
    public func cancel() {
        if (connState_ == kConnStateConnecting || connState_ == kConnStateConnected), let channel = dispatchChannel_ {
            channel.close(flags: [])
            setDispatchChannel(nil)
        } else if connState_ == kConnStateListening, let source = dispatchSource_ {
            source.cancel()
        }
    }

    @objc(startReadingFromConnectedChannel:error:)
    public func startReading(fromConnectedChannel channel: DispatchIO, error: NSErrorPointer) -> Bool {
        guard connState_ == kConnStateNone || connState_ == kConnStateConnecting || connState_ == kConnStateConnected else {
            error?.pointee = NSError(domain: NSPOSIXErrorDomain, code: Int(EPERM), userInfo: nil)
            return false
        }

        if dispatchChannel_ !== channel {
            close()
            setDispatchChannel(channel)
        }

        setConnState(kConnStateConnected)

        let handleError: (NSError?, Bool) -> Bool = { err, isEOS in
            if let err {
                self.endError_ = err
                self.close()
                return true
            }
            if isEOS {
                self.cancel()
                return true
            }
            return false
        }

        protocol_.readFrames(overChannel: channel) { frameError, type, tag, payloadSize, resumeReadingFrames in
            if handleError(frameError, type == 0) {
                return
            }

            var accepted = channel === self.dispatchChannel_
            if accepted, self.delegateFlags_ & kDelegateFlagShouldAcceptFrame != 0 {
                accepted = self.delegate?.ioFrameChannel?(
                    self,
                    shouldAcceptFrameOfType: type,
                    tag: tag,
                    payloadSize: payloadSize
                ) ?? true
            }

            if payloadSize == 0 {
                if accepted, let delegate = self.delegate {
                    delegate.ioFrameChannel(self, didReceiveFrameOfType: type, tag: tag, payload: nil)
                }
                resumeReadingFrames()
            } else if !accepted {
                self.protocol_.readAndDiscardData(ofSize: Int(payloadSize), overChannel: channel) { discardError, endOfStream in
                    if !handleError(discardError, endOfStream) {
                        resumeReadingFrames()
                    }
                }
            } else {
                self.protocol_.readPayload(ofSize: Int(payloadSize), overChannel: channel) { payloadError, contiguousData, buffer, bufferSize in
                    if handleError(payloadError, bufferSize == 0) {
                        return
                    }
                    if let delegate = self.delegate {
                        let payload = LookinPTData(
                            mappedDispatchData: contiguousData,
                            data: buffer.map { UnsafeMutableRawPointer(mutating: $0) },
                            length: bufferSize
                        )
                        delegate.ioFrameChannel(self, didReceiveFrameOfType: type, tag: tag, payload: payload)
                    }
                    resumeReadingFrames()
                }
            }
        }

        return true
    }

    @objc(sendFrameOfType:tag:withPayload:callback:)
    public func sendFrame(
        ofType frameType: UInt32,
        tag: UInt32,
        withPayload payload: dispatch_data_t?,
        callback: ((NSError?) -> Void)?
    ) {
        guard connState_ == kConnStateConnecting || connState_ == kConnStateConnected,
              let channel = dispatchChannel_ else {
            callback?(NSError(domain: NSPOSIXErrorDomain, code: Int(EPERM), userInfo: nil))
            return
        }
        protocol_.sendFrame(ofType: frameType, tag: tag, withPayload: payload, overChannel: channel, callback: callback)
    }

    public override var description: String {
        let state: String
        switch connState_ {
        case kConnStateConnecting: state = "connecting"
        case kConnStateConnected: state = "connected"
        case kConnStateListening: state = "listening"
        default: state = "closed"
        }
        let info = userInfo.map { " \($0)" } ?? ""
        return String(format: "<Lookin_PTChannel: %p (%@)%@%@>", self, state, info.isEmpty ? "" : " ", info)
    }
}

@objc(Lookin_PTChannelDelegate)
public protocol Lookin_PTChannelDelegate: NSObjectProtocol {
    @objc(ioFrameChannel:didReceiveFrameOfType:tag:payload:)
    func ioFrameChannel(
        _ channel: LookinPTChannel,
        didReceiveFrameOfType type: UInt32,
        tag: UInt32,
        payload: LookinPTData?
    )

    @objc optional func ioFrameChannel(
        _ channel: LookinPTChannel,
        shouldAcceptFrameOfType type: UInt32,
        tag: UInt32,
        payloadSize: UInt32
    ) -> Bool

    @objc optional func ioFrameChannel(_ channel: LookinPTChannel, didEndWithError error: NSError?)

    @objc optional func ioFrameChannel(
        _ channel: LookinPTChannel,
        didAcceptConnection otherChannel: LookinPTChannel,
        fromAddress address: LookinPTAddress
    )
}

#endif /* SHOULD_COMPILE_LOOKIN_SERVER */
