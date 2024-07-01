import SwiftUI
import WebRTC

struct ContentView: View {
    @EnvironmentObject var webRTCManager: WebRTCManager

    var body: some View {
        VStack {
            VideoViewContainer(videoView: webRTCManager.remoteView)
                .frame(height: 300)
                .background(Color.black)
            VideoViewContainer(videoView: webRTCManager.localView)
                .frame(width: 150, height: 200)
                .background(Color.black)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white, lineWidth: 2)
                )
                .padding()
            Button(action: {
                webRTCManager.startConnection()
            }) {
                Text("Start Connection")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
    }
}

struct VideoViewContainer: UIViewRepresentable {
    let videoView: RTCMTLVideoView
    
    func makeUIView(context: Context) -> RTCMTLVideoView {
        return videoView
    }
    
    func updateUIView(_ uiView: RTCMTLVideoView, context: Context) {}
}
