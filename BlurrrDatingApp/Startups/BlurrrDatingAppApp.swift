import SwiftUI
import UIKit
import GoogleSignIn
import NSFWDetector

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

        // Pre-warm NSFWDetector in background — loads CoreML model early
        // so there's no delay or black screen when the camera first appears
        DispatchQueue.global(qos: .background).async {
            _ = NSFWDetector.shared
        }

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
    @State private var isLoading = true

    var body: some Scene {
        WindowGroup {
            if isLoading {
                SplashView()
                    .onAppear {
                        let start = Date()

                        // 1. Pre-warm NSFW detector
                        // 2. Restore Google Sign-In session (loads profile image)
                        // 3. Enforce minimum 1.5s splash duration
                        DispatchQueue.global(qos: .background).async {
                            _ = NSFWDetector.shared

                            DispatchQueue.main.async {
                                GIDSignIn.sharedInstance.restorePreviousSignIn { _, _ in
                                    let elapsed = Date().timeIntervalSince(start)
                                    let remaining = max(0, 3.0 - elapsed)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + remaining) {
                                        withAnimation(.easeInOut(duration: 0.5)) {
                                            isLoading = false
                                        }
                                    }
                                }
                            }
                        }
                    }
            } else {
                ContentView(
                    signalingURL: signalingServerURL,
                    iceServers: iceServers
                )
                .transition(.opacity)
            }
        }
    }
}

// MARK: - Splash Screen

struct SplashView: View {
    @State private var iconScale: CGFloat = 0.85

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            // Large soft blobs — heavily blurred, atmospheric background
            BlobField(color: Color("appOrange").opacity(0.12), count: 4, spread: 200)
                .ignoresSafeArea()

            // Icon + spinner
            VStack(spacing: 24) {
                Image("Blurrr Icon transparent")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140, height: 140)
                    .scaleEffect(iconScale)
                    .shadow(color: Color("appOrange").opacity(0.6), radius: 24)
                    .animation(.spring(response: 0.6, dampingFraction: 0.55), value: iconScale)

                ProgressView()
                    .tint(Color("appOrange"))
                    .scaleEffect(1.2)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.55)) {
                iconScale = 1.05
            }
        }
    }
}
