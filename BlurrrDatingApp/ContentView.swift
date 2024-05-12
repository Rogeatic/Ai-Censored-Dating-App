import SwiftUI
import JitsiMeetSDK

class JitsiMeetDelegate: NSObject, JitsiMeetViewDelegate {
    func conferenceJoined(_ data: [AnyHashable : Any]!) {
        if let data = data {
            print("Conference joined with data: \(data)")
        } else {
            print("Conference joined with no data")
        }
    }
    
    func conferenceTerminated(_ data: [AnyHashable : Any]!) {
        if let data = data {
            print("Conference terminated with data: \(data)")
        } else {
            print("Conference terminated with no data")
        }
    }
    
    // Implement other delegate methods as needed
}

struct JitsiMeetViewWrapper: UIViewRepresentable {
    let roomName: String
    let delegate = JitsiMeetDelegate()
    
    func makeUIView(context: Context) -> JitsiMeetView {
        let jitsiMeetView = JitsiMeetView()
        jitsiMeetView.delegate = delegate
        return jitsiMeetView
    }
    
    func updateUIView(_ uiView: JitsiMeetView, context: Context) {
        // Do nothing
    }
}

struct ContentView: View {
    let roomName = "your-hardcoded-room-name"

    var body: some View {
        VStack {
            JitsiMeetViewWrapper(roomName: roomName)
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                .ignoresSafeArea()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
