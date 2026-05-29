#if SHOULD_COMPILE_LOOKIN_SERVER

import Darwin
import Dispatch
import Foundation

// Notification names and error domain strings are declared in Lookin_PTUSBHub.h (Peertalk Swift port).

@objc public enum PTUSBHubError: Int {
    case badDevice = 2
    case connectionRefused = 3
}

private enum USBMuxPacketType: UInt32 {
    case result = 1
    case connect = 2
    case listen = 3
    case deviceAdd = 4
    case deviceRemove = 5
    case plistPayload = 8
}

private enum USBMuxPacketProtocol: UInt32 {
    case binary = 0
    case plist = 1
}

private enum USBMuxReplyCode: UInt32 {
    case ok = 0
    case badCommand = 1
    case badDevice = 2
    case connectionRefused = 3
    case badVersion = 6
}

private struct USBMuxPacketHeader {
    var size: UInt32
    var protocolNumber: UInt32
    var type: UInt32
    var tag: UInt32
}

private let kUsbmuxPacketMaxPayloadSize = UInt32.max - UInt32(MemoryLayout<USBMuxPacketHeader>.size)

private let kPlistPacketTypeListen = "Listen"
private let kPlistPacketTypeConnect = "Connect"

@objc(Lookin_PTUSBHub)
public class LookinPTUSBHub: NSObject {
    private var channel_: LookinPTUSBChannel?

    @objc(sharedHub)
    public class func shared() -> LookinPTUSBHub {
        struct Static {
            static let hub = LookinPTUSBHub()
            static let once: Void = {
                hub.listen(on: DispatchQueue.main, onStart: { error in
                    if let error {
                        NSLog("Lookin_PTUSBHub failed to initialize: %@", error as NSError)
                    }
                }, onEnd: nil)
            }()
        }
        _ = Static.once
        return Static.hub
    }

    @objc(connectToDevice:port:onStart:onEnd:)
    public func connect(
        toDevice deviceID: NSNumber,
        port: Int,
        onStart: @escaping (NSError?, DispatchIO?) -> Void,
        onEnd: ((NSError?) -> Void)?
    ) {
        let channel = LookinPTUSBChannel()
        var error: NSError?

        guard channel.open(on: DispatchQueue.main, error: &error, onEnd: onEnd) else {
            onStart(error, nil)
            return
        }

        var swappedPort = Int32(port)
        swappedPort = ((swappedPort << 8) & 0xFF00) | ((swappedPort >> 8) & 0xFF)

        let payload: [String: Any] = [
            "DeviceID": deviceID,
            "PortNumber": NSNumber(value: swappedPort),
        ]
        let packet = LookinPTUSBChannel.packetDictionary(
            withPacketType: kPlistPacketTypeConnect,
            payload: payload
        )

        channel.sendRequest(packet) { requestError, responsePacket in
            var err = requestError
            _ = channel.error(fromPlistResponse: responsePacket, error: &err)
            onStart(err, err == nil ? channel.dispatchChannel : nil)
        }
    }

    @objc(listenOnQueue:onStart:onEnd:)
    public func listen(
        on queue: DispatchQueue,
        onStart: ((NSError?) -> Void)?,
        onEnd: ((NSError?) -> Void)?
    ) {
        if channel_ != nil {
            onStart?(nil)
            return
        }
        let channel = LookinPTUSBChannel()
        var error: NSError?
        if channel.open(on: queue, error: &error, onEnd: onEnd) {
            channel_ = channel
            channel.listen(broadcastHandler: { [weak self] packet in
                self?.handleBroadcastPacket(packet)
            }, callback: onStart)
        } else {
            onStart?(error)
        }
    }

    private func handleBroadcastPacket(_ packet: NSDictionary) {
        let messageType = packet["MessageType"] as? String
        if messageType == "Attached" {
            NotificationCenter.default.post(
                name: NSNotification.Name(kLookinPTUSBDeviceDidAttachNotification),
                object: self,
                userInfo: packet as? [AnyHashable: Any]
            )
        } else if messageType == "Detached" {
            NotificationCenter.default.post(
                name: NSNotification.Name(kLookinPTUSBDeviceDidDetachNotification),
                object: self,
                userInfo: packet as? [AnyHashable: Any]
            )
        } else {
            NSLog("Warning: Unhandled broadcast message: %@", packet)
        }
    }
}

// MARK: - Internal USB channel

private final class LookinPTUSBChannel: NSObject {
    private var channel_: DispatchIO?
    private var queue_: DispatchQueue?
    private var nextPacketTag_: UInt32 = 0
    private var responseQueue_: [UInt32: (NSError?, NSDictionary?) -> Void] = [:]
    private var autoReadPackets_ = false
    private var isReadingPackets_ = false

    var dispatchChannel: DispatchIO? { channel_ }
    var fileDescriptor: Int32 {
        guard let channel_ else { return -1 }
        return channel_.fileDescriptor
    }

    static func packetDictionary(withPacketType messageType: String, payload: [String: Any]?) -> NSDictionary {
        var packet: [String: Any] = ["MessageType": messageType]

        struct BundleInfo {
            static var name: String?
            static var version: String?
            static let once: Void = {
                let info = Bundle.main.infoDictionary
                name = info?["CFBundleName"] as? String
                version = (info?["CFBundleVersion"] as? CustomStringConvertible)?.description
            }()
        }
        _ = BundleInfo.once

        if let bundleName = BundleInfo.name {
            packet["ProgName"] = bundleName
            packet["ClientVersionString"] = BundleInfo.version ?? ""
        }

        if let payload {
            for (key, value) in payload {
                packet[key] = value
            }
        }
        return packet as NSDictionary
    }

    func open(on queue: DispatchQueue, error: NSErrorPointer, onEnd: ((NSError?) -> Void)?) -> Bool {
        assert(channel_ == nil)
        queue_ = queue

        let fd = socket(AF_UNIX, SOCK_STREAM, 0)
        if fd == -1 {
            error?.pointee = NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil)
            return false
        }

        var on: Int32 = 1
        setsockopt(fd, SOL_SOCKET, SO_NOSIGPIPE, &on, socklen_t(MemoryLayout.size(ofValue: on)))

        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        _ = "/var/run/usbmuxd".withCString { cstr in
            strncpy(&addr.sun_path.0, cstr, MemoryLayout.size(ofValue: addr.sun_path) - 1)
        }
        let socklen = socklen_t(MemoryLayout<sockaddr_un>.size)

        let connectResult = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                connect(fd, $0, socklen)
            }
        }
        if connectResult == -1 {
            error?.pointee = NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil)
            Darwin.close(fd)
            return false
        }

        channel_ = DispatchIO(type: .stream, fileDescriptor: fd, queue: queue) { err in
            Darwin.close(fd)
            if let onEnd {
                if err == 0 {
                    onEnd(nil)
                } else {
                    onEnd(NSError(domain: NSPOSIXErrorDomain, code: Int(err), userInfo: nil))
                }
            }
        }
        return channel_ != nil
    }

    func listen(
        broadcastHandler: @escaping (NSDictionary) -> Void,
        callback: ((NSError?) -> Void)?
    ) {
        autoReadPackets_ = true
        scheduleReadPacket(broadcastHandler: broadcastHandler)

        let packet = Self.packetDictionary(withPacketType: kPlistPacketTypeListen, payload: nil)
        sendRequest(packet) { error, responsePacket in
            guard let callback else { return }
            var err = error
            _ = self.error(fromPlistResponse: responsePacket, error: &err)
            callback(err)
        }
    }

    func error(fromPlistResponse packet: NSDictionary?, error: NSErrorPointer) -> Bool {
        if error?.pointee != nil { return true }
        guard let n = packet?["Number"] as? NSNumber else {
            error?.pointee = NSError(domain: kLookinPTUSBHubErrorDomain, code: 0, userInfo: nil)
            return false
        }

        let replyCode = USBMuxReplyCode(rawValue: UInt32(n.intValue)) ?? .ok
        if replyCode != .ok {
            var errmessage = "Unspecified error"
            switch replyCode {
            case .badCommand: errmessage = "illegal command"
            case .badDevice: errmessage = "unknown device"
            case .connectionRefused: errmessage = "connection refused"
            case .badVersion: errmessage = "invalid version"
            default: break
            }
            error?.pointee = NSError(
                domain: kLookinPTUSBHubErrorDomain,
                code: Int(replyCode.rawValue),
                userInfo: [NSLocalizedDescriptionKey: errmessage]
            )
            return false
        }
        return true
    }

    private func nextPacketTag() -> UInt32 {
        nextPacketTag_ &+= 1
        return nextPacketTag_
    }

    func sendRequest(
        _ packet: NSDictionary,
        callback: @escaping (NSError?, NSDictionary?) -> Void
    ) {
        let tag = nextPacketTag()
        sendPacket(packet, tag: tag) { error in
            if let error {
                callback(error, nil)
                return
            }
            self.responseQueue_[tag] = callback
        }
        setNeedsReadingPacket()
    }

    private func setNeedsReadingPacket() {
        if !isReadingPackets_ {
            scheduleReadPacket(broadcastHandler: nil)
        }
    }

    private func scheduleReadPacket(broadcastHandler: ((NSDictionary) -> Void)?) {
        assert(!isReadingPackets_)
        scheduleReadPacket { [weak self] error, packet, packetTag in
            guard let self else { return }
            if packetTag == 0 {
                broadcastHandler?(packet ?? [:])
            } else if let callback = self.responseQueue_.removeValue(forKey: packetTag) {
                callback(error, packet)
            } else {
                NSLog("Warning: Ignoring reply packet for which there is no registered callback. Packet => %@", packet ?? [:])
            }
            if self.autoReadPackets_ {
                self.scheduleReadPacket(broadcastHandler: broadcastHandler)
            }
        }
    }

    private func scheduleReadPacket(
        _ callback: @escaping (NSError?, NSDictionary?, UInt32) -> Void
    ) {
        guard let channel = channel_, let queue = queue_ else { return }
        isReadingPackets_ = true

        let headerSize = MemoryLayout<UInt32>.size
        channel.read(offset: 0, length: headerSize, queue: queue) { [weak self] done, data, error in
            guard let self else { return }
            guard done else { return }

            if error != 0 {
                self.isReadingPackets_ = false
                callback(NSError(domain: NSPOSIXErrorDomain, code: Int(error), userInfo: nil), nil, 0)
                return
            }

            guard let data, data.count == headerSize else {
                self.isReadingPackets_ = false
                callback(NSError(domain: NSPOSIXErrorDomain, code: Int(error), userInfo: nil), nil, 0)
                return
            }

            let headerBytes = data.lookinCopyBytes()
            let upacketLen: UInt32 = headerBytes.withUnsafeBytes { raw -> UInt32 in
                guard raw.count >= MemoryLayout<UInt32>.size else { return 0 }
                return raw.load(as: UInt32.self)
            }

            let totalSize = Int(upacketLen)
            let offset = headerSize

            channel.read(offset: off_t(offset), length: totalSize - offset, queue: queue) { done, bodyData, readError in
                guard done else { return }
                self.isReadingPackets_ = false

                if readError != 0 {
                    callback(NSError(domain: NSPOSIXErrorDomain, code: Int(readError), userInfo: nil), nil, 0)
                    return
                }

                if upacketLen > kUsbmuxPacketMaxPayloadSize {
                    callback(
                        NSError(
                            domain: kLookinPTUSBHubErrorDomain,
                            code: 1,
                            userInfo: [NSLocalizedDescriptionKey: "Received a packet that is too large"]
                        ),
                        nil,
                        0
                    )
                    return
                }

                guard let bodyData else {
                    callback(nil, nil, 0)
                    return
                }

                var header = USBMuxPacketHeader(size: upacketLen, protocolNumber: 0, type: 0, tag: 0)
                header.size = upacketLen
                var packetBytes = Data(bytes: &header, count: headerSize)
                packetBytes.append(bodyData.lookinCopyBytes())

                guard packetBytes.count >= MemoryLayout<USBMuxPacketHeader>.size else {
                    callback(nil, nil, 0)
                    return
                }
                let headerCopy = packetBytes.withUnsafeBytes { $0.load(as: USBMuxPacketHeader.self) }

                if headerCopy.protocolNumber != USBMuxPacketProtocol.plist.rawValue {
                    callback(
                        NSError(
                            domain: kLookinPTUSBHubErrorDomain,
                            code: 0,
                            userInfo: [NSLocalizedDescriptionKey: "Unexpected package protocol"]
                        ),
                        nil,
                        headerCopy.tag
                    )
                    return
                }

                if headerCopy.type != USBMuxPacketType.plistPayload.rawValue {
                    callback(
                        NSError(
                            domain: kLookinPTUSBHubErrorDomain,
                            code: 0,
                            userInfo: [NSLocalizedDescriptionKey: "Unexpected package type"]
                        ),
                        nil,
                        headerCopy.tag
                    )
                    return
                }

                let plistStart = MemoryLayout<USBMuxPacketHeader>.size
                let plistData: Data
                if packetBytes.count > plistStart {
                    plistData = packetBytes.subdata(in: plistStart..<packetBytes.count)
                } else {
                    plistData = Data()
                }

                let dict: NSDictionary?
                if !plistData.isEmpty {
                    dict = try? PropertyListSerialization.propertyList(
                        from: plistData,
                        options: [],
                        format: nil
                    ) as? NSDictionary
                } else {
                    dict = nil
                }
                callback(nil, dict, headerCopy.tag)
            }
        }
    }

    func sendPacket(_ packet: NSDictionary, tag: UInt32, callback: @escaping (NSError?) -> Void) {
        do {
            let plistData = try PropertyListSerialization.data(
                fromPropertyList: packet,
                format: .xml,
                options: 0
            )
            sendPacket(
                type: .plistPayload,
                protocol: .plist,
                tag: tag,
                payload: plistData
            ) { callback($0) }
        } catch let err as NSError {
            callback(err)
        }
    }

    private func sendPacket(
        type: USBMuxPacketType,
        protocol proto: USBMuxPacketProtocol,
        tag: UInt32,
        payload: Data,
        callback: @escaping (NSError?) -> Void
    ) {
        assert(payload.count <= kUsbmuxPacketMaxPayloadSize)
        let headerSize = MemoryLayout<USBMuxPacketHeader>.size
        let totalSize = headerSize + payload.count
        var header = USBMuxPacketHeader(
            size: UInt32(totalSize),
            protocolNumber: proto.rawValue,
            type: type.rawValue,
            tag: tag
        )
        var packetBytes = Data(bytes: &header, count: headerSize)
        packetBytes.append(payload)
        let dispatchRef = (packetBytes as NSData).createReferencingDispatchData()
        guard let packetData = lookinDispatchData(from: dispatchRef) else {
            callback(NSError(domain: kLookinPTUSBHubErrorDomain, code: 0, userInfo: nil))
            return
        }
        sendDispatchData(packetData, callback: callback)
    }

    private func sendDispatchData(_ data: DispatchData, callback: @escaping (NSError?) -> Void) {
        guard let channel = channel_, let queue = queue_ else { return }
        channel.write(offset: 0, data: data, queue: queue) { done, _, errno in
            guard done else { return }
            if errno == 0 {
                callback(nil)
            } else {
                callback(NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil))
            }
        }
    }
}

#endif /* SHOULD_COMPILE_LOOKIN_SERVER */
