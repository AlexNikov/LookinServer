#if canImport(LookinShared)
import LookinShared
#endif
#if SHOULD_COMPILE_LOOKIN_SERVER

import UIKit

extension UIViewController {
    @objc(lks_visibleViewController)
    public static func lks_visibleViewController() -> UIViewController? {
        guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController else {
            return nil
        }
        return rootViewController.lks_visibleViewControllerIfExist()
    }

    @objc(lks_visibleViewControllerIfExist)
    public func lks_visibleViewControllerIfExist() -> UIViewController? {
        if let presentedViewController {
            return presentedViewController.lks_visibleViewControllerIfExist()
        }

        if let navigationController = self as? UINavigationController {
            return navigationController.visibleViewController?.lks_visibleViewControllerIfExist()
        }

        if let tabBarController = self as? UITabBarController {
            return tabBarController.selectedViewController?.lks_visibleViewControllerIfExist()
        }

        if isViewLoaded, !view.isHidden, view.alpha > 0.01 {
            return self
        }
        return nil
    }
}

#endif
