import Foundation
#if os(iOS) || os(tvOS) || os(visionOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

private enum WireHierarchyObjectMapping {
    static func wireRef(_ object: LookinObject?) -> WireObjectRef? {
        guard let object, object.oid != 0 else { return nil }
        return WireObjectRef(
            oid: object.oid,
            classChainList: object.classChainList,
            memoryAddress: object.memoryAddress,
            specialTrace: object.specialTrace,
            ivarTraces: object.ivarTraces?.map(wireIvarTrace(from:))
        )
    }

    static func lookinObject(from ref: WireObjectRef) -> LookinObject {
        let object = LookinObject()
        object.oid = ref.oid
        object.classChainList = ref.classChainList
        object.memoryAddress = ref.memoryAddress
        object.specialTrace = ref.specialTrace
        object.ivarTraces = ref.ivarTraces?.map(lookinIvarTrace(from:))
        return object
    }

    static func wireIvarTrace(from trace: LookinIvarTrace) -> WireIvarTrace {
        WireIvarTrace(
            relation: trace.relation,
            hostClassName: trace.hostClassName,
            ivarName: trace.ivarName
        )
    }

    static func lookinIvarTrace(from wire: WireIvarTrace) -> LookinIvarTrace {
        var trace = LookinIvarTrace()
        trace.relation = wire.relation
        trace.hostClassName = wire.hostClassName
        trace.ivarName = wire.ivarName
        return trace
    }

    static func wireBackgroundColorRGBA(from color: LookinColor?) -> [Double]? {
        guard let color else { return nil }
        let rgba = color.lookin_rgbaComponents
        guard rgba.count >= 4 else { return nil }
        return rgba.map(\.doubleValue)
    }

    static func lookinBackgroundColor(from rgba: [Double]?) -> LookinColor? {
        guard let rgba, rgba.count >= 4 else { return nil }
        return LookinColor.lookin_color(fromRGBAComponents: rgba.map { NSNumber(value: $0) })
    }
}

#if os(iOS) || os(tvOS) || os(visionOS)
import UIKit

public enum WireHierarchyMapper {
    public static func wirePayload(from info: LookinHierarchyInfo) -> WireHierarchyPayload {
        WireHierarchyPayload(
            serverVersion: info.serverVersion,
            displayItems: (info.displayItems ?? []).map { wireItem(from: $0) },
            collapsedClassList: info.collapsedClassList,
            appInfo: info.appInfo.map { WireRequestResponseMapper.wireAppInfo(from: $0) }
        )
    }

    public static func lookinHierarchy(from payload: WireHierarchyPayload) -> LookinHierarchyInfo {
        let info = LookinHierarchyInfo()
        info.serverVersion = payload.serverVersion
        info.displayItems = payload.displayItems.map { lookinItem(from: $0) }
        info.collapsedClassList = payload.collapsedClassList
        if let wireApp = payload.appInfo {
            info.appInfo = WireRequestResponseMapper.lookinAppInfo(from: wireApp)
        }
        return info
    }

    public static func wireItem(from item: LookinDisplayItem) -> WireDisplayItem {
        let oid = item.layerObject?.oid ?? item.viewObject?.oid ?? 0
        let wireCustomInfo: WireCustomDisplayItemInfo?
        if let customInfo = item.customInfo {
            let frameRect: Rect? = customInfo.frameInWindow.map { Rect($0) }
            wireCustomInfo = WireCustomDisplayItemInfo(
                frameInWindow: frameRect,
                title: customInfo.title,
                subtitle: customInfo.subtitle,
                danceuiSource: customInfo.danceuiSource
            )
        } else {
            wireCustomInfo = nil
        }
        return WireDisplayItem(
            oid: oid,
            frame: Rect(item.frame),
            bounds: Rect(item.bounds),
            isHidden: item.isHidden,
            alpha: item.alpha,
            shouldCaptureImage: item.shouldCaptureImage,
            customDisplayTitle: item.customDisplayTitle,
            representedAsKeyWindow: item.representedAsKeyWindow ? true : nil,
            layerRef: WireHierarchyObjectMapping.wireRef(item.layerObject),
            viewRef: WireHierarchyObjectMapping.wireRef(item.viewObject),
            hostViewControllerRef: WireHierarchyObjectMapping.wireRef(item.hostViewControllerObject),
            customInfo: wireCustomInfo,
            customAttrGroupList: item.customAttrGroupList?.map { WireAttributeMapper.wireGroup(from: $0) },
            backgroundColorRGBA: WireHierarchyObjectMapping.wireBackgroundColorRGBA(from: item.backgroundColor),
            subitems: item.subitems?.map { wireItem(from: $0) }
        )
    }

    public static func lookinItem(from wire: WireDisplayItem) -> LookinDisplayItem {
        let item = LookinDisplayItem()
        item.frame = wire.frame.cgRect
        item.bounds = wire.bounds.cgRect
        item.isHidden = wire.isHidden
        item.alpha = wire.alpha
        item.shouldCaptureImage = wire.shouldCaptureImage
        item.customDisplayTitle = wire.customDisplayTitle
        item.backgroundColor = WireHierarchyObjectMapping.lookinBackgroundColor(from: wire.backgroundColorRGBA)
        if wire.representedAsKeyWindow == true {
            item.representedAsKeyWindow = true
        }
        if let layerRef = wire.layerRef {
            item.layerObject = WireHierarchyObjectMapping.lookinObject(from: layerRef)
        }
        if let viewRef = wire.viewRef {
            item.viewObject = WireHierarchyObjectMapping.lookinObject(from: viewRef)
        }
        if let hostVCRef = wire.hostViewControllerRef {
            item.hostViewControllerObject = WireHierarchyObjectMapping.lookinObject(from: hostVCRef)
        }
        if let wireInfo = wire.customInfo {
            var info = LookinCustomDisplayItemInfo()
            info.frameInWindow = wireInfo.frameInWindow?.cgRect
            info.title = wireInfo.title
            info.subtitle = wireInfo.subtitle
            info.danceuiSource = wireInfo.danceuiSource
            item.customInfo = info
        }
        if let groups = wire.customAttrGroupList {
            item.customAttrGroupList = groups.map { WireAttributeMapper.lookinGroup(from: $0) }
        }
        item.subitems = wire.subitems?.map { lookinItem(from: $0) }
        return item
    }

    public static func wireDetail(from detail: LookinDisplayItemDetail) -> WireDisplayItemDetailPayload {
        WireDetailMapper.wireDetail(from: detail)
    }

    public static func lookinDetail(from payload: WireDisplayItemDetailPayload) -> LookinDisplayItemDetail {
        WireDetailMapper.lookinDetail(from: payload)
    }

    public static func applyWireDetail(_ payload: WireDisplayItemDetailPayload, to item: LookinDisplayItem) {
        if let frame = payload.frame {
            item.frame = frame.cgRect
        }
        if let bounds = payload.bounds {
            item.bounds = bounds.cgRect
        }
        if let hidden = payload.isHidden {
            item.isHidden = hidden
        }
        if let alpha = payload.alpha {
            item.alpha = alpha
        }
        if let subitems = payload.subitems {
            item.subitems = subitems.map { lookinItem(from: $0) }
        }
    }
}

#endif

#if os(macOS)

public enum WireHierarchyMapper {
    public static func wirePayload(from info: LookinHierarchyInfo) -> WireHierarchyPayload {
        WireHierarchyPayload(
            serverVersion: info.serverVersion,
            displayItems: (info.displayItems ?? []).map { wireItem(from: $0) },
            collapsedClassList: info.collapsedClassList,
            appInfo: info.appInfo.map { WireRequestResponseMapper.wireAppInfo(from: $0) }
        )
    }

    public static func lookinHierarchy(from payload: WireHierarchyPayload) -> LookinHierarchyInfo {
        let info = LookinHierarchyInfo()
        info.serverVersion = payload.serverVersion
        info.displayItems = payload.displayItems.map { lookinItem(from: $0) }
        info.collapsedClassList = payload.collapsedClassList
        if let wireApp = payload.appInfo {
            info.appInfo = WireRequestResponseMapper.lookinAppInfo(from: wireApp)
        }
        return info
    }

    public static func wireItem(from item: LookinDisplayItem) -> WireDisplayItem {
        let oid = item.layerObject?.oid ?? item.viewObject?.oid ?? 0
        let wireCustomInfo: WireCustomDisplayItemInfo?
        if let customInfo = item.customInfo {
            let frameRect: Rect? = customInfo.frameInWindow.map { Rect($0) }
            wireCustomInfo = WireCustomDisplayItemInfo(
                frameInWindow: frameRect,
                title: customInfo.title,
                subtitle: customInfo.subtitle,
                danceuiSource: customInfo.danceuiSource
            )
        } else {
            wireCustomInfo = nil
        }
        return WireDisplayItem(
            oid: oid,
            frame: Rect(item.frame),
            bounds: Rect(item.bounds),
            isHidden: item.isHidden,
            alpha: item.alpha,
            shouldCaptureImage: item.shouldCaptureImage,
            customDisplayTitle: item.customDisplayTitle,
            representedAsKeyWindow: item.representedAsKeyWindow ? true : nil,
            layerRef: WireHierarchyObjectMapping.wireRef(item.layerObject),
            viewRef: WireHierarchyObjectMapping.wireRef(item.viewObject),
            hostViewControllerRef: WireHierarchyObjectMapping.wireRef(item.hostViewControllerObject),
            customInfo: wireCustomInfo,
            customAttrGroupList: item.customAttrGroupList?.map { WireAttributeMapper.wireGroup(from: $0) },
            backgroundColorRGBA: WireHierarchyObjectMapping.wireBackgroundColorRGBA(from: item.backgroundColor),
            subitems: item.subitems?.map { wireItem(from: $0) }
        )
    }

    public static func lookinItem(from wire: WireDisplayItem) -> LookinDisplayItem {
        let item = LookinDisplayItem()
        item.frame = wire.frame.cgRect
        item.bounds = wire.bounds.cgRect
        item.isHidden = wire.isHidden
        item.alpha = wire.alpha
        item.shouldCaptureImage = wire.shouldCaptureImage
        item.customDisplayTitle = wire.customDisplayTitle
        item.backgroundColor = WireHierarchyObjectMapping.lookinBackgroundColor(from: wire.backgroundColorRGBA)
        if wire.representedAsKeyWindow == true {
            item.representedAsKeyWindow = true
        }
        if let layerRef = wire.layerRef {
            item.layerObject = WireHierarchyObjectMapping.lookinObject(from: layerRef)
        }
        if let viewRef = wire.viewRef {
            item.viewObject = WireHierarchyObjectMapping.lookinObject(from: viewRef)
        }
        if let hostVCRef = wire.hostViewControllerRef {
            item.hostViewControllerObject = WireHierarchyObjectMapping.lookinObject(from: hostVCRef)
        }
        if let wireInfo = wire.customInfo {
            var info = LookinCustomDisplayItemInfo()
            info.frameInWindow = wireInfo.frameInWindow?.cgRect
            info.title = wireInfo.title
            info.subtitle = wireInfo.subtitle
            info.danceuiSource = wireInfo.danceuiSource
            item.customInfo = info
        }
        if let groups = wire.customAttrGroupList {
            item.customAttrGroupList = groups.map { WireAttributeMapper.lookinGroup(from: $0) }
        }
        item.subitems = wire.subitems?.map { lookinItem(from: $0) }
        return item
    }

    public static func wireDetail(from detail: LookinDisplayItemDetail) -> WireDisplayItemDetailPayload {
        WireDetailMapper.wireDetail(from: detail)
    }

    public static func lookinDetail(from payload: WireDisplayItemDetailPayload) -> LookinDisplayItemDetail {
        WireDetailMapper.lookinDetail(from: payload)
    }

    public static func applyWireDetail(_ payload: WireDisplayItemDetailPayload, to item: LookinDisplayItem) {
        if let frame = payload.frame {
            item.frame = frame.cgRect
        }
        if let bounds = payload.bounds {
            item.bounds = bounds.cgRect
        }
        if let hidden = payload.isHidden {
            item.isHidden = hidden
        }
        if let alpha = payload.alpha {
            item.alpha = alpha
        }
        if let subitems = payload.subitems {
            item.subitems = subitems.map { lookinItem(from: $0) }
        }
    }
}

#endif
