import SwiftUI
import UIKit
import GoogleSignIn

// MARK: - Constants

private let iceServers = [
    "stun:stun.l.google.com:19302",
    "stun:stun1.l.google.com:19302",
    "stun:stun2.l.google.com:19302"
]

private let signalingServerURL = URL(string: "ws://143.198.98.38:8080")!
private let googleClientID = "414114629933-jk8k57h27p80v8kvrofinkr0q6ppkiil.apps.googleusercontent.com"

// MARK: - AppDelegate

class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: googleClientID)
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}

// MARK: - App

@main
struct BlurrrApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            // Pass a factory closure instead of a single shared instance.
            // VideoView calls makeWebRTCHandler() each time it appears,
            // so reconnecting always gets a fresh PeerConnection.
            ContentView(
                signalingURL: signalingServerURL,
                iceServers: iceServers
            )
        }
    }
}
