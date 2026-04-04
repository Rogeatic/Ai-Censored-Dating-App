import SwiftUI
import WebRTC
import NSFWDetector

struct VideoView: View {
    @State private var isBlurred: Bool = false
    @State private var isConnected: Bool = false
    @State private var offerSent: Bool = false

    // Use a class wrapper so we can mutate delegate without SwiftUI re-rendering
    private let webRTCHandler: WebRTCHandler
    private let signalingHandler: SignalingHandler

    init(signalingHandler: SignalingHandler, webRTCHandler: WebRTCHandler) {
        self.signalingHandler = signalingHandler
        self.webRTCHandler = webRTCHandler
    }

    var body: some View {
        ZStack {
            // Full-screen remote video
            RemoteVideoView(webRTCHandler: webRTCHandler, isBlurred: $isBlurred)
                .edgesIgnoringSafeArea(.all)
                .blur(radius: isBlurred ? 40 : 0)
                .overlay {
                    if isBlurred {
                        LinearGradient.teal
                            .opacity(0.85)
                            .overlay {
                                Text("Shielding your eyes")
                                    .font(.title3.bold())
                                    .foregroundColor(.white)
                            }
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: isBlurred)

            // Connection status overlay
            if !isConnected {
                ConnectingView()
            }

            // Picture-in-picture local video — always on top
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    LocalVideoView(webRTCHandler: webRTCHandler)
                        .frame(width: 120, height: 160)
                        .cornerRadius(30)
                        .shadow(radius: 6)
                        .mask(
                            RoundedRectangle(cornerRadius: 12)
                                .padding(3)
                                .blur(radius: 26)
                        )
                        .padding(20)
                }
            }
        }
        .tint(Color("appOrange"))
        .onAppear {
            // Set delegates
            webRTCHandler.delegate = makeWebRTCDelegate()
            signalingHandler.delegate = makeSignalingDelegate()
            signalingHandler.connect()
        }
        .onDisappear {
            webRTCHandler.disconnect()
            signalingHandler.disconnect()
            offerSent = false
            isConnected = false
        }
    }

    // MARK: - Offer (called once after signaling connects)

    private func sendOfferIfNeeded() {
        guard !offerSent else { return }
        offerSent = true
        webRTCHandler.offer { sdp in
            signalingHandler.send(sdp: sdp)
        }
    }

    // MARK: - Delegate Factories
    // Using closures avoids conforming the View struct to protocols (which breaks SwiftUI state updates)

    private func makeWebRTCDelegate() -> WebRTCDelegateHandler {
        WebRTCDelegateHandler(
            onCandidate: { candidate in
                signalingHandler.send(candidate: candidate)
            },
            onStateChange: { state in
                DispatchQueue.main.async {
                    switch state {
                    case .connected, .completed:
                        isConnected = true
                    case .disconnected, .failed, .closed:
                        isConnected = false
                        offerSent = false
                    default:
                        break
                    }
                }
            },
            onData: { data in
                // Handle incoming data channel messages here
                if let text = String(data: data, encoding: .utf8) {
                    print("📨 Received message: \(text)")
                }
            }
        )
    }

    private func makeSignalingDelegate() -> SignalingDelegateHandler {
        SignalingDelegateHandler(
            onConnect: {
                // Signaling server connected — send offer
                sendOfferIfNeeded()
            },
            onDisconnect: {
                DispatchQueue.main.async {
                    isConnected = false
                    offerSent = false
                }
            },
            onRemoteSdp: { sdp in
                webRTCHandler.set(remoteSdp: sdp) { error in
                    guard error == nil else {
                        print("⚠️ setRemoteSdp error: \(String(describing: error))")
                        return
                    }
                    webRTCHandler.answer { answerSdp in
                        signalingHandler.send(sdp: answerSdp)
                    }
                }
            },
            onCandidate: { candidate in
                webRTCHandler.set(remoteCandidate: candidate) { error in
                    if let error { print("⚠️ addCandidate error: \(error)") }
                }
            }
        )
    }
}

// MARK: - Delegate Handler Classes
// These are lightweight class wrappers so we can pass closures as delegates

final class WebRTCDelegateHandler: WebRTCDelegate {
    private let onCandidate: (RTCIceCandidate) -> Void
    private let onStateChange: (RTCIceConnectionState) -> Void
    private let onData: (Data) -> Void

    init(
        onCandidate: @escaping (RTCIceCandidate) -> Void,
        onStateChange: @escaping (RTCIceConnectionState) -> Void,
        onData: @escaping (Data) -> Void
    ) {
        self.onCandidate = onCandidate
        self.onStateChange = onStateChange
        self.onData = onData
    }

    func webRTC(_ client: WebRTCHandler, didDiscoverLocalCandidate candidate: RTCIceCandidate) {
        onCandidate(candidate)
    }
    func webRTC(_ client: WebRTCHandler, didChangeConnectionState state: RTCIceConnectionState) {
        onStateChange(state)
    }
    func webRTC(_ client: WebRTCHandler, didReceiveData data: Data) {
        onData(data)
    }
}

final class SignalingDelegateHandler: SignalManager {
    private let onConnect: () -> Void
    private let onDisconnect: () -> Void
    private let onRemoteSdp: (RTCSessionDescription) -> Void
    private let onCandidate: (RTCIceCandidate) -> Void

    init(
        onConnect: @escaping () -> Void,
        onDisconnect: @escaping () -> Void,
        onRemoteSdp: @escaping (RTCSessionDescription) -> Void,
        onCandidate: @escaping (RTCIceCandidate) -> Void
    ) {
        self.onConnect = onConnect
        self.onDisconnect = onDisconnect
        self.onRemoteSdp = onRemoteSdp
        self.onCandidate = onCandidate
    }

    func signalClientDidConnect(_ signalingHandler: SignalingHandler) { onConnect() }
    func signalClientDidDisconnect(_ signalingHandler: SignalingHandler) { onDisconnect() }
    func signalClient(_ signalingHandler: SignalingHandler, didReceiveRemoteSdp sdp: RTCSessionDescription) { onRemoteSdp(sdp) }
    func signalClient(_ signalingHandler: SignalingHandler, didReceiveCandidate candidate: RTCIceCandidate) { onCandidate(candidate) }
}

// MARK: - Local Video View

struct LocalVideoView: UIViewRepresentable {
    let webRTCHandler: WebRTCHandler

    func makeUIView(context: Context) -> RTCMTLVideoView {
        let view = RTCMTLVideoView(frame: .zero)
        view.videoContentMode = .scaleAspectFill
        webRTCHandler.startLocalVideo(renderer: view)
        return view
    }

    func updateUIView(_ uiView: RTCMTLVideoView, context: Context) {}
}

// MARK: - Remote Video View

struct RemoteVideoView: UIViewRepresentable {
    let webRTCHandler: WebRTCHandler
    @Binding var isBlurred: Bool

    func makeUIView(context: Context) -> RTCMTLVideoView {
        let view = RTCMTLVideoView(frame: .zero)
        view.videoContentMode = .scaleAspectFill
        webRTCHandler.renderRemoteVideo(to: view)
        // Also attach the NSFW coordinator as a renderer
        webRTCHandler.remoteVideoTrack?.add(context.coordinator)
        return view
    }

    func updateUIView(_ uiView: RTCMTLVideoView, context: Context) {}

    func makeCoordinator() -> NSFWCoordinator {
        NSFWCoordinator(isBlurred: $isBlurred)
    }

    static func dismantleUIView(_ uiView: RTCMTLVideoView, coordinator: NSFWCoordinator) {
        // coordinator.webRTCHandler would remove it — here we just let it deallocate
    }
}

// MARK: - NSFW Coordinator

final class NSFWCoordinator: NSObject, RTCVideoRenderer {
    @Binding var isBlurred: Bool
    private var blurTimer: Timer?
    private var skipFrame = false
    private let detector = NSFWDetector.shared

    init(isBlurred: Binding<Bool>) {
        self._isBlurred = isBlurred
    }

    func setSize(_ size: CGSize) {}

    func renderFrame(_ frame: RTCVideoFrame?) {
        // Process every other frame to reduce CPU load
        skipFrame.toggle()
        guard !skipFrame, let frame else { return }
        guard let buffer = frame.buffer as? RTCCVPixelBuffer else { return }

        let ci = CIImage(cvPixelBuffer: buffer.pixelBuffer)
        let ctx = CIContext()
        guard let cg = ctx.createCGImage(ci, from: ci.extent) else { return }
        let image = UIImage(cgImage: cg)

        detector.check(image: image) { [weak self] result in
            guard let self else { return }
            if case .success(let confidence) = result {
                DispatchQueue.main.async {
                    if confidence > 0.90 {
                        self.blurTimer?.invalidate()
                        self.blurTimer = nil
                        self.isBlurred = true
                    } else if self.blurTimer == nil {
                        self.blurTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
                            self.isBlurred = false
                            self.blurTimer = nil
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Connecting View

struct ConnectingView: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            // Semi-transparent dark background — lets local video show through
            Color.black.opacity(0.55).ignoresSafeArea()

            // Dancing teal blobs
            ZStack {
                // Blob 1
                Circle()
                    .fill(Color.darkTeal.opacity(0.7))
                    .frame(width: 280, height: 280)
                    .blur(radius: 60)
                    .offset(
                        x: animate ? -60 : 60,
                        y: animate ? -80 : 40
                    )
                    .animation(
                        .easeInOut(duration: 3.2).repeatForever(autoreverses: true),
                        value: animate
                    )

                // Blob 2
                Circle()
                    .fill(Color.darkTeal1.opacity(0.6))
                    .frame(width: 220, height: 220)
                    .blur(radius: 50)
                    .offset(
                        x: animate ? 70 : -50,
                        y: animate ? 60 : -70
                    )
                    .animation(
                        .easeInOut(duration: 2.7).repeatForever(autoreverses: true),
                        value: animate
                    )

                // Blob 3 — smaller accent
                Circle()
                    .fill(Color.darkTeal.opacity(0.5))
                    .frame(width: 160, height: 160)
                    .blur(radius: 40)
                    .offset(
                        x: animate ? 30 : -80,
                        y: animate ? 100 : -30
                    )
                    .animation(
                        .easeInOut(duration: 3.8).repeatForever(autoreverses: true),
                        value: animate
                    )
            }

            // Text on top
            VStack(spacing: 16) {
                ProgressView()
                    .tint(Color("appOrange"))
                    .scaleEffect(1.2)
                Text("Connecting...")
                    .font(.headline)
                    .foregroundColor(Color("appOrange"))
            }
        }
        .onAppear { animate = true }
    }
}
