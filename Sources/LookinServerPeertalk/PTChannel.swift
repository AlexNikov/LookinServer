#if SHOULD_COMPILE_LOOKIN_SERVER

import Darwin
import Dispatch
import Foundation

private let kConnStateNone: UInt8 = 0
private let kConnStateConnecting: UInt8 = 1
private let kConnStateConnected: UInt8 = 2
private let kConnStateListening: UInt8 = 3

private var ptChannelInstanceCount = 0
private var ptChannelUniqueID = 0

/// Swift Concurrency Peertalk channel (replaces delegate-driven `LookinPTChannel` on iOS server).
public actor PTChannel {
    public let uniqueID: Int32
    public var targetPort: Int = 0
    public private(set) var isListening = false
    public private(set) var isConnected = false

    public var hasActiveTransport: Bool {
        dispatchIO != nil || dispatchSource != nil
    }

    private let ioQueue: DispatchQueue
    private let protocol_: LookinPTProtocol
    private var dispatchIO: DispatchIO?
    private var dispatchSource: DispatchSourceRead?
    private var endError: NSError?
    private var connState: UInt8 = kConnStateNone
    private var frameContinuation: AsyncThrowingStream<PTFrame, Error>.Continuation?
    private var acceptContinuation: AsyncStream<PTChannel>.Continuation?
    private var readLoopTask: Task<Void, Never>?

    public init() {
        let queue = DispatchQueue(label: "com.lookin.ptchannel.\(ptChannelUniqueID + 1)")
        self.init(ioQueue: queue)
    }

    private init(ioQueue queue: DispatchQueue) {
        ptChannelUniqueID += 1
        ptChannelInstanceCount += 1
        uniqueID = Int32(ptChannelUniqueID)
        ioQueue = queue
        protocol_ = LookinPTProtocol.sharedProtocol(forQueue: ioQueue)
    }

    deinit {
        ptChannelInstanceCount -= 1
        readLoopTask?.cancel()
    }

    public func debugTag() -> String {
        let state: String
        switch connState {
        case kConnStateNone: state = "None"
        case kConnStateConnecting: state = "Connecting"
        case kConnStateConnected: state = "Connected"
        case kConnStateListening: state = "Listening"
        default: state = "Undefined"
        }
        return "[\(uniqueID)-\(targetPort),\(state)]"
    }

    // MARK: - Listen / connect

    public func listen(onPort port: UInt16, ipv4Address address: in_addr_t = in_addr_t(INADDR_LOOPBACK)) async throws {
        guard dispatchSource == nil else {
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(EPERM), userInfo: nil)
        }

        let fd = socket(AF_INET, SOCK_STREAM, 0)
        guard fd != -1 else {
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil)
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
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil)
        }
        if fcntl(fd, F_SETFL, O_NONBLOCK) == -1 {
            Darwin.close(fd)
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil)
        }

        let bindResult = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                Darwin.bind(fd, $0, socklen)
            }
        }
        if bindResult != 0 {
            Darwin.close(fd)
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil)
        }
        if Darwin.listen(fd, 512) != 0 {
            Darwin.close(fd)
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil)
        }

        let source = DispatchSource.makeReadSource(fileDescriptor: fd, queue: ioQueue)
        source.setEventHandler { [weak self] in
            guard let self else { return }
            Task { await self.handleListenEvents(serverSocketFD: fd) }
        }
        source.setCancelHandler { [weak self] in
            guard let self else { return }
            Task { await self.handleListenCancelled(fd: fd) }
        }
        source.resume()
        dispatchSource = source
        connState = kConnStateListening
        isListening = true
        targetPort = Int(port)
    }

    private func handleListenEvents(serverSocketFD fd: Int32) async {
        guard let source = dispatchSource else { return }
        var pending = source.data
        while true {
            guard await acceptIncomingConnection(serverSocketFD: fd) else { break }
            if pending > 0 {
                pending -= 1
                if pending == 0 { break }
            } else {
                break
            }
        }
    }

    private func handleListenCancelled(fd: Int32) {
        dispatchSource = nil
        Darwin.close(fd)
        connState = kConnStateNone
        isListening = false
        acceptContinuation?.finish()
        acceptContinuation = nil
    }

    @discardableResult
    private func acceptIncomingConnection(serverSocketFD fd: Int32) async -> Bool {
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

        var storage = sockaddr_storage()
        memcpy(&storage, &addr, MemoryLayout<sockaddr_in>.size)
        storage.ss_len = UInt8(addrLen)
        storage.ss_family = sa_family_t(AF_INET)
        let ptAddress = LookinPTAddress(sockaddr: &storage)

        let peerChannel = PTChannel(ioQueue: ioQueue)
        await peerChannel.attachConnectedTransport(makeDispatchIO(fd: clientSocketFD), port: ptAddress.port)
        acceptContinuation?.yield(peerChannel)
        return true
    }

    private func attachConnectedTransport(_ io: DispatchIO, port: Int) {
        dispatchIO = io
        connState = kConnStateConnected
        isConnected = true
        targetPort = port
    }

    private func makeDispatchIO(fd: Int32) -> DispatchIO {
        DispatchIO(type: .stream, fileDescriptor: fd, queue: ioQueue) { [weak self] error in
            Darwin.close(fd)
            guard let self else { return }
            Task {
                await self.handleTransportEnd(error: error == 0 ? nil : NSError(domain: NSPOSIXErrorDomain, code: Int(error), userInfo: nil))
            }
        }
    }

    public func connect(
        toPort port: Int32,
        over usbHub: LookinPTUSBHub,
        deviceID: NSNumber
    ) async throws {
        guard connState == kConnStateNone else {
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(EPERM), userInfo: nil)
        }
        connState = kConnStateConnecting
        isConnected = true
        let io = try await usbHub.connectAsync(toDevice: deviceID, port: Int(port))
        dispatchIO = io
        connState = kConnStateConnected
        await startReadLoop()
    }

    // MARK: - Frames stream

    public func frames() -> AsyncThrowingStream<PTFrame, Error> {
        AsyncThrowingStream { continuation in
            frameContinuation = continuation
            continuation.onTermination = { [weak self] _ in
                guard let self else { return }
                Task { await self.clearFrameContinuation() }
            }
            startReadLoop()
        }
    }

    public func acceptedChannels() -> AsyncStream<PTChannel> {
        AsyncStream { continuation in
            acceptContinuation = continuation
            continuation.onTermination = { [weak self] _ in
                guard let self else { return }
                Task { await self.clearAcceptContinuation() }
            }
        }
    }

    private func clearFrameContinuation() {
        frameContinuation = nil
    }

    private func clearAcceptContinuation() {
        acceptContinuation = nil
    }

    public func startReadLoop() {
        guard readLoopTask == nil else { return }
        readLoopTask = Task { await self.runReadLoop() }
    }

    private func runReadLoop() async {
        do {
            while !Task.isCancelled {
                let frame = try await readNextFrame()
                if frame.type == 0 { break }
                frameContinuation?.yield(frame)
            }
            frameContinuation?.finish()
        } catch {
            frameContinuation?.finish(throwing: error)
        }
    }

    private func readNextFrame() async throws -> PTFrame {
        guard let channel = dispatchIO else {
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(EPERM), userInfo: nil)
        }
        let header = try await readFrameHeader(over: channel)
        if header.type == 0 {
            return PTFrame(type: 0, tag: 0)
        }
        if header.payloadSize == 0 {
            return PTFrame(type: header.type, tag: header.tag)
        }
        let payload = try await readPayload(size: Int(header.payloadSize), over: channel)
        return PTFrame(type: header.type, tag: header.tag, payload: payload)
    }

    private struct FrameHeader {
        var type: UInt32
        var tag: UInt32
        var payloadSize: UInt32
    }

    private func readFrameHeader(over channel: DispatchIO) async throws -> FrameHeader {
        try await withCheckedThrowingContinuation { continuation in
            protocol_.readFrame(overChannel: channel) { error, type, tag, payloadSize in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: FrameHeader(type: type, tag: tag, payloadSize: payloadSize))
            }
        }
    }

    private func readPayload(size: Int, over channel: DispatchIO) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            protocol_.readPayload(ofSize: size, overChannel: channel) { error, contiguousData, buffer, bufferSize in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                if bufferSize == 0 {
                    continuation.resume(returning: Data())
                    return
                }
                if let contiguousData, let dispatchData = lookinDispatchData(from: contiguousData) {
                    continuation.resume(returning: dispatchData.lookinCopyBytes())
                    return
                }
                if let buffer {
                    continuation.resume(returning: Data(bytes: buffer, count: bufferSize))
                    return
                }
                continuation.resume(returning: Data())
            }
        }
    }

    // MARK: - Send / close

    public func send(type: UInt32, tag: UInt32, payload: Data) async throws {
        guard connState == kConnStateConnecting || connState == kConnStateConnected,
              let channel = dispatchIO else {
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(EPERM), userInfo: nil)
        }
        let dispatchPayload: dispatch_data_t? = payload.isEmpty ? nil : (payload as NSData).createReferencingDispatchData()
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            protocol_.sendFrame(ofType: type, tag: tag, withPayload: dispatchPayload, overChannel: channel) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    public func close() {
        if (connState == kConnStateConnecting || connState == kConnStateConnected), let channel = dispatchIO {
            channel.close(flags: .stop)
            dispatchIO = nil
        } else if connState == kConnStateListening, let source = dispatchSource {
            source.cancel()
        }
        readLoopTask?.cancel()
        readLoopTask = nil
        updateConnectionFlags()
    }

    public func cancel() {
        if (connState == kConnStateConnecting || connState == kConnStateConnected), let channel = dispatchIO {
            channel.close(flags: [])
            dispatchIO = nil
        } else if connState == kConnStateListening, let source = dispatchSource {
            source.cancel()
        }
        readLoopTask?.cancel()
        readLoopTask = nil
        updateConnectionFlags()
    }

    private func handleTransportEnd(error: NSError?) {
        endError = error
        frameContinuation?.finish(throwing: error ?? POSIXError(.EIO))
        frameContinuation = nil
        cancel()
    }

    private func updateConnectionFlags() {
        isConnected = connState == kConnStateConnecting || connState == kConnStateConnected
        isListening = connState == kConnStateListening
        if dispatchIO == nil && dispatchSource == nil {
            connState = kConnStateNone
            isConnected = false
            isListening = false
        }
    }
}

extension LookinPTUSBHub {
    func connectAsync(toDevice deviceID: NSNumber, port: Int) async throws -> DispatchIO {
        try await withCheckedThrowingContinuation { continuation in
            self.connect(toDevice: deviceID, port: port, onStart: { error, io in
                if let error {
                    continuation.resume(throwing: error)
                } else if let io {
                    continuation.resume(returning: io)
                } else {
                    continuation.resume(throwing: NSError(domain: NSPOSIXErrorDomain, code: Int(EIO), userInfo: nil))
                }
            }, onEnd: nil)
        }
    }
}

#endif
