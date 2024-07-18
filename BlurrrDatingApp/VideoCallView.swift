import SwiftUI
import WebRTC
import CoreML
import Vision
import NSFWDetector

struct VideoView: View {
    @State private var isBlurred: Bool = false
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
            RemoteVideoView(webRTCHandler: webRTCHandler, isBlurred: $isBlurred)
                .blur(radius: isBlurred ? 100 : 0)
                .background(isBlurred ? AnyView(LinearGradient(gradient: Gradient(colors: [Color.darkTeal, Color.darkTeal1]), startPoint: .topLeading, endPoint: .bottomTrailing)) : AnyView(Color.clear))
                .animation(.easeInOut, value: isBlurred)
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
        }
        .onAppear {
            self.signalingHandler.connect()
            DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                self.pairUsers()
            }
        }
        .onDisappear(){
            disconnect()
        }
    }

    private func pairUsers() {
        webRTCHandler.offer { sdp in
            signalingHandler.send(sdp: sdp)
            hasLocalSdp = true
        }
    }

    private func disconnect() {
        webRTCHandler.disconnect()
        signalingHandler.disconnect()
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
            if message.contains("signaling") {
                print("SUCCESS")
            }
            if message.contains("Paired with another client") {
                self.pairMessage = "Paired with another client"
            } else if message.contains("Waiting for a pair") {
                self.pairMessage = "Waiting for a pair"
            } else if message.contains("opened data channel") {
                self.pairMessage = "opened data channel"
            } else if message.contains("Your pair has disconnected") {
                self.pairMessage = "Your pair has disconnected"
                self.isLocalVideoActive = false
                self.isRemoteVideoActive = false
            }
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
    @Binding var isBlurred: Bool
    var blurTimer: Timer?

    class Coordinator: NSObject, RTCVideoRenderer {
        var parent: RemoteVideoView
        var nsfwDetector = NSFWDetector.shared
        private var blurTimer: Timer?
        private var processNextFrame = true

        init(parent: RemoteVideoView) {
            self.parent = parent
        }

        func setSize(_ size: CGSize) {}

        func renderFrame(_ frame: RTCVideoFrame?) {
            processNextFrame.toggle()
            if !processNextFrame {
                return
            }

            guard let buffer = frame?.buffer as? RTCCVPixelBuffer else { return }
            let pixelBuffer = buffer.pixelBuffer

            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let context = CIContext()
            guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
            let uiImage = UIImage(cgImage: cgImage)

            nsfwDetector.check(image: uiImage, completion: { result in
                switch result {
                case let .success(nsfwConfidence: confidence):
                    DispatchQueue.main.async {
                        if confidence > 0.72 {
                            self.applyCensoring()
                        } else {
                            self.scheduleRemoveCensoring()
                        }
                    }
                default:
                    break
                }
            })
        }

        func applyCensoring() {
            blurTimer?.invalidate()
            parent.isBlurred = true
            blurTimer = nil
        }

        func scheduleRemoveCensoring() {
            if blurTimer == nil {
                blurTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
                    self.parent.isBlurred = false
                    self.blurTimer = nil
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UIView {
        let remoteRenderer = RTCMTLVideoView(frame: .zero)
        remoteRenderer.videoContentMode = .scaleAspectFill
        webRTCHandler.renderRemoteVideo(to: remoteRenderer)
        webRTCHandler.remoteVideoTrack?.add(context.coordinator)
        return remoteRenderer
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.parent.webRTCHandler.remoteVideoTrack?.remove(coordinator)
    }
}
