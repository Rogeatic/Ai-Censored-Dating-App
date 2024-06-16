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
    
    var body: some View {
<<<<<<< Updated upstream
        VStack {
            if let roomName = roomName {
                JitsiMeetViewWrapper(roomName: roomName)
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                    .ignoresSafeArea()
            } else {
                Text("Connecting...")
                    .onAppear {
                        fetchRoomName()
                    }
=======
        NavigationView {
            VStack {
                Text("ContentView Loaded")
                    .padding()

                TextField("Enter your user ID", text: $userID, onEditingChanged: { isEditing in
                    if !isEditing {
                        UIApplication.shared.endEditing()
                    }
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

                Button(action: {
                    print("Join Room button pressed with userID: \(userID)")
                    socketManager.joinRoom(userID: userID) {
                        print("Room joined with ID: \(socketManager.roomID) and Password: \(socketManager.roomPassword)")
                        navigateToVideoCall = true
                    }
                }) {
                    Text("Join Room")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding()

                if !socketManager.roomID.isEmpty {
                    Text("Room ID: \(socketManager.roomID)")
                        .padding()
                    Text("Room Password: \(socketManager.roomPassword)")
                        .padding()
                } else {
                    Text("Waiting for room ID...")
                        .padding()
                }

                NavigationLink(destination: VideoCallView(roomID: socketManager.roomID, roomPassword: socketManager.roomPassword), isActive: $navigateToVideoCall) {
                    EmptyView()
                }
            }
            .padding()
            .onAppear {
                print("ContentView appeared")
            }
            .background(Color.white)
            .onTapGesture {
                UIApplication.shared.endEditing()
>>>>>>> Stashed changes
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
//import SwiftUI
//struct ContentView : View {
//    var body: some View {
//        Text("HelloWorld")
//    }
//}
//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
