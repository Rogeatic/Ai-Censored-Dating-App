import UIKit
import GoogleSignIn

class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Initialize Google Sign-In
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: "414114629933-jk8k57h27p80v8kvrofinkr0q6ppkiil.apps.googleusercontent.com")
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}
