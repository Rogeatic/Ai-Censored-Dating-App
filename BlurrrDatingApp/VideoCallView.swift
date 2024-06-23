import SwiftUI
import WebKit

struct VideoCallView: UIViewControllerRepresentable {
    let roomID: String

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        let webView = WKWebView()

        let jitsiMeetURL = URL(string: "https://meet.jit.si/\(roomID)")!
        let request = URLRequest(url: jitsiMeetURL)

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
        VideoCallView(roomID: "testRoom")
    }
}
