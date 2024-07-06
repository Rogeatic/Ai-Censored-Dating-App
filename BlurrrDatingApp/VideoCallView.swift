import SwiftUI
import WebRTC

struct VideoView: View {
    var webRTCHandler: WebRTCHandler
    
    var body: some View {
        ZStack {
            RemoteVideoView(webRTCHandler: webRTCHandler)
                .edgesIgnoringSafeArea(.all)
            LocalVideoView(webRTCHandler: webRTCHandler)
                .frame(width: 150, height: 200)
                .cornerRadius(15)
                .padding()
                .background(Color.black.opacity(0.6))
                .cornerRadius(15)
                .padding()
        }
    }
}

struct LocalVideoView: UIViewRepresentable {
    var webRTCHandler: WebRTCHandler
    
    func makeUIView(context: Context) -> UIView {
        let localRenderer = RTCMTLVideoView(frame: .zero)
        localRenderer.videoContentMode = .scaleAspectFill
        webRTCHandler.LocalVideo(renderer: localRenderer)
        return localRenderer
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

struct RemoteVideoView: UIViewRepresentable {
    var webRTCHandler: WebRTCHandler
    
    func makeUIView(context: Context) -> UIView {
        let remoteRenderer = RTCMTLVideoView(frame: .zero)
        remoteRenderer.videoContentMode = .scaleAspectFill
        webRTCHandler.renderRemoteVideo(to: remoteRenderer)
        return remoteRenderer
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}
