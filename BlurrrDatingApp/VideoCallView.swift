import SwiftUI
import WebRTC

struct VideoDetailView: View {
    var webRTCHandler: WebRTCHandler

    var body: some View {
        VStack {
            Text("Video Detail View")
                .font(.largeTitle)
                .padding()

            VideoView(isBlurred: .constant(false), isLocalVideoActive: .constant(true), isRemoteVideoActive: .constant(true))
                .cornerRadius(15)
                .frame(height: 400)
                .padding()
                .background(Color.black)
                .cornerRadius(15)

            Button(action: {
                webRTCHandler.hideVideo()
            }) {
                Text("Hide Video")
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()

            Button(action: {
                webRTCHandler.showVideo()
            }) {
                Text("Show Video")
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()
        }
    }
}

struct VideoDetailView_Previews: PreviewProvider {
    static var previews: some View {
        VideoDetailView(webRTCHandler: WebRTCHandler(iceServers: ["stun:stun.l.google.com:19302"]))
    }
}
