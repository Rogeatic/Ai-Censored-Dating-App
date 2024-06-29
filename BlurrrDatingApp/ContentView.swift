import SwiftUI

struct ContentView: View {
    @StateObject private var socketManager = SocketIOManager()
    @StateObject private var webrtcManager = WebRTCManager()
    @State private var navigateToVideoCall: Bool = false
    @State private var isUserSignedIn: Bool = true // Assuming the user is signed in for simplicity

    var body: some View {
        NavigationView {
            VStack {
                Text("P2P Video Streaming")
                    .font(.largeTitle)
                    .padding()

                Button(action: {
                    print("Join Room button pressed")
                    socketManager.joinRoom() {
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

                NavigationLink(
                    destination: VideoCallView(roomID: socketManager.roomID, roomToken: socketManager.roomToken)
                        .navigationBarHidden(true),
                    isActive: $navigateToVideoCall
                ) {
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
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
