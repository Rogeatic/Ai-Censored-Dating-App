import SwiftUI
import WebRTC

struct VideoCallView: View {
    @StateObject private var webrtcManager = WebRTCManager()
    var roomID: String
    var roomToken: String

    var body: some View {
        VStack {
            RTCVideoView(webrtcManager: webrtcManager)
                .frame(width: 300, height: 400)
                .background(Color.black)
                .cornerRadius(10)
                .padding()

            Button(action: {
                webrtcManager.createOffer()
            }) {
                Text("Start Call")
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()

            Button(action: {
                webrtcManager.endCall()
                webrtcManager.setupPeerConnection() // This should work if these methods are correctly defined in WebRTCManager
            }) {
                Text("End Call")
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()
        }
        .onAppear {
            webrtcManager.setupPeerConnection()
            webrtcManager.joinRoom(roomID: roomID, roomToken: roomToken)
        }
        .navigationBarHidden(true)
    }
}

struct RTCVideoView: UIViewRepresentable {
    @ObservedObject var webrtcManager: WebRTCManager

    func makeUIView(context: Context) -> UIView {
        #if arch(arm64)
        // Use RTCMTLVideoView for 64-bit arm (arm64)
        return webrtcManager.metalVideoView()
        #else
        // Use RTCEAGLVideoView for other architectures (like armv7)
        return webrtcManager.eaglVideoView()
        #endif
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
