import SwiftUI
import WebRTC
import AVFoundation

struct ContentView: View {
    @State private var isUserSignedIn: Bool = true
    @State private var displayName: String = ""
    @State private var email: String = ""
    @State private var avatarURL: URL = URL(string: "https://example.com/default-avatar.png")!
    @State private var idToken: String = ""
    @State private var isBlurred: Bool = false
    @State private var isLoading: Bool = false
    @State private var isLocalVideoActive: Bool = false
    @State private var isRemoteVideoActive: Bool = false
    @State private var signalingConnected: Bool = false
    @State private var hasLocalSdp: Bool = false
    @State private var localCandidateCount: Int = 0
    @State private var hasRemoteSdp: Bool = false
    @State private var remoteCandidateCount: Int = 0
    @State private var pairMessage: String = "Waiting for a pair"

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

                    Text(pairMessage)
                        .padding()

                    Button(action: pairUsers) {
                        Text(isLoading ? "Pairing..." : "Pair Users")
                            .padding()
                            .background(isLoading ? Color.gray : Color.teal)
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
                    //.disabled(!isLocalVideoActive || !isRemoteVideoActive)
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

    private func pairUsers() {
        isLoading = true
        webRTCHandler.offer { sdp in
            signalingHandler.send(sdp: sdp)
            hasLocalSdp = true
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
                webRTCHandler.answer { sdp in
                    signalingHandler.send(sdp: sdp)
                    hasLocalSdp = true
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

    func signalClient(_ signalingHandler: SignalingHandler, didReceiveMessage message: String) {
        DispatchQueue.main.async {
            if message.contains("Paired with another client") {
                self.pairMessage = "Paired with another client"
                self.isLoading = false
            } else if message.contains("Waiting for a pair") {
                self.pairMessage = "Waiting for a pair"
                self.isLoading = false
            } else if message.contains("opened data channel") {
                self.pairMessage = "opened data channel"
                self.isLoading = false
            } else if message.contains("Your pair has disconnected") {
                self.pairMessage = "Your pair has disconnected"
                self.isLocalVideoActive = false
                self.isRemoteVideoActive = false
            }
        }
    }
}
