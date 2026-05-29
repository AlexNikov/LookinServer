#if SHOULD_COMPILE_LOOKIN_SERVER

import Darwin
import Foundation
import UIKit

private typealias LookinPTChannelDelegateProtocol = Lookin_PTChannelDelegate

public final class LKS_ConnectionManager: NSObject, LookinPTChannelDelegateProtocol {

    @objc public static let sharedInstance = LKS_ConnectionManager()

    /// Replaces ObjC `+load` — triggers singleton initialization when the module loads.
    public static let bootstrap: Void = {
        _ = sharedInstance
        return ()
    }()

    @objc public var applicationIsActive = false

    /// Strong ref keeps listen/connected Peertalk channels alive (delegate is weak on the channel side).
    var peerChannel_: LookinPTChannel?
    let requestHandler = LKS_RequestHandler()
    /// Last inbound Peertalk activity on the connected peer (Mac client quit detection).
    private var lastPeerFrameAt: TimeInterval = 0
    private var peertalkWatchdogTimer: DispatchSourceTimer?

    private override init() {
        super.init()
        NSLog("LookinServer - Will launch. Framework version: %@", lookinServerReadableVersion)

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

        startMCPHTTPServerIfAvailable(port: 47190)
        startPeertalkWatchdog()
    }

    deinit {
        peertalkWatchdogTimer?.cancel()
        peerChannel_?.close()
        NotificationCenter.default.removeObserver(self)
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

    @objc(respond:requestType:tag:)
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
            _sendRawPayload(jsonData, frameOfType: type, tag: 0)
        } catch {
            NSLog("LookinServer - wire v2 push JSON encode failed type:%u: %@", type, error as NSError)
        }
    }

    /// Peertalk listen port when `peerChannel_` is listening; 0 when connected or idle.
    @objc public func mcpPeertalkListenPort() -> Int {
        guard let peer = peerChannel_, peer.isListening else { return 0 }
        return peer.targetPort
    }

    @objc public func mcpPeertalkIsConnected() -> Bool {
        peerChannel_?.isConnected == true
    }

    /// Launch-screen discovery: mac Lookin may scan while a zombie Peertalk peer still blocks re-listen.
    @objc public func nudgePeertalkListenForLaunchScreenDiscoveryIfNeeded() {
        guard let peer = peerChannel_ else {
            searchPortToListenIfNoConnection()
            return
        }
        if peer.isListening {
            if peer.hasActiveTransport {
                return
            }
            LookinDiagLog.log("iOS nudge stale listen peer — recycle")
            let stale = peer
            peerChannel_ = nil
            stale.close()
            searchPortToListenIfNoConnection()
            return
        }
        if peer.isConnected {
            let idle = Date().timeIntervalSince1970 - lastPeerFrameAt
            if lastPeerFrameAt <= 0 || idle >= 0.8 {
                LookinDiagLog.log(
                    "iOS nudge Peertalk re-listen (connected idle=\(String(format: "%.1f", idle))s)"
                )
                prepareForNewMacClientConnection()
            }
            return
        }
        searchPortToListenIfNoConnection()
    }

    @objc public func searchPortToListenIfNoConnection() {
        // Mac quit / USB drop can leave a dead channel (not listening, not connected) that blocks re-listen.
        if let peer = peerChannel_, !peer.isListening, !peer.isConnected {
            LookinDiagLog.log("iOS clear dead Peertalk peer — re-listen")
            let stale = peer
            peerChannel_ = nil
            lastPeerFrameAt = 0
            stale.close()
        }
        // USB device: connected zombie (no live transport) after Mac client quit — not a normal connected session.
        if !isiOSAppOnMac(),
           let peer = peerChannel_, peer.isConnected, mcpPeertalkListenPort() == 0, !peer.hasActiveTransport {
            prepareForNewMacClientConnection()
        }
        recycleStaleConnectedPeerIfNeeded()
        if let peer = peerChannel_, peer.isListening {
            if peer.hasActiveTransport {
                return
            }
            LookinDiagLog.log("iOS stale listen peer (no transport) — recycle for re-listen")
            let stale = peer
            peerChannel_ = nil
            stale.close()
        }
        if let peer = peerChannel_, peer.isConnected {
            if peer.hasActiveTransport {
                let idle = Date().timeIntervalSince1970 - lastPeerFrameAt
                // killall Lookin / crash often leaves a connected peer with no live Mac client.
                if lastPeerFrameAt > 0, idle < 0.25 {
                    NSLog("LookinServer - Abort to search ports. Already has connected channel.")
                    return
                }
                LookinDiagLog.log(
                    "iOS zombie peer (connected, idle=\(String(format: "%.1f", idle))s) — recycle for re-listen"
                )
                let stale = peer
                peerChannel_ = nil
                lastPeerFrameAt = 0
                stale.cancel()
            } else {
                // Mac client died without a clean Peertalk teardown — do not block re-listen.
                LookinDiagLog.log("iOS stale peer (connected, no transport) — closing for re-listen")
                peer.close()
                peerChannel_ = nil
            }
        }
        NSLog("LookinServer - Searching port to listen...")
        peerChannel_?.close()
        peerChannel_ = nil

        if isiOSAppOnMac() {
            _tryToListenOnPort(
                from: Int32(LookinSimulatorIPv4PortNumberStart),
                to: Int32(LookinSimulatorIPv4PortNumberEnd),
                current: Int32(LookinSimulatorIPv4PortNumberStart)
            )
        } else {
            _tryToListenOnPort(
                from: Int32(LookinUSBDeviceIPv4PortNumberStart),
                to: Int32(LookinUSBDeviceIPv4PortNumberEnd),
                current: Int32(LookinUSBDeviceIPv4PortNumberStart)
            )
        }
    }

    // MARK: - Lookin_PTChannelDelegate

    @objc public func ioFrameChannel(
        _ channel: LookinPTChannel,
        didReceiveFrameOfType type: UInt32,
        tag: UInt32,
        payload: LookinPTData?
    ) {
        if channel === peerChannel_ {
            lastPeerFrameAt = Date().timeIntervalSince1970
        }
        let payloadSize = payload?.length ?? 0
        guard let payload else {
            NSLog("LookinServer - didReceive frame type:%u tag:%u empty payload", type, tag)
            return
        }
        let data = payload.lookinPayloadBytes()
        if type == LookinWireFormat.frameTypeJSON {
            handleWireJSONCommand(data, tag: tag)
            return
        }
        do {
            let envelope = try LKWireCodecV2.decodeJSON(WireRequestEnvelope.self, from: data)
            handleWireJSONRequest(envelope, tag: tag)
            return
        } catch {
            if data.first == UInt8(ascii: "{") {
                NSLog(
                    "LookinServer - wire request JSON decode failed type:%u tag:%u bytes:%zu error:%@ preview:%@",
                    type,
                    tag,
                    data.count,
                    error as NSError,
                    String(data: data.prefix(120), encoding: .utf8) ?? ""
                )
            }
        }
        if LookinWirePushTypes.all.contains(type),
           let push = try? LKWireCodecV2.decodeJSON(WirePushEnvelope.self, from: data) {
            guard LookinWireFormat.validateWireVersion(push.wireVersion, context: "push") else {
                return
            }
            requestHandler.handleRequestType(push.pushType, tag: tag, object: nil)
            return
        }
        NSLog(
            "LookinServer - expected JSON request/push, got type:%u tag:%u payload:%zu",
            type,
            tag,
            payloadSize
        )
    }

    @objc public func ioFrameChannel(
        _ channel: LookinPTChannel,
        shouldAcceptFrameOfType type: UInt32,
        tag: UInt32,
        payloadSize: UInt32
    ) -> Bool {
        if channel !== peerChannel_ {
            return false
        }
        if type == LookinWireFormat.frameTypeJSON || type == LookinWireFormat.frameTypeScreenshot {
            return true
        }
        if requestHandler.canHandleRequestType(type) {
            return true
        }
        channel.close()
        return false
    }

    @objc public func ioFrameChannel(_ channel: LookinPTChannel, didEndWithError error: NSError?) {
        if peerChannel_ !== channel {
            NSLog("LookinServer - Ignore channel%@ end.", channel.debugTag())
            if peerChannel_ == nil {
                searchPortToListenIfNoConnection()
            }
            return
        }
        NSLog("LookinServer - channel%@ DidEndWithError:%@", channel.debugTag(), String(describing: error))

        NotificationCenter.default.post(
            name: NSNotification.Name(rawValue: LKS_ConnectionDidEndNotificationName as String),
            object: self
        )
        // Drop peer before re-listen — searchPort aborts when peerChannel_.isConnected is still true.
        peerChannel_ = nil
        lastPeerFrameAt = 0
        channel.close()
        searchPortToListenIfNoConnection()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.searchPortToListenIfNoConnection()
        }
    }

    @objc public func ioFrameChannel(
        _ channel: LookinPTChannel,
        didAcceptConnection otherChannel: LookinPTChannel,
        fromAddress address: LookinPTAddress
    ) {
        NSLog("LookinServer - channel:%@, acceptConnection:%@", channel.debugTag(), otherChannel.debugTag())

        let previousChannel = peerChannel_
        otherChannel.targetPort = address.port
        peerChannel_ = otherChannel
        lastPeerFrameAt = Date().timeIntervalSince1970
        previousChannel?.cancel()
    }

    // MARK: - Private

    /// Drop a connected-only peer so a new Mac Lookin client can attach (demo keeps running).
    @objc public func prepareForNewMacClientConnection() {
        recycleStaleConnectedPeerIfNeeded(minIdle: 0)
        searchPortToListenIfNoConnection()
    }

    /// Mac Lookin quit without Peertalk teardown leaves a connected zombie — relisten for the next client.
    private func startPeertalkWatchdog() {
        guard peertalkWatchdogTimer == nil else { return }
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + 1, repeating: 1.0)
        timer.setEventHandler { [weak self] in
            self?.checkPeertalkZombiePeer()
        }
        timer.resume()
        peertalkWatchdogTimer = timer
    }

    private func checkPeertalkZombiePeer() {
        if let peer = peerChannel_, peer.isListening {
            if !peer.hasActiveTransport {
                LookinDiagLog.log("iOS watchdog stale listen (no transport) — recycle")
                let stale = peer
                peerChannel_ = nil
                stale.close()
                searchPortToListenIfNoConnection()
            }
            return
        }

        guard let peer = peerChannel_ else {
            // Physical device must keep USB listen even when the app is backgrounded (Mac Lookin has focus).
            if applicationIsActive || !isiOSAppOnMac() {
                searchPortToListenIfNoConnection()
            }
            return
        }

        if !peer.isListening, !peer.isConnected {
            LookinDiagLog.log("iOS watchdog dead peer — clear and re-listen")
            let stale = peer
            peerChannel_ = nil
            lastPeerFrameAt = 0
            stale.close()
            searchPortToListenIfNoConnection()
            return
        }

        if peer.isConnected {
            if mcpPeertalkListenPort() == 0, !peer.hasActiveTransport {
                LookinDiagLog.log("iOS watchdog connected zombie w/o transport — re-listen")
                prepareForNewMacClientConnection()
                return
            }
            if !peer.hasActiveTransport {
                LookinDiagLog.log("iOS watchdog connected peer w/o transport — re-listen")
                prepareForNewMacClientConnection()
                return
            }
            let idle = Date().timeIntervalSince1970 - lastPeerFrameAt
            // Keep live inspector sessions during Mac UI idle after load; short idle only when
            // the iOS app is backgrounded (Mac Lookin has focus, no wire traffic expected).
            // USB device: Mac Lookin quit (killall) leaves a zombie peer — recycle quickly.
            // Real device bulk HierarchyDetails can take >0.8 s with no Mac→iOS frames after
            // the initial request; use a long threshold while the app is active so the channel
            // is not torn down mid-inspection. The !peer.hasActiveTransport checks above handle
            // fast Mac-quit detection independently of this idle guard.
            let idleThreshold: TimeInterval = isiOSAppOnMac()
                ? (applicationIsActive ? 5.0 : 0.8)
                : (applicationIsActive ? 30.0 : 0.8)
            if lastPeerFrameAt <= 0 || idle >= idleThreshold {
                LookinDiagLog.log(
                    "iOS watchdog stale connected idle=\(String(format: "%.1f", idle))s active=\(applicationIsActive) — re-listen"
                )
                prepareForNewMacClientConnection()
            }
        }
    }

    /// After the Mac client quits, the connected peer can block re-listen until iOS becomes active again.
    private func recycleStaleConnectedPeerIfNeeded(minIdle: TimeInterval = 0.8) {
        guard let peer = peerChannel_, peer.isListening == false, peer.isConnected else { return }
        if minIdle > 0 {
            let idle = Date().timeIntervalSince1970 - lastPeerFrameAt
            guard lastPeerFrameAt > 0, idle >= minIdle else { return }
            LookinDiagLog.log("iOS recycle stale peer idle=\(String(format: "%.2f", idle))s — re-listen")
        } else {
            LookinDiagLog.log("iOS recycle connected peer — re-listen for new Mac client")
        }
        let stale = peer
        peerChannel_ = nil
        lastPeerFrameAt = 0
        stale.cancel()
    }

    @objc private func _handleWillResignActiveNotification() {
        applicationIsActive = false
        if let channel = peerChannel_ {
            // While listening, isConnected is false — do not close or discovery breaks when
            // the Mac Lookin app (or verify scripts) takes focus away from the Simulator.
            if channel.isListening {
                return
            }
            if !channel.isConnected {
                channel.close()
                peerChannel_ = nil
            }
        }
        // Physical device: user switches to Mac Lookin — keep (or restart) USB Peertalk listen.
        ensurePeertalkListenAfterResigningActive()
    }

    /// On a USB-connected iPhone/iPad, Mac Lookin discovery runs while the iOS app is backgrounded.
    private func ensurePeertalkListenAfterResigningActive() {
        #if targetEnvironment(simulator)
        return
        #else
        guard !isiOSAppOnMac() else { return }
        DispatchQueue.main.async { [weak self] in
            self?.searchPortToListenIfNoConnection()
        }
        #endif
    }

    @objc private func _handleApplicationDidFinishLaunching() {
        // Start Peertalk listen early — mac Lookin may scan before the first didBecomeActive.
        LookinDiagLog.log("iOS didFinishLaunching — schedule Peertalk listen")
        DispatchQueue.main.async { [weak self] in
            self?.searchPortToListenIfNoConnection()
        }
    }

    @objc private func _handleApplicationDidBecomeActive() {
        applicationIsActive = true
        LookinDiagLog.log("iOS didBecomeActive — ensure Peertalk listen")
        recycleStaleConnectedPeerIfNeeded(minIdle: 0.25)
        searchPortToListenIfNoConnection()
    }

    @objc private func _handleSceneDidActivate(_ note: Notification) {
        applicationIsActive = true
        LookinDiagLog.log("iOS scene didActivate — ensure Peertalk listen")
        recycleStaleConnectedPeerIfNeeded(minIdle: 0.25)
        searchPortToListenIfNoConnection()
    }

    private func _tryToListenOnPort(from fromPort: Int32, to toPort: Int32, current currentPort: Int32) {
        let channel = LookinPTChannel.channel(withDelegate: self)
        channel.targetPort = Int(currentPort)
        channel.listen(onPort: UInt16(currentPort), ipv4Address: in_addr_t(INADDR_LOOPBACK)) { [weak self] (error: NSError?) in
            guard let self else { return }
            if let error {
                if currentPort < toPort {
                    NSLog("LookinServer - 127.0.0.1:%d is unavailable(%@). Will try anothor address ...", currentPort, error)
                    LookinDiagLog.log("Peertalk listen skip port=\(currentPort) errno=\((error as NSError).code)")
                    self._tryToListenOnPort(from: fromPort, to: toPort, current: currentPort + 1)
                } else {
                    NSLog("LookinServer - 127.0.0.1:%d is unavailable(%@).", currentPort, error)
                    NSLog(
                        "LookinServer - Peertalk listen FAILED on all ports %d-%d (errno in log above). Rebuild iOS app after pod install.",
                        fromPort,
                        toPort
                    )
                }
            } else {
                NSLog("LookinServer - Connected successfully on 127.0.0.1:%d", currentPort)
                LookinDiagLog.log("Peertalk listen OK port=\(currentPort)")
                self.peerChannel_ = channel
            }
        }
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
