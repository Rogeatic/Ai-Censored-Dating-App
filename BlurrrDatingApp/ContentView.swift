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
        jitsiMeetView.join(JitsiMeetConferenceOptions.fromBuilder { (builder) in
            builder.room = roomName
        })
        return jitsiMeetView
    }
    
    func updateUIView(_ uiView: JitsiMeetView, context: Context) {
        // Do nothing
    }
}

struct ContentView: View {
    @State private var roomName: String? = nil
    @State private var isConnecting: Bool = false

    var body: some View {
        VStack {
            if let roomName = roomName {
                JitsiMeetViewWrapper(roomName: roomName)
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                    .ignoresSafeArea()
            } else {
                if isConnecting {
                    Text("Connecting...")
                        .onAppear {
                            fetchRoomName()
                        }
                } else {
                    VStack {
                        CameraPreviewView()
                            .frame(height: 300)
                            .cornerRadius(12)
                            .padding()

                        Text("Welcome to the App")
                            .font(.largeTitle)
                            .padding()

                        Button(action: {
                            isConnecting = true
                        }) {
                            Text("Start Video Call")
                                .font(.title2)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                }
            }
        }
    }
    
    func fetchRoomName() {
        guard let url = URL(string: "http://yourserver.com/get_room") else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: String],
                   let roomName = json["room_name"] {
                    DispatchQueue.main.async {
                        self.roomName = roomName
                    }
                }
            }
        }.resume()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
