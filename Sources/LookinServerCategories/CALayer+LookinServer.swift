#if canImport(LookinShared)
import LookinShared
#endif
#if SHOULD_COMPILE_LOOKIN_SERVER

import UIKit

extension CALayer {
    public var lks_hostView: UIView? {
        guard let delegate = delegate as? UIView, delegate.layer === self else { return nil }
        return delegate
    }

    public func lks_groupScreenshot(withLowQuality lowQuality: Bool) -> UIImage? {
        captureGroupScreenshot(lowQuality: lowQuality)
    }

    public func lks_soloScreenshot(withLowQuality lowQuality: Bool) -> UIImage? {
        guard !(sublayers?.isEmpty ?? true) else { return nil }
        return captureSoloScreenshot(lowQuality: lowQuality)
    }

    @objc(lks_relatedClassChainList)
    public func lks_relatedClassChainList() -> [[String]] {
        var array: [[String]] = []
        if let hostView = lks_hostView {
            array.append(Self.lks_getClassList(of: hostView, endingClass: "UIView"))
            if let viewController = hostView.lks_findHostViewController() {
                array.append(Self.lks_getClassList(of: viewController, endingClass: "UIViewController"))
            }
        } else {
            array.append(Self.lks_getClassList(of: self, endingClass: "CALayer"))
        }
        return array
    }

    public static func lks_getClassList(of object: Any, endingClass: String) -> [String] {
        guard let object = object as? NSObject else { return [] }
        var completedList = object.lks_classChainList()
        if let endingIdx = completedList.firstIndex(of: endingClass) {
            completedList = Array(completedList.prefix(through: endingIdx))
        }
        return completedList
    }

    @objc(lks_selfRelation)
    public func lks_selfRelation() -> [String]? {
        var array: [String] = []
        var ivarTraces: [LookinIvarTrace] = []

        if let hostView = lks_hostView {
            if let viewController = hostView.lks_findHostViewController() {
                array.append("(\(NSStringFromClass(type(of: viewController))) *).view")
                if let traces = viewController.lks_ivarTraces {
                    ivarTraces.append(contentsOf: traces)
                }
            }
            if let traces = hostView.lks_ivarTraces {
                ivarTraces.append(contentsOf: traces)
            }
        } else if let traces = lks_ivarTraces {
            ivarTraces.append(contentsOf: traces)
        }

        if !ivarTraces.isEmpty {
            let mapped = ivarTraces.compactMap { trace -> String? in
                guard let hostClassName = trace.hostClassName, let ivarName = trace.ivarName else { return nil }
                return "(\(hostClassName) *) -> \(ivarName)"
            }
            array.append(contentsOf: mapped)
        }

        return array.isEmpty ? nil : array
    }

    @objc var lks_backgroundColor: UIColor? {
        get { UIColor.lks_colorWithCGColor(backgroundColor) }
        set { backgroundColor = newValue?.cgColor }
    }

    @objc var lks_borderColor: UIColor? {
        get { UIColor.lks_colorWithCGColor(borderColor) }
        set { borderColor = newValue?.cgColor }
    }

    @objc var lks_shadowColor: UIColor? {
        get { UIColor.lks_colorWithCGColor(shadowColor) }
        set { shadowColor = newValue?.cgColor }
    }

    @objc var lks_shadowOffsetWidth: CGFloat {
        get { shadowOffset.width }
        set { shadowOffset = CGSize(width: newValue, height: shadowOffset.height) }
    }

    @objc var lks_shadowOffsetHeight: CGFloat {
        get { shadowOffset.height }
        set { shadowOffset = CGSize(width: shadowOffset.width, height: newValue) }
    }

    private func captureGroupScreenshot(lowQuality: Bool) -> UIImage? {
        guard let contextSize = validatedContextSize() else { return nil }
        let renderScale = screenshotRenderScale(for: contextSize, lowQuality: lowQuality)

        UIGraphicsBeginImageContextWithOptions(contextSize, false, renderScale)
        defer { UIGraphicsEndImageContext() }

        let captureRect = CGRect(origin: .zero, size: contextSize)
        if let hostView = lks_hostView, !hostView.lks_isChildrenViewOfTabBar {
            // drawHierarchy only works for views that are not clipped by a clipsToBounds ancestor
            // (e.g. UIScrollView cells outside the current contentOffset viewport return blank).
            // Fall back to CALayer.render for off-screen content.
            if hostView.lks_isVisibleInClipHierarchy {
                _ = hostView.drawHierarchy(in: captureRect, afterScreenUpdates: true)
            } else if let context = UIGraphicsGetCurrentContext() {
                render(in: context)
            }
        } else if let context = UIGraphicsGetCurrentContext() {
            render(in: context)
        }

        return UIGraphicsGetImageFromCurrentImageContext()
    }

    private func captureSoloScreenshot(lowQuality: Bool) -> UIImage? {
        guard let contextSize = validatedContextSize() else { return nil }
        let renderScale = screenshotRenderScale(for: contextSize, lowQuality: lowQuality)

        let hiddenSublayers = hideDirectVisibleSublayers()
        var hiddenSubviews: [UIView] = []
        if let hostView = lks_hostView, !hostView.lks_isChildrenViewOfTabBar {
            hiddenSubviews = hideDirectVisibleSubviews(of: hostView)
        }

        UIGraphicsBeginImageContextWithOptions(contextSize, false, renderScale)
        defer {
            UIGraphicsEndImageContext()
            restoreHiddenSublayers(hiddenSublayers)
            restoreHiddenSubviews(hiddenSubviews)
        }

        // Solo must not use drawHierarchy — it always composites the full view tree
        // (e.g. UIWindow would still show HorseLayer/DogLayer). Render this layer only.
        if let context = UIGraphicsGetCurrentContext() {
            render(in: context)
        }

        return UIGraphicsGetImageFromCurrentImageContext()
    }

    private func hideDirectVisibleSublayers() -> [CALayer] {
        guard let sublayers else { return [] }
        var visibleSublayers: [CALayer] = []
        for sublayer in sublayers where !sublayer.isHidden {
            sublayer.isHidden = true
            visibleSublayers.append(sublayer)
        }
        return visibleSublayers
    }

    private func restoreHiddenSublayers(_ sublayers: [CALayer]) {
        for sublayer in sublayers {
            sublayer.isHidden = false
        }
    }

    private func hideDirectVisibleSubviews(of view: UIView) -> [UIView] {
        var hidden: [UIView] = []
        for subview in view.subviews where !subview.isHidden {
            subview.isHidden = true
            hidden.append(subview)
        }
        return hidden
    }

    private func restoreHiddenSubviews(_ subviews: [UIView]) {
        for subview in subviews {
            subview.isHidden = false
        }
    }

    private func validatedContextSize() -> CGSize? {
        let screenScale = LKS_MultiplatformAdapter.mainScreenScale()
        let pixelWidth = frame.size.width * screenScale
        let pixelHeight = frame.size.height * screenScale
        guard pixelWidth > 0, pixelHeight > 0 else { return nil }

        let contextSize = frame.size
        guard contextSize.width > 0, contextSize.height > 0,
              contextSize.width <= 20000, contextSize.height <= 20000 else {
            NSLog(
                "LookinServer - Failed to capture screenshot. Invalid context size: %@ x %@",
                NSNumber(value: contextSize.width),
                NSNumber(value: contextSize.height)
            )
            return nil
        }
        return contextSize
    }

    private func screenshotRenderScale(for contextSize: CGSize, lowQuality: Bool) -> CGFloat {
        let screenScale = LKS_MultiplatformAdapter.mainScreenScale()
        var renderScale: CGFloat = lowQuality ? 1 : 0
        let pixelWidth = contextSize.width * screenScale
        let pixelHeight = contextSize.height * screenScale
        let maxLength = max(pixelWidth, pixelHeight)
        let maxImageLength: CGFloat = 16384
        if maxLength > maxImageLength {
            renderScale = min(screenScale * maxImageLength / maxLength, 1)
        }
        return renderScale
    }
}

#endif
