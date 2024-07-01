import UIKit
import WebRTC

class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var webRTCManager = WebRTCManager()
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }
}
