import SwiftUI
import JitsiMeetSDK

struct VideoCallView: UIViewControllerRepresentable {
    let roomID: String

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()

        // Create a vertical stack to hold the room ID text and JitsiMeetView
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Room ID Label
        let roomLabel = UILabel()
        roomLabel.text = "Room ID: \(roomID)"
        roomLabel.textAlignment = .center
        roomLabel.font = UIFont.systemFont(ofSize: 24)
        stackView.addArrangedSubview(roomLabel)

        // JitsiMeetView
        let jitsiMeetView = JitsiMeetView()
        jitsiMeetView.delegate = context.coordinator
        jitsiMeetView.join(JitsiMeetConferenceOptions.fromBuilder { (builder) in
            builder.room = roomID
        })
        jitsiMeetView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        stackView.addArrangedSubview(jitsiMeetView)

        // Add the stack view to the view controller's view
        viewController.view.addSubview(stackView)
        
        // Set up the constraints for the stack view
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

struct VideoCallView_Previews: PreviewProvider {
    static var previews: some View {
        VideoCallView(roomID: "testRoom")
    }
}
