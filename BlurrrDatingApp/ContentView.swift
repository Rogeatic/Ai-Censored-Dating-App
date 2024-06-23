import SwiftUI

struct ContentView: View {
    @StateObject private var socketManager = SocketIOManager()
    @State private var userID: String = ""
    @State private var navigateToVideoCall: Bool = false

    var body: some View {
        VStack {
            TextField("Enter your user ID", text: $userID)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button(action: {
                socketManager.joinRoom(userID: userID)
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
                NavigationLink(destination: VideoCallView(roomID: socketManager.roomID), isActive: .constant(true)) {
                    EmptyView()
                }
            }
        }
        .padding()
        .onAppear {
            print("ContentView appeared")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

