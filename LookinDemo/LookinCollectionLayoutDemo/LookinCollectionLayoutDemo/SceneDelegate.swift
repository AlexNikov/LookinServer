import UIKit
import LookinServer

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = LKCollectionLayoutDemoViewController()
        window.makeKeyAndVisible()
        self.window = window
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // UIScene lifecycle: recycle zombie/dead peers (incl. after Mac Lookin quit) and ensure USB listen.
        let conn = LKS_ConnectionManager.sharedInstance
        conn.prepareForNewMacClientConnection()
        conn.nudgePeertalkListenForLaunchScreenDiscoveryIfNeeded()
    }
}
