import Foundation
#if canImport(UIKit)
import UIKit
#if canImport(LookinShared)
import LookinShared
#endif
#endif

#if os(iOS) || os(tvOS) || os(visionOS)
private typealias LKMultiplatformAdapter = LKS_MultiplatformAdapter

extension LKAppInfo {
    // Use millisecond precision to reduce collision probability when sim + device start in the same second.
    private static let cachedAppInfoIdentifier: Int = Int(Date().timeIntervalSince1970 * 1000) & Int(UInt32.max)

    @objc(currentInfoWithScreenshot:icon:localIdentifiers:)
    public class func currentInfo(
        withScreenshot hasScreenshot: Bool,
        icon hasIcon: Bool,
        localIdentifiers: [NSNumber]?
    ) -> LKAppInfo {
        let selfIdentifier = cachedAppInfoIdentifier
        if let localIdentifiers, localIdentifiers.contains(NSNumber(value: selfIdentifier)) {
            let info = LKAppInfo()
            info.appInfoIdentifier = UInt(selfIdentifier)
            info.shouldUseCache = true
            // Include deviceType so the Mac client can match the correct local cache entry.
            #if targetEnvironment(simulator)
            info.deviceType = .simulator
            #elseif os(iOS)
            if LKMultiplatformAdapter.isiPad() {
                info.deviceType = .iPad
            } else {
                info.deviceType = .others
            }
            #else
            info.deviceType = .others
            #endif
            return info
        }

        let info = LKAppInfo()
        info.serverReadableVersion = lookinServerReadableVersion
        info.swiftEnabledInLookinServer = 1
        info.appInfoIdentifier = UInt(selfIdentifier)
        info.appName = lookinAppName()
        info.deviceDescription = UIDevice.current.name
        info.appBundleIdentifier = Bundle.main.bundleIdentifier

        #if targetEnvironment(simulator)
        info.deviceType = .simulator
        #elseif os(iOS)
        if LKMultiplatformAdapter.isiPad() {
            info.deviceType = .iPad
        } else {
            info.deviceType = .others
        }
        #else
        info.deviceType = .others
        #endif

        info.osDescription = UIDevice.current.systemVersion
        let mainVersionStr = UIDevice.current.systemVersion.components(separatedBy: ".").first ?? "0"
        info.osMainVersion = UInt(mainVersionStr) ?? 0

        let screenSize = LKMultiplatformAdapter.mainScreenBounds().size
        info.screenWidth = Double(screenSize.width)
        info.screenHeight = Double(screenSize.height)
        info.screenScale = Double(LKMultiplatformAdapter.mainScreenScale())

        if hasScreenshot {
            info.screenshot = lookinScreenshotImage()
        }
        if hasIcon {
            info.appIcon = lookinAppIcon()
        }

        return info
    }

    private class func lookinAppName() -> String? {
        let bundleInfo = Bundle.main.infoDictionary
        let displayName = bundleInfo?["CFBundleDisplayName"] as? String
        let name = bundleInfo?["CFBundleName"] as? String
        if let displayName, !displayName.isEmpty {
            return displayName
        }
        return name
    }

    private class func lookinAppIcon() -> UIImage? {
        #if os(tvOS)
        return nil
        #else
        var imageName: String?
        if let bundleIcons = Bundle.main.infoDictionary?["CFBundleIcons"] {
            if let primaryIcon = (bundleIcons as? [String: Any])?["CFBundlePrimaryIcon"] {
                if let iconDict = primaryIcon as? [String: Any],
                   let iconFiles = iconDict["CFBundleIconFiles"] as? [String] {
                    imageName = iconFiles.last
                } else if let iconName = primaryIcon as? String {
                    imageName = iconName
                }
            }
        }
        guard let imageName, !imageName.isEmpty else { return nil }
        return UIImage(named: imageName)
        #endif
    }

    private class func lookinScreenshotImage() -> UIImage? {
        guard let window = LKMultiplatformAdapter.keyWindow() else { return nil }
        let size = window.bounds.size
        guard size.width > 0, size.height > 0 else { return nil }
        UIGraphicsBeginImageContextWithOptions(size, true, 0.4)
        window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

#endif
