//import SwiftUI
//import JitsiMeetSDK
//
//struct VideoCallView: UIViewControllerRepresentable {
//    let roomID: String
//
//    func makeUIViewController(context: Context) -> UIViewController {
//        let viewController = UIViewController()
//        let jitsiMeetView = JitsiMeetView()
//
//        // Configure JitsiMeetView
//        let options = JitsiMeetConferenceOptions.fromBuilder { builder in
//            builder.room = roomID
//            builder.serverURL = URL(string: "https://blurrr-dating.com") // Set your server URL
//            builder.setFeatureFlag("welcomepage.enabled", withBoolean: false) // Disable the welcome page
//            builder.setFeatureFlag("add-people.enabled", withBoolean: false) // Disable invite option
//            builder.setFeatureFlag("calendar.enabled", withBoolean: false) // Disable calendar option
//            builder.setFeatureFlag("call-integration.enabled", withBoolean: false) // Disable call integration
//            builder.setFeatureFlag("chat.enabled", withBoolean: false) // Disable chat
//            builder.setFeatureFlag("close-captions.enabled", withBoolean: false) // Disable close captions
//            builder.setFeatureFlag("live-streaming.enabled", withBoolean: false) // Disable live streaming
//            builder.setFeatureFlag("meeting-name.enabled", withBoolean: false) // Disable meeting name
//            builder.setFeatureFlag("meeting-password.enabled", withBoolean: false) // Disable meeting password
//            builder.setFeatureFlag("recording.enabled", withBoolean: false) // Disable recording
//            builder.setFeatureFlag("video-share.enabled", withBoolean: false) // Disable video share
//            builder.setFeatureFlag("pip.enabled", withBoolean: false) // Disable picture-in-picture
//            builder.setFeatureFlag("raise-hand.enabled", withBoolean: false) // Disable raise hand
//            builder.setFeatureFlag("tile-view.enabled", withBoolean: false) // Disable tile view
//            builder.userInfo = JitsiMeetUserInfo(displayName: "User", andEmail: "user@example.com", andAvatar: URL(string: "https://example.com/default-avatar.png"))
//        }
//
//        jitsiMeetView.join(options)
//        viewController.view = jitsiMeetView
//
//        return viewController
//    }
//
//    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
//
//    static func dismantleUIViewController(_ uiViewController: UIViewController, coordinator: ()) {
//        if let jitsiMeetView = uiViewController.view as? JitsiMeetView {
//            jitsiMeetView.leave()
//        }
//    }
//}
