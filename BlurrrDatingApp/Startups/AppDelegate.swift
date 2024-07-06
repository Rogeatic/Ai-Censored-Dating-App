import UIKit
import GoogleSignIn

//@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var IceServers = ["stun:stun.l.google.com:19302",
                     "stun:stun1.l.google.com:19302",
                     "stun:stun2.l.google.com:19302",
                     "stun:stun3.l.google.com:19302",
                     "stun:stun4.l.google.com:19302"]
    
    internal var window: UIWindow?
    var signalClient: SignalingHandler!
    var webRTCHandler: WebRTCHandler!
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Initialize WebRTCHandler with ICE servers
        webRTCHandler = WebRTCHandler(iceServers: IceServers)
        
        // Initialize SignalingHandler with WebSocket URL
        signalClient = SignalingHandler(webSocket: StarscreamWebSocket(url: URL(string: "ws://143.198.98.38:8080")!))
        
        // Initialize Google Sign-In
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: "414114629933-jk8k57h27p80v8kvrofinkr0q6ppkiil.apps.googleusercontent.com")
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}
