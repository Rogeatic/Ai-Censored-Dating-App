import SwiftUI
import WebKit

struct VideoCallView: UIViewControllerRepresentable {
    let roomID: String
    let displayName: String
    let email: String
    let avatarURL: String
    let idToken: String

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        let webView = WKWebView()

        let jitsiMeetURL = URL(string: "https://meet.jit.si/\(roomID)")!
        var request = URLRequest(url: jitsiMeetURL)
        
        // Prepare user information to pass to Jitsi Meet
        let userInfo = [
            "displayName": displayName,
            "email": email,
            "avatarURL": avatarURL,
            "idToken": idToken
        ]
        
        // Convert userInfo to JSON string
        if let userInfoData = try? JSONSerialization.data(withJSONObject: userInfo, options: []),
           let userInfoString = String(data: userInfoData, encoding: .utf8) {
            let userScript = WKUserScript(source: "window.jitsiMeetExternalAPI = window.jitsiMeetExternalAPI || {}; window.jitsiMeetExternalAPI.userInfo = \(userInfoString);", injectionTime: .atDocumentEnd, forMainFrameOnly: true)
            webView.configuration.userContentController.addUserScript(userScript)
        }

        webView.load(request)
        viewController.view = webView

        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor),
            webView.topAnchor.constraint(equalTo: viewController.view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor)
        ])

        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    static var previews: some View {
        VideoCallView(roomID: "testRoom", displayName: "Test User", email: "test@example.com", avatarURL: "https://example.com/avatar.png", idToken: "testToken")
    }
}
