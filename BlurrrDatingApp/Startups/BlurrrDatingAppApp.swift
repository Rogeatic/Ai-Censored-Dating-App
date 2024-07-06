import SwiftUI

@main
struct BlurrrDatingAppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView(signalingHandler: appDelegate.signalClient,
                        webRTCHandler: appDelegate.webRTCHandler)
                .navigationViewStyle(StackNavigationViewStyle())
        }
    }
}
