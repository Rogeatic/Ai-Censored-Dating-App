import SwiftUI
import GoogleSignIn

struct ContentView: View {
    // Google sign-in info
    @State private var isUserSignedIn: Bool = false
    @State private var displayName: String = ""
    @State private var email: String = ""
    @State private var avatarURL: URL = URL(string: "https://example.com/default-avatar.png")!
    @State private var idToken: String = ""
    
    // Blurring state
    @State private var isBlurred: Bool = false
    // Button clicked
    @State private var isLoading: Bool = false
    // Video stream states
    @State private var isLocalVideoActive: Bool = false
    @State private var isRemoteVideoActive: Bool = false
    // WebRTC states
    @State private var signalingConnected: Bool = false
    @State private var hasLocalSdp: Bool = false
    @State private var localCandidateCount: Int = 0
    @State private var hasRemoteSdp: Bool = false
    @State private var remoteCandidateCount: Int = 0
    
    private var signalingHandler: SignalingHandler
    private var webRTCHandler: WebRTCHandler
    
    @State private var coordinator: MainViewControllerRepresentable.Coordinator?

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
                    MainViewControllerRepresentable(
                        signalingHandler: signalingHandler,
                        webRTCHandler: webRTCHandler,
                        isLocalVideoActive: $isLocalVideoActive,
                        isRemoteVideoActive: $isRemoteVideoActive,
                        signalingConnected: $signalingConnected,
                        hasLocalSdp: $hasLocalSdp,
                        localCandidateCount: $localCandidateCount,
                        hasRemoteSdp: $hasRemoteSdp,
                        remoteCandidateCount: $remoteCandidateCount
                    )
                    .cornerRadius(15)
                    .frame(height: 400)
                    .padding()
                    .blur(radius: isBlurred ? 100 : 0)
                    .background(isBlurred ? Color.darkTeal : Color.clear)
                    .animation(.easeInOut, value: isBlurred)
                    .cornerRadius(15)
                    .onAppear {
                        if coordinator == nil {
                            coordinator = MainViewControllerRepresentable.Coordinator(MainViewControllerRepresentable(
                                signalingHandler: signalingHandler,
                                webRTCHandler: webRTCHandler,
                                isLocalVideoActive: $isLocalVideoActive,
                                isRemoteVideoActive: $isRemoteVideoActive,
                                signalingConnected: $signalingConnected,
                                hasLocalSdp: $hasLocalSdp,
                                localCandidateCount: $localCandidateCount,
                                hasRemoteSdp: $hasRemoteSdp,
                                remoteCandidateCount: $remoteCandidateCount
                            ))
                        }
                    }
                    
                    Text("Hello, \(displayName)")
                        .padding()

                    Text("Signaling Connected: \(signalingConnected ? "Yes" : "No")")
                    Text("Local SDP: \(hasLocalSdp ? "Yes" : "No")")
                    Text("Local Candidates: \(localCandidateCount)")
                    Text("Remote SDP: \(hasRemoteSdp ? "Yes" : "No")")
                    Text("Remote Candidates: \(remoteCandidateCount)")

                    Button(action: sendOffer) {
                        Text(isLoading ? "Joining..." : "Send Offer")
                            .padding()
                            .background(isLoading ? Color.gray : Color.darkTeal)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding()
                    .disabled(isLoading)

                    Button(action: sendAnswer) {
                        Text(isLoading ? "Joining..." : "Send Answer")
                            .padding()
                            .background(isLoading ? Color.gray : Color.darkTeal)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding()
                    .disabled(isLoading)
                    
                    NavigationLink(destination: VideoView(webRTCHandler: webRTCHandler)) {
                        Text("Go to Video View")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding()
                    .disabled(!isLocalVideoActive || !isRemoteVideoActive)
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

    private func sendOffer() {
        print("sendOffer called")
        isLoading = true
        coordinator?.offer()
    }

    private func sendAnswer() {
        print("sendAnswer called")
        isLoading = true
        coordinator?.answer()
    }
}
