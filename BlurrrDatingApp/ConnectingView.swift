import SwiftUI
import AVFoundation
import JitsiMeetSDK

struct ConnectingView: View {
    let timerDuration: TimeInterval = 30 // 30 seconds countdown
    @Binding var isConnecting: Bool
    @Binding var connected: Bool
    @Binding var socketConnected: Bool
    
    var body: some View {
        VStack {
            if connected {
                Text("Connected. Joining the room...")
            } else if socketConnected {
                Text("Connected to socket. Waiting to be paired...")
                // Loading animation or logo animation
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .scaleEffect(2)
                    .padding()
            } else {
                Text("Waiting to connect to socket...")
                // Loading animation or logo animation
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .scaleEffect(2)
                    .padding()
            }
        }
    }
}
