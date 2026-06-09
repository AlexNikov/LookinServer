#if SHOULD_COMPILE_LOOKIN_SERVER

import Foundation
import UIKit

extension LKS_ConnectionManager {
    /// Detail responses use wire v2 JSON (attrs + LKPG screenshots).
    func respondWireV2(_ attachment: LKConnectionResponseAttachment, requestType: UInt32, tag: UInt32) {
        if let details = attachment.data as? [LookinDisplayItemDetail] {
            for item in details {
                let wireDetail = WireHierarchyMapper.wireDetail(from: item)
                let envelope = WireResponseEnvelope(
                    requestType: requestType,
                    tag: tag,
                    detail: wireDetail,
                    dataTotalCount: attachment.dataTotalCount > 0 ? attachment.dataTotalCount : nil,
                    currentDataCount: attachment.currentDataCount > 0 ? attachment.currentDataCount : nil
                )
                sendDetailAsync(item, envelope: envelope, tag: tag)
            }
            return
        }

        guard let envelope = WireRequestResponseMapper.responseEnvelope(
            from: attachment,
            requestType: requestType,
            tag: tag
        ) else {
            NSLog("LookinServer - wire v2 missing response mapper type:%u", requestType)
            let envelope = WireResponseEnvelope(
                requestType: requestType,
                tag: tag,
                error: WireErrorPayload(code: -1, message: "Unsupported wire v2 response")
            )
            sendWireJSONEnvelope(envelope, tag: tag)
            return
        }

        if let detail = attachment.data as? LookinDisplayItemDetail {
            sendDetailAsync(detail, envelope: envelope, tag: tag)
            return
        }
        sendWireJSONEnvelope(envelope, tag: tag)
    }

    // Encodes screenshots on a background thread to avoid blocking main, then sends on main.
    // Each item's screenshots are guaranteed to arrive before its JSON envelope.
    private func sendDetailAsync(
        _ detail: LookinDisplayItemDetail,
        envelope: WireResponseEnvelope,
        tag: UInt32
    ) {
        let solo = detail.soloScreenshot
        let group = detail.groupScreenshot
        let oid = detail.displayItemOid

        Task.detached(priority: .userInitiated) { [weak self] in
            let soloData = solo.flatMap { WireScreenshotImageCoding.pngData(from: $0) }
            let groupData = group.flatMap { WireScreenshotImageCoding.pngData(from: $0) }
            await MainActor.run { [weak self] in
                guard let self else { return }
                if let data = soloData { self.sendWireScreenshot(oid: oid, kind: .solo, imageData: data, tag: tag) }
                if let data = groupData { self.sendWireScreenshot(oid: oid, kind: .group, imageData: data, tag: tag) }
                self.sendWireJSONEnvelope(envelope, tag: tag, frameType: LookinWireFormat.frameTypeJSON)
            }
        }
    }

    func sendWireJSONEnvelope(
        _ envelope: WireResponseEnvelope,
        tag: UInt32,
        frameType: UInt32? = nil
    ) {
        do {
            let data = try LKWireCodecV2.encodeJSON(envelope)
            let frame = frameType ?? envelope.requestType
            _sendRawPayload(data, frameOfType: frame, tag: tag)
        } catch {
            NSLog("LookinServer - wire v2 JSON encode failed: %@", error as NSError)
        }
    }

    func sendWireScreenshot(oid: UInt, kind: WireScreenshotKind, imageData: Data, tag: UInt32) {
        let payload = LKWireCodecV2.makeScreenshotPayload(
            oid: oid,
            kind: kind,
            format: .png,
            imageData: imageData
        )
        _sendRawPayload(payload, frameOfType: LookinWireFormat.frameTypeScreenshot, tag: tag)
    }

    func handleWireJSONRequest(_ envelope: WireRequestEnvelope, tag: UInt32) {
        guard LookinWireFormat.validateWireVersion(envelope.wireVersion, context: "request") else {
            return
        }
        guard let object = WireRequestResponseMapper.requestObject(from: envelope) else {
            if envelope.requestType == UInt32(LookinRequestTypePing) {
                requestHandler.handleRequestType(envelope.requestType, tag: tag, object: nil)
            } else {
                LookinDiagLog.log(
                    "wire request decode FAIL type=\(envelope.requestType) tag=\(tag) inbuilt=\(envelope.inbuiltModification != nil)"
                )
                NSLog("LookinServer - wire request decode failed type:%u", envelope.requestType)
                var attachment = LKConnectionResponseAttachment()
                attachment.error = LookinConnectionErrors.inner as NSError
                LKS_ConnectionManager.sharedInstance.respond(attachment, requestType: envelope.requestType, tag: tag)
            }
            return
        }
        requestHandler.handleRequestType(envelope.requestType, tag: tag, object: object)
    }

    func handleWireJSONCommand(_ data: Data, tag: UInt32) {
        if let envelope = try? LKWireCodecV2.decodeJSON(WireRequestEnvelope.self, from: data) {
            handleWireJSONRequest(envelope, tag: tag)
            return
        }
        guard let command = try? LKWireCodecV2.decodeJSON(WireCommand.self, from: data),
              command.op == .screenshot else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            guard let layer = NSObject.lks_object(withOid: command.oid) as? CALayer else { return }
            let image: UIImage?
            switch command.kind {
            case .solo:
                image = layer.lks_soloScreenshot(withLowQuality: command.lowQuality)
            case .group:
                image = layer.lks_groupScreenshot(withLowQuality: command.lowQuality)
            }
            guard let image, let png = image.pngData() else { return }
            self.sendWireScreenshot(oid: command.oid, kind: command.kind, imageData: png, tag: tag)
        }
    }

    func _sendRawPayload(_ data: Data, frameOfType: UInt32, tag: UInt32) {
        sendRawPayload(data, frameOfType: frameOfType, tag: tag)
    }
}

#endif
