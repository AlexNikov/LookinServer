import UIKit
import LookinServer

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        _ = LookinServerEntry.self
        MainActor.assumeIsolated {
            _ = LKS_ConnectionManager.sharedInstance
        }
        return true
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        LKS_ConnectionManager.sharedInstance.prepareForNewMacClientConnection()
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}
