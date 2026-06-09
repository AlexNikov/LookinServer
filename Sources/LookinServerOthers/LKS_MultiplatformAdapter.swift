#if SHOULD_COMPILE_LOOKIN_SERVER

import UIKit

public final class LKS_MultiplatformAdapter: NSObject {

    private static var _isiPad: Bool = {
        UIDevice.current.model.hasPrefix("iPad")
    }()

    public static func isiPad() -> Bool {
        _isiPad
    }

    public static func mainScreenBounds() -> CGRect {
        #if os(visionOS)
        return getFirstActiveWindowScene()?.coordinateSpace.bounds ?? .zero
        #else
        return UIScreen.main.bounds
        #endif
    }

    public static func mainScreenScale() -> CGFloat {
        #if os(visionOS)
        return 2
        #else
        return UIScreen.main.scale
        #endif
    }

    #if os(visionOS)
    private static func getFirstActiveWindowScene() -> UIWindowScene? {
        for case let windowScene as UIWindowScene in UIApplication.shared.connectedScenes {
            if windowScene.activationState == .foregroundActive {
                return windowScene
            }
        }
        return nil
    }
    #endif

    public static func keyWindow() -> UIWindow? {
        #if os(visionOS)
        return getFirstActiveWindowScene()?.keyWindow
        #else
        return UIApplication.shared.keyWindow
        #endif
    }

    public static func allWindows() -> [UIWindow] {
        #if os(visionOS)
        var windows: [UIWindow] = []
        for case let windowScene as UIWindowScene in UIApplication.shared.connectedScenes {
            windows.append(contentsOf: windowScene.windows)
            if let keyWindow = windowScene.keyWindow,
               !windows.contains(keyWindow),
               !NSStringFromClass(type(of: keyWindow)).contains("HUD") {
                windows.append(keyWindow)
            }
        }
        return windows
        #else
        return UIApplication.shared.windows
        #endif
    }
}

#endif
