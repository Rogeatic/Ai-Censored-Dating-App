import SwiftUI

struct ContentView: View {
    @State private var isUserSignedIn: Bool = false
    @State private var displayName: String = ""
    @State private var email: String = ""
    @State private var avatarURL: URL = URL(string: "https://example.com/default-avatar.png")!
    @State private var idToken: String = ""
    @State private var isBlurred: Bool = false
    
    var signalingHandler: SignalingHandler
    var webRTCHandler: WebRTCHandler

    init(signalingHandler: SignalingHandler, webRTCHandler: WebRTCHandler) {
        self.signalingHandler = signalingHandler
        self.webRTCHandler = webRTCHandler
    }

    var body: some View {
        NavigationView {
            if !isUserSignedIn {
                LoginView(isUserSignedIn: $isUserSignedIn, displayName: $displayName, email: $email, avatarURL: $avatarURL, idToken: $idToken)
            } else {
                VStack {
                    CameraPreviewView(isBlurred: $isBlurred, videoTrack: webRTCHandler.localVideoTrack)
                        .cornerRadius(15)
                        .frame(height: 400)
                        .padding()
                        .blur(radius: isBlurred ? 100 : 0)
                        .background(isBlurred ? AnyView(LinearGradient(gradient: Gradient(colors: [Color.darkTeal, Color.darkTeal1]), startPoint: .topLeading, endPoint: .bottomTrailing)) : AnyView(Color.clear))
                        .animation(.easeInOut, value: isBlurred)
                        .cornerRadius(15)

                    Text("Hello, \(displayName)")
                        .padding()

                    NavigationLink(destination: VideoView(signalingHandler: signalingHandler, webRTCHandler: webRTCHandler)) {
                        Text("Go to Video View")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding()
                }
                .padding()
                .background(Color.white)
                .onTapGesture {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
