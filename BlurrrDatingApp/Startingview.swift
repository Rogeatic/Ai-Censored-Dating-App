import SwiftUI
import AVFoundation
import JitsiMeetSDK

struct StartingView: View {
    var onConnect: () -> Void
    
    var body: some View {
        VStack {
            CameraPreviewView()
                .frame(height: 450)
                .cornerRadius(12)
                .padding()

            Text("Welcome to The Blurrr")
                .font(.largeTitle)
                .padding()

            Button(action: onConnect) {
                Text("Start Video Call")
                    .font(.title2)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
    }
}


