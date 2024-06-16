import SwiftUI
import WebRTC

struct VideoCallView: View {
    @StateObject private var webRTCClient = WebRTCClient()

    let roomID: String
    let roomPassword: String

    var body: some View {
        VStack {
            Text("Video Call - Room ID: \(roomID)")
                .padding()

            // Add video views here (e.g., local and remote video tracks)

            Button(action: {
                webRTCClient.startConnection()
            }) {
                Text("Start Call")
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }

            Button(action: {
                webRTCClient.endConnection()
            }) {
                Text("End Call")
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .onAppear {
            webRTCClient.webSocketManager.webRTCClient = webRTCClient
        }
    }
}

struct VideoCallView_Previews: PreviewProvider {
    static var previews: some View {
        VideoCallView(roomID: "testRoom", roomPassword: "testPassword")
    }
}
