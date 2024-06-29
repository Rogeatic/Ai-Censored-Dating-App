import SwiftUI
import JitsiMeetSDK

struct VideoCallView: UIViewControllerRepresentable {
    let roomID: String
    let roomPassword: String?
    let displayName: String
    let email: String
    let avatarURL: URL

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false

        let roomLabel = UILabel()
        roomLabel.text = "Room ID: \(roomID)"
        roomLabel.textAlignment = .center
        roomLabel.font = UIFont.systemFont(ofSize: 24)
        stackView.addArrangedSubview(roomLabel)

        let jitsiMeetView = JitsiMeetView()
        jitsiMeetView.delegate = context.coordinator
        let options = JitsiMeetConferenceOptions.fromBuilder { (builder) in
            builder.room = roomID
            builder.serverURL = URL(string: "https://64.23.140.158")!
            builder.userInfo = JitsiMeetUserInfo(displayName: displayName, andEmail: email, andAvatar: avatarURL)
            if let password = roomPassword {
                builder.setConfigOverride("password", withValue: password)
            }
            builder.setFeatureFlag("p2p.enabled", withBoolean: true)
            builder.setFeatureFlag("meeting-password-enabled", withBoolean: false)
            builder.setFeatureFlag("invite.enabled", withBoolean: false)
            builder.setFeatureFlag("live-streaming.enabled", withBoolean: false)
            builder.setFeatureFlag("recording.enabled", withBoolean: false)
            builder.setFeatureFlag("toolbox.enabled", withBoolean: false)
            builder.setFeatureFlag("kick-out.enabled", withBoolean: false)
            builder.setFeatureFlag("help.enabled", withBoolean: false)
            builder.setFeatureFlag("close-captions.enabled", withBoolean: false)
        }
        jitsiMeetView.join(options)
        jitsiMeetView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        stackView.addArrangedSubview(jitsiMeetView)

        viewController.view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: viewController.view.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor)
        ])

        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, JitsiMeetViewDelegate {
        var parent: VideoCallView

        init(_ parent: VideoCallView) {
            self.parent = parent
        }

        func conferenceTerminated(_ data: [AnyHashable : Any]!) {
            print("Conference terminated: \(String(describing: data))")
        }

        func conferenceJoined(_ data: [AnyHashable : Any]!) {
            print("Conference joined: \(String(describing: data))")
        }

        func conferenceWillJoin(_ data: [AnyHashable : Any]!) {
            print("Conference will join: \(String(describing: data))")
        }
    }
}
