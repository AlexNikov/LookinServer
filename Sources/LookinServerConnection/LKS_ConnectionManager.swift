#if canImport(LookinShared)
import LookinShared
#endif
#if SHOULD_COMPILE_LOOKIN_SERVER

import Darwin
import Foundation
import UIKit

@MainActor
public final class LKS_ConnectionManager: NSObject {

    @objc public static let sharedInstance = LKS_ConnectionManager()

    /// Replaces ObjC `+load` — triggers singleton initialization when the module loads.
    public static let bootstrap: Void = {
        _ = sharedInstance
        return ()
    }()

    @objc public var applicationIsActive = false

    private var peerChannel: PTChannel?
    private var peerChannelUniqueID: Int32?
    private var listenChannel: PTChannel?
    private var peertalkListenPortCache = 0
    private var peertalkIsConnectedCache = false
    private var listeningTask: Task<Void, Never>?
    private var frameLoopTask: Task<Void, Never>?
    private var watchdogTask: Task<Void, Never>?
    let requestHandler = LKS_RequestHandler()
    private var lastPeerFrameAt: TimeInterval = 0

    private override init() {
        super.init()
        NSLog("LookinServer - Will launch. Framework version: %@", lookinServerReadableVersion)

        startLifecycleObservers()
        startMCPHTTPServerIfAvailable(port: 47190)
        startWatchdog()
    }

    deinit {
        listeningTask?.cancel()
        frameLoopTask?.cancel()
        watchdogTask?.cancel()
    }

    // MARK: - Lifecycle

    private func startLifecycleObservers() {
        if #available(iOS 15.0, *) {
            Task { @MainActor [weak self] in
                for await _ in NotificationCenter.default.notifications(named: UIApplication.didBecomeActiveNotification) {
                    self?.applicationIsActive = true
                    self?.recycleStaleConnectedPeerIfNeeded(minIdle: 0.25)
                    await self?.searchPortToListenIfNoConnection()
                }
            }
            Task { @MainActor [weak self] in
                for await _ in NotificationCenter.default.notifications(named: UIApplication.didFinishLaunchingNotification) {
                    await self?.searchPortToListenIfNoConnection()
                }
            }
            Task { @MainActor [weak self] in
                for await _ in NotificationCenter.default.notifications(named: UIApplication.willResignActiveNotification) {
                    self?.applicationIsActive = false
                    self?.handleWillResignActive()
                }
            }
            if #available(iOS 13.0, *) {
                Task { @MainActor [weak self] in
                    for await _ in NotificationCenter.default.notifications(named: UIScene.didActivateNotification) {
                        self?.applicationIsActive = true
                        self?.recycleStaleConnectedPeerIfNeeded(minIdle: 0.25)
                        await self?.searchPortToListenIfNoConnection()
                    }
                }
            }
        } else {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(_handleApplicationDidBecomeActive),
                name: UIApplication.didBecomeActiveNotification,
                object: nil
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(_handleApplicationDidFinishLaunching),
                name: UIApplication.didFinishLaunchingNotification,
                object: nil
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(_handleWillResignActiveNotification),
                name: UIApplication.willResignActiveNotification,
                object: nil
            )
            if #available(iOS 13.0, *) {
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(_handleSceneDidActivate),
                    name: UIScene.didActivateNotification,
                    object: nil
                )
            }
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(_handleLocalInspect(_:)),
            name: .lookin2D,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(_handleLocalInspect(_:)),
            name: .lookin3D,
            object: nil
        )
        NotificationCenter.default.addObserver(
            forName: .lookinExport,
            object: nil,
            queue: .main
        ) { _ in
            LKS_ExportManager.sharedInstance().exportAndShare()
        }
        NotificationCenter.default.addObserver(
            forName: .lookinRelationSearch,
            object: nil,
            queue: .main
        ) { note in
            LKS_TraceManager.sharedInstance().addSearchTarger(note.object)
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleGetLookinInfo(_:)),
            name: .getLookinInfo,
            object: nil
        )
    }

    private func startWatchdog() {
        watchdogTask?.cancel()
        watchdogTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { return }
                self?.checkPeertalkZombiePeer()
            }
        }
    }

    // MARK: - Public API

    public func respond(_ data: LKConnectionResponseAttachment, requestType: UInt32, tag: UInt32) {
        respondWireV2(data, requestType: requestType, tag: tag)
    }

    @objc(pushData:type:)
    public func pushData(_ data: NSObject, type: UInt32) {
        guard LookinWirePushTypes.all.contains(type) else {
            NSLog("LookinServer - unsupported push type:%u", type)
            return
        }
        do {
            let jsonData = try LKWireCodecV2.encodeJSON(WirePushEnvelope(pushType: type))
            sendRawPayload(jsonData, frameOfType: type, tag: 0)
        } catch {
            NSLog("LookinServer - wire v2 push JSON encode failed type:%u: %@", type, error as NSError)
        }
    }

    @objc public func mcpPeertalkListenPort() -> Int {
        peertalkListenPortCache
    }

    @objc public func mcpPeertalkIsConnected() -> Bool {
        peertalkIsConnectedCache
    }

    private func updatePeertalkCache(using channel: PTChannel?) async {
        guard let channel else {
            peertalkListenPortCache = 0
            peertalkIsConnectedCache = false
            return
        }
        let listening = await channel.isListening
        peertalkListenPortCache = listening ? await channel.targetPort : 0
        peertalkIsConnectedCache = await channel.isConnected
    }

    @objc public func nudgePeertalkListenForLaunchScreenDiscoveryIfNeeded() {
        Task { await searchPortToListenIfNoConnection() }
    }

    @objc public func searchPortToListenIfNoConnection() {
        Task { await searchPortToListenIfNoConnection() }
    }

    @objc public func prepareForNewMacClientConnection() {
        recycleStaleConnectedPeerIfNeeded(minIdle: 0)
        Task { await searchPortToListenIfNoConnection() }
    }

    // MARK: - Peertalk orchestration

    private func searchPortToListenIfNoConnection() async {
        await clearDeadPeersIfNeeded()
        await recycleStaleListenPeerIfNeeded()
        await recycleStaleConnectedPeerIfNeededAsync(minIdle: 0.25)

        if let peer = peerChannel, await peer.isConnected, await peer.hasActiveTransport {
            let idle = Date().timeIntervalSince1970 - lastPeerFrameAt
            if lastPeerFrameAt > 0, idle < 0.25 {
                NSLog("LookinServer - Abort to search ports. Already has connected channel.")
                return
            }
        }

        NSLog("LookinServer - Searching port to listen...")
        frameLoopTask?.cancel()
        frameLoopTask = nil
        listeningTask?.cancel()
        listeningTask = nil
        if let listen = listenChannel {
            await listen.close()
            listenChannel = nil
        }
        if let peer = peerChannel {
            await peer.close()
            peerChannel = nil
            peerChannelUniqueID = nil
        }
        lastPeerFrameAt = 0

        if isiOSAppOnMac() {
            await searchPortToListen(from: Int32(LookinSimulatorIPv4PortNumberStart), to: Int32(LookinSimulatorIPv4PortNumberEnd))
        } else {
            await searchPortToListen(from: Int32(LookinUSBDeviceIPv4PortNumberStart), to: Int32(LookinUSBDeviceIPv4PortNumberEnd))
        }
    }

    private func searchPortToListen(from: Int32, to: Int32) async {
        var current = from
        while current <= to {
            let channel = PTChannel()
            do {
                try await channel.listen(onPort: UInt16(current))
                NSLog("LookinServer - Connected successfully on 127.0.0.1:%d", current)
                LookinDiagLog.log("Peertalk listen OK port=\(current)")
                listenChannel = channel
                peerChannel = channel
                peerChannelUniqueID = await channel.uniqueID
                await updatePeertalkCache(using: channel)
                listeningTask = Task { @MainActor [weak self] in
                    await self?.runAcceptLoop(on: channel)
                }
                return
            } catch {
                if current < to {
                    NSLog("LookinServer - 127.0.0.1:%d is unavailable(%@). Will try anothor address ...", current, error as NSError)
                    LookinDiagLog.log("Peertalk listen skip port=\(current) errno=\((error as NSError).code)")
                    current += 1
                } else {
                    NSLog("LookinServer - 127.0.0.1:%d is unavailable(%@).", current, error as NSError)
                    NSLog(
                        "LookinServer - Peertalk listen FAILED on all ports %d-%d (errno in log above). Rebuild iOS app after pod install.",
                        from,
                        to
                    )
                    return
                }
            }
        }
    }

    private func runAcceptLoop(on listenChannel: PTChannel) async {
        for await peer in await listenChannel.acceptedChannels() {
            let previous = peerChannel
            peerChannel = peer
            peerChannelUniqueID = await peer.uniqueID
            await updatePeertalkCache(using: peer)
            lastPeerFrameAt = Date().timeIntervalSince1970
            if let previous {
                let previousID = await previous.uniqueID
                let listenID = await listenChannel.uniqueID
                if previousID != listenID {
                    await previous.cancel()
                }
            }
            frameLoopTask?.cancel()
            frameLoopTask = Task { @MainActor [weak self] in
                await self?.runFrameLoop(on: peer)
            }
            pushData(NSObject(), type: LookinWirePushTypes.serverReady)
        }
        await searchPortToListenIfNoConnection()
    }

    private func runFrameLoop(on channel: PTChannel) async {
        let channelID = await channel.uniqueID
        do {
            for try await frame in await channel.frames() {
                guard peerChannelUniqueID == channelID else { break }
                lastPeerFrameAt = Date().timeIntervalSince1970
                await handleFrame(frame)
            }
        } catch {
            await handleChannelEnd(channelID: channelID, error: error as NSError)
        }
    }

    private func handleFrame(_ frame: PTFrame) async {
        guard !frame.payload.isEmpty else {
            NSLog("LookinServer - didReceive frame type:%u tag:%u empty payload", frame.type, frame.tag)
            return
        }
        if frame.type != LookinWireFormat.frameTypeJSON,
           frame.type != LookinWireFormat.frameTypeScreenshot,
           !(await requestHandler.canHandleRequestType(frame.type)) {
            NSLog("LookinServer - reject unknown frame type:%u tag:%u", frame.type, frame.tag)
            await peerChannel?.close()
            return
        }
        let data = frame.payload
        if frame.type == LookinWireFormat.frameTypeJSON {
            await handleWireJSONCommand(data, tag: frame.tag)
            return
        }
        do {
            let envelope = try LKWireCodecV2.decodeJSON(WireRequestEnvelope.self, from: data)
            await handleWireJSONRequest(envelope, tag: frame.tag)
            return
        } catch {
            if data.first == UInt8(ascii: "{") {
                NSLog(
                    "LookinServer - wire request JSON decode failed type:%u tag:%u bytes:%zu error:%@ preview:%@",
                    frame.type,
                    frame.tag,
                    data.count,
                    error as NSError,
                    String(data: data.prefix(120), encoding: .utf8) ?? ""
                )
            }
        }
        if LookinWirePushTypes.all.contains(frame.type),
           let push = try? LKWireCodecV2.decodeJSON(WirePushEnvelope.self, from: data) {
            guard LookinWireFormat.validateWireVersion(push.wireVersion, context: "push") else {
                return
            }
            await requestHandler.handleRequestType(push.pushType, tag: frame.tag, object: nil)
            return
        }
        NSLog(
            "LookinServer - expected JSON request/push, got type:%u tag:%u payload:%zu",
            frame.type,
            frame.tag,
            data.count
        )
    }

    private func handleChannelEnd(channelID: Int32, error: NSError?) async {
        guard peerChannelUniqueID == channelID else {
            if peerChannel == nil {
                await searchPortToListenIfNoConnection()
            }
            return
        }
        NSLog("LookinServer - channel DidEndWithError:%@", String(describing: error))
        NotificationCenter.default.post(
            name: NSNotification.Name(rawValue: LKS_ConnectionDidEndNotificationName as String),
            object: self
        )
        peerChannel = nil
        peerChannelUniqueID = nil
        peertalkListenPortCache = 0
        peertalkIsConnectedCache = false
        lastPeerFrameAt = 0
        await searchPortToListenIfNoConnection()
        try? await Task.sleep(nanoseconds: 300_000_000)
        await searchPortToListenIfNoConnection()
    }

    func sendRawPayload(_ data: Data, frameOfType: UInt32, tag: UInt32) {
        guard let peerChannel else { return }
        Task {
            do {
                try await peerChannel.send(type: frameOfType, tag: tag, payload: data)
            } catch {
                NSLog(
                    "LookinServer - wire v2 sendFrame failed type:%u tag:%u error:%@",
                    frameOfType,
                    tag,
                    error as NSError
                )
            }
        }
    }

    // MARK: - Peer maintenance

    private func clearDeadPeersIfNeeded() async {
        if let peer = peerChannel, !(await peer.isListening), !(await peer.isConnected) {
            LookinDiagLog.log("iOS clear dead Peertalk peer — re-listen")
            await peer.close()
            peerChannel = nil
            peerChannelUniqueID = nil
            lastPeerFrameAt = 0
        }
        if !isiOSAppOnMac(),
           let peer = peerChannel,
           await peer.isConnected,
           !(await peer.isListening),
           !(await peer.hasActiveTransport) {
            await prepareForNewMacClientConnectionAsync()
        }
    }

    private func recycleStaleListenPeerIfNeeded() async {
        guard let peer = peerChannel, await peer.isListening else { return }
        if await peer.hasActiveTransport { return }
        LookinDiagLog.log("iOS stale listen peer (no transport) — recycle for re-listen")
        await peer.close()
        peerChannel = nil
        peerChannelUniqueID = nil
    }

    private func recycleStaleConnectedPeerIfNeededAsync(minIdle: TimeInterval) async {
        guard let peer = peerChannel, !(await peer.isListening), await peer.isConnected else { return }
        if await peer.hasActiveTransport {
            let idle = Date().timeIntervalSince1970 - lastPeerFrameAt
            if lastPeerFrameAt > 0, idle >= minIdle {
                LookinDiagLog.log("iOS recycle stale peer idle=\(String(format: "%.2f", idle))s — re-listen")
                await peer.cancel()
                peerChannel = nil
                peerChannelUniqueID = nil
                lastPeerFrameAt = 0
            }
            return
        }
        LookinDiagLog.log("iOS stale peer (connected, no transport) — closing for re-listen")
        await peer.close()
        peerChannel = nil
        peerChannelUniqueID = nil
    }

    private func recycleStaleConnectedPeerIfNeeded(minIdle: TimeInterval = 0.8) {
        Task { await recycleStaleConnectedPeerIfNeededAsync(minIdle: minIdle) }
    }

    private func prepareForNewMacClientConnectionAsync() async {
        await recycleStaleConnectedPeerIfNeededAsync(minIdle: 0)
        await searchPortToListenIfNoConnection()
    }

    private func checkPeertalkZombiePeer() {
        Task { await checkPeertalkZombiePeerAsync() }
    }

    private func checkPeertalkZombiePeerAsync() async {
        if let peer = peerChannel, await peer.isListening {
            if !(await peer.hasActiveTransport) {
                LookinDiagLog.log("iOS watchdog stale listen (no transport) — recycle")
                await peer.close()
                peerChannel = nil
                peerChannelUniqueID = nil
                await searchPortToListenIfNoConnection()
            }
            return
        }

        guard let peer = peerChannel else {
            if applicationIsActive || !isiOSAppOnMac() {
                await searchPortToListenIfNoConnection()
            }
            return
        }

        if !(await peer.isListening), !(await peer.isConnected) {
            LookinDiagLog.log("iOS watchdog dead peer — clear and re-listen")
            await peer.close()
            peerChannel = nil
            peerChannelUniqueID = nil
            lastPeerFrameAt = 0
            await searchPortToListenIfNoConnection()
            return
        }

        if await peer.isConnected {
            if !(await peer.isListening), !(await peer.hasActiveTransport) {
                LookinDiagLog.log("iOS watchdog connected zombie w/o transport — re-listen")
                await prepareForNewMacClientConnectionAsync()
                return
            }
            if !(await peer.hasActiveTransport) {
                LookinDiagLog.log("iOS watchdog connected peer w/o transport — re-listen")
                await prepareForNewMacClientConnectionAsync()
                return
            }
            let idle = Date().timeIntervalSince1970 - lastPeerFrameAt
            let idleThreshold: TimeInterval = isiOSAppOnMac()
                ? (applicationIsActive ? 5.0 : 0.8)
                : (applicationIsActive ? 30.0 : 0.8)
            if lastPeerFrameAt <= 0 || idle >= idleThreshold {
                LookinDiagLog.log(
                    "iOS watchdog stale connected idle=\(String(format: "%.1f", idle))s active=\(applicationIsActive) — re-listen"
                )
                await prepareForNewMacClientConnectionAsync()
            }
        }
    }

    private func handleWillResignActive() {
        Task { await handleWillResignActiveAsync() }
    }

    private func handleWillResignActiveAsync() async {
        if let channel = peerChannel {
            if await channel.isListening { return }
            if !(await channel.isConnected) {
                await channel.close()
                peerChannel = nil
                peerChannelUniqueID = nil
            }
        }
        ensurePeertalkListenAfterResigningActive()
    }

    private func ensurePeertalkListenAfterResigningActive() {
        #if targetEnvironment(simulator)
        return
        #else
        guard !isiOSAppOnMac() else { return }
        Task { await searchPortToListenIfNoConnection() }
        #endif
    }

    @objc private func _handleApplicationDidFinishLaunching() {
        LookinDiagLog.log("iOS didFinishLaunching — schedule Peertalk listen")
        Task { await searchPortToListenIfNoConnection() }
    }

    @objc private func _handleApplicationDidBecomeActive() {
        applicationIsActive = true
        LookinDiagLog.log("iOS didBecomeActive — ensure Peertalk listen")
        recycleStaleConnectedPeerIfNeeded(minIdle: 0.25)
        Task { await searchPortToListenIfNoConnection() }
    }

    @objc private func _handleWillResignActiveNotification() {
        applicationIsActive = false
        handleWillResignActive()
    }

    @objc private func _handleSceneDidActivate(_ note: Notification) {
        applicationIsActive = true
        LookinDiagLog.log("iOS scene didActivate — ensure Peertalk listen")
        recycleStaleConnectedPeerIfNeeded(minIdle: 0.25)
        Task { await searchPortToListenIfNoConnection() }
    }

    private func startMCPHTTPServerIfAvailable(port: UInt16) {
        let classNames = ["LKS_MCPHTTPServer", "LookinServer.MCPHTTPServer"]
        for className in classNames {
            guard let mcpClass = NSClassFromString(className) as AnyObject?,
                  mcpClass.responds(to: NSSelectorFromString("shared")) else {
                continue
            }
            let server = mcpClass.perform(NSSelectorFromString("shared"))?.takeUnretainedValue()
            guard let server, server.responds(to: NSSelectorFromString("startWithPort:")) else {
                continue
            }
            _ = server.perform(NSSelectorFromString("startWithPort:"), with: NSNumber(value: port))
            return
        }
        NSLog(
            "LookinServer - Swift MCP HTTP server unavailable (add LookinServer/MCP subspec; tried %@)",
            classNames.joined(separator: ", ")
        )
    }

    private func isiOSAppOnMac() -> Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        #if os(iOS)
        let info = ProcessInfo.processInfo
        return info.isiOSAppOnMac || info.isMacCatalystApp
        #else
        return false
        #endif
        #endif
    }

    @objc private func _handleLocalInspect(_ note: Notification) {
        let alertController = UIAlertController(
            title: "Lookin",
            message: "Failed to run local inspection. The feature has been removed. Please use the computer version of Lookin or consider SDKs like FLEX for similar functionality.",
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        guard let keyWindow = LKS_MultiplatformAdapter.keyWindow(),
              let rootViewController = keyWindow.rootViewController else {
            return
        }
        rootViewController.present(alertController, animated: true)
        NSLog("LookinServer - Failed to run local inspection. The feature has been removed. Please use the computer version of Lookin or consider SDKs like FLEX for similar functionality.")
    }

    @objc private func handleGetLookinInfo(_ note: Notification) {
        guard let userInfo = note.userInfo,
              let infoWrapper = userInfo["infos"] as? NSMutableDictionary else {
            if note.userInfo?["infos"] == nil {
                NSLog("LookinServer - GetLookinInfo failed. Params invalid.")
            }
            return
        }
        infoWrapper["lookinServerVersion"] = lookinServerReadableVersion
    }
}

/// Allows `NSClassFromString("Lookin")` to detect whether LookinServer is linked.
@objc(Lookin)
private final class Lookin: NSObject {}

#endif
