import UIKit
import JitsiMeetSDK

class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var pipViewCoordinator: PiPViewCoordinator?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Initialize JitsiMeetView
        let jitsiMeetView = JitsiMeetView()
        self.pipViewCoordinator = PiPViewCoordinator(withView: jitsiMeetView)
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        pipViewCoordinator?.enterPictureInPicture()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        pipViewCoordinator?.exitPictureInPicture()
    }
}
