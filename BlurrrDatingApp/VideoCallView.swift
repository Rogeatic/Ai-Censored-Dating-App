import SwiftUI
import WebRTC
import CoreML
import Vision
import NSFWDetector

struct VideoView: View {
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
        ZStack {
            RemoteVideoView(webRTCHandler: webRTCHandler)
                .edgesIgnoringSafeArea(.all)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    LocalVideoView(webRTCHandler: webRTCHandler)
                        .frame(width: 150, height: 200)
                        .cornerRadius(15)
                        .background(Color.clear)
                        .padding()
                }
            }
            .blur(radius: isBlurred ? 100 : 0)
            .background(isBlurred ? AnyView(LinearGradient(gradient: Gradient(colors: [Color.darkTeal, Color.darkTeal1]), startPoint: .topLeading, endPoint: .bottomTrailing)) : AnyView(Color.clear))
            .animation(.easeInOut, value: isBlurred)
        }
        .onAppear {
            self.signalingHandler.connect()
            DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                self.pairUsers()
            }
        }
    }

    private func pairUsers() {
        isLoading = true
        webRTCHandler.offer { sdp in
            signalingHandler.send(sdp: sdp)
            hasLocalSdp = true
        }
    }
}

extension VideoView: WebRTCManager {
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

extension VideoView: SignalManager {
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
            if message.contains("signaling"){
                print("SUCCESS")
            }
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

// Add definitions for LocalVideoView and RemoteVideoView
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
