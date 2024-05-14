import SwiftUI
import AVFoundation
import JitsiMeetSDK

struct ConnectingView: View {
    var body: some View {
        VStack {
            Text("Finding Your Connection... ;)")
            // Add loading animation or logo animation here
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                .scaleEffect(2)
                .padding()
        }
    }
}
