import SwiftUI
import JitsiMeetSDK

class JitsiMeetDelegate: NSObject, JitsiMeetViewDelegate {
    func conferenceJoined(_ data: [AnyHashable : Any]!) {
        print("Conference joined with data: \(data ?? [:])")
    }

    func conferenceTerminated(_ data: [AnyHashable : Any]!) {
        print("Conference terminated with data: \(data ?? [:])")
    }

    func conferenceWillJoin(_ data: [AnyHashable : Any]!) {
        print("Conference will join with data: \(data ?? [:])")
    }
}

struct JitsiMeetViewWrapper: UIViewRepresentable {
    let roomName: String
    var password: String
    let delegate = JitsiMeetDelegate()

    func makeUIView(context: Context) -> JitsiMeetView {
        let jitsiMeetView = JitsiMeetView()
        jitsiMeetView.delegate = delegate

        let options = JitsiMeetConferenceOptions.fromBuilder { (builder) in
            builder.room = roomName
            builder.setFeatureFlag("ios.screensharing.enabled", withBoolean: false)
            builder.setFeatureFlag("welcomepage.enabled", withBoolean: false)
        }
        jitsiMeetView.join(options)
        return jitsiMeetView
    }

    func updateUIView(_ uiView: JitsiMeetView, context: Context) {
        // Do nothing
    }
}
