import SwiftUI
import WebRTC

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
    
    var signalingHandler: SignalingHandler
    var webRTCHandler: WebRTCHandler

    init(signalingHandler: SignalingHandler, webRTCHandler: WebRTCHandler) {
        self.signalingHandler = signalingHandler
        self.webRTCHandler = webRTCHandler
        self.webRTCHandler.delegate = self
        self.signalingHandler.delegate = self
    }
    
    var body: some View {
        NavigationView {
            if !isUserSignedIn {
                LoginView(isUserSignedIn: $isUserSignedIn, displayName: $displayName, email: $email, avatarURL: $avatarURL, idToken: $idToken)
            } else {
                VStack {
                    VideoView(isBlurred: $isBlurred, isLocalVideoActive: $isLocalVideoActive, isRemoteVideoActive: $isRemoteVideoActive)
                        .cornerRadius(15)
                        .frame(height: 400)
                        .padding()
                        .blur(radius: isBlurred ? 100 : 0)
                        .background(isBlurred ? Color.teal : Color.clear)
                        .animation(.easeInOut, value: isBlurred)
                    
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
                            .background(isLoading ? Color.gray : Color.teal)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding()
                    .disabled(isLoading)

                    Button(action: sendAnswer) {
                        Text(isLoading ? "Joining..." : "Send Answer")
                            .padding()
                            .background(isLoading ? Color.gray : Color.teal)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding()
                    .disabled(isLoading)
                    
                    NavigationLink(destination: VideoDetailView(webRTCHandler: webRTCHandler)) {
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
                .onAppear {
                    self.signalingHandler.connect()
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private func sendOffer() {
        print("sendOffer called")
        isLoading = true
        webRTCHandler.offer { sdp in
            signalingHandler.send(sdp: sdp)
            isLoading = false
            hasLocalSdp = true
        }
    }

    private func sendAnswer() {
        print("sendAnswer called")
        isLoading = true
        webRTCHandler.answer { sdp in
            signalingHandler.send(sdp: sdp)
            isLoading = false
            hasLocalSdp = true
        }
    }
}

struct VideoView: UIViewRepresentable {
    @Binding var isBlurred: Bool
    @Binding var isLocalVideoActive: Bool
    @Binding var isRemoteVideoActive: Bool

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let localRenderer = RTCMTLVideoView(frame: view.bounds)
        let remoteRenderer = RTCMTLVideoView(frame: view.bounds)

        localRenderer.videoContentMode = .scaleAspectFill
        remoteRenderer.videoContentMode = .scaleAspectFill

        view.addSubview(remoteRenderer)
        view.addSubview(localRenderer)

        context.coordinator.setupRenderers(localRenderer: localRenderer, remoteRenderer: remoteRenderer)
        
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Update UI if needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        func setupRenderers(localRenderer: RTCMTLVideoView, remoteRenderer: RTCMTLVideoView) {
            // Setup video renderers
        }
    }
}

extension ContentView: WebRTCManager {
    func webRTCHandler(_ client: WebRTCHandler, didDiscoverLocalCandidate candidate: RTCIceCandidate) {
        signalingHandler.send(candidate: candidate)
        localCandidateCount += 1
    }
    
    func webRTCHandler(_ client: WebRTCHandler, didChangeConnectionState state: RTCIceConnectionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected, .completed:
                self.isLocalVideoActive = true
                self.isRemoteVideoActive = true
            case .disconnected, .failed, .closed:
                self.isLocalVideoActive = false
                self.isRemoteVideoActive = false
            default:
                break
            }
        }
    }
    
    func webRTCHandler(_ client: WebRTCHandler, didReceiveData data: Data) {
        let message = String(data: data, encoding: .utf8) ?? "(Binary: \(data.count) bytes)"
        // Handle received data
    }
}

extension ContentView: SignalManager {
    func signalClientDidConnect(_ signalingHandler: SignalingHandler) {
        DispatchQueue.main.async {
            self.signalingConnected = true
        }
    }
    
    func signalClientDidDisconnect(_ signalingHandler: SignalingHandler) {
        DispatchQueue.main.async {
            self.signalingConnected = false
        }
        // Try to reconnect after a delay
        DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
            self.signalingHandler.connect()
        }
    }
    
    func signalClient(_ signalingHandler: SignalingHandler, didReceiveRemoteSdp sdp: RTCSessionDescription) {
        webRTCHandler.set(remoteSdp: sdp) { error in
            if error == nil {
                DispatchQueue.main.async {
                    self.hasRemoteSdp = true
                }
            }
        }
    }
    
    func signalClient(_ signalingHandler: SignalingHandler, didReceiveCandidate candidate: RTCIceCandidate) {
        webRTCHandler.set(remoteCandidate: candidate) { error in
            if error == nil {
                DispatchQueue.main.async {
                    self.remoteCandidateCount += 1
                }
            }
        }
    }
}
