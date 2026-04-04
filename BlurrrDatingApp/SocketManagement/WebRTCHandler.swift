import Foundation
import WebRTC

// MARK: - Delegate Protocol
protocol WebRTCDelegate: AnyObject {
    func webRTC(_ client: WebRTCHandler, didDiscoverLocalCandidate candidate: RTCIceCandidate)
    func webRTC(_ client: WebRTCHandler, didChangeConnectionState state: RTCIceConnectionState)
    func webRTC(_ client: WebRTCHandler, didReceiveData data: Data)
}

// MARK: - WebRTCHandler
final class WebRTCHandler: NSObject {

    // Factory is expensive — keep it as a singleton
    private static let factory: RTCPeerConnectionFactory = {
        RTCInitializeSSL()
        let encoderFactory = RTCDefaultVideoEncoderFactory()
        let decoderFactory = RTCDefaultVideoDecoderFactory()
        // Enable H264 hardware encoding if available
        encoderFactory.preferredCodec = RTCVideoCodecInfo(name: kRTCVideoCodecH264Name)
        return RTCPeerConnectionFactory(
            encoderFactory: encoderFactory,
            decoderFactory: decoderFactory
        )
    }()

    weak var delegate: WebRTCDelegate?

    private var peerConnection: RTCPeerConnection!
    private let rtcAudioSession = RTCAudioSession.sharedInstance()
    private let mediaConstraints = [
        kRTCMediaConstraintsOfferToReceiveAudio: kRTCMediaConstraintsValueTrue,
        kRTCMediaConstraintsOfferToReceiveVideo: kRTCMediaConstraintsValueTrue
    ]

    private var videoCapturer: RTCCameraVideoCapturer?
    private(set) var localVideoTrack: RTCVideoTrack?
    private(set) var remoteVideoTrack: RTCVideoTrack?
    private var localDataChannel: RTCDataChannel?
    private var remoteDataChannel: RTCDataChannel?

    // MARK: - Init

    init(iceServers: [String]) {
        let config = RTCConfiguration()
        config.iceServers = [RTCIceServer(urlStrings: iceServers)]
        config.continualGatheringPolicy = .gatherContinually
        config.sdpSemantics = .unifiedPlan
        // Improves connection reliability
        config.bundlePolicy = .maxBundle
        config.rtcpMuxPolicy = .require

        let constraints = RTCMediaConstraints(
            mandatoryConstraints: nil,
            optionalConstraints: ["DtlsSrtpKeyAgreement": kRTCMediaConstraintsValueTrue]
        )

        // Modern stasel/WebRTC returns non-optional
        let pc = WebRTCHandler.factory.peerConnection(
            with: config,
            constraints: constraints,
            delegate: nil
        )
        self.peerConnection = pc

        super.init()
        self.peerConnection.delegate = self

        setupMediaTracks()
        setupDataChannel()
        configureAudioSession()
    }

    // MARK: - Media Setup

    private func setupMediaTracks() {
        let streamId = "blurrr-stream"

        // Audio with echo cancellation
        let audioConstraints = RTCMediaConstraints(
            mandatoryConstraints: nil,
            optionalConstraints: ["echoCancellation": "true"]
        )
        let audioSource = WebRTCHandler.factory.audioSource(with: audioConstraints)
        let audioTrack = WebRTCHandler.factory.audioTrack(with: audioSource, trackId: "audio0")
        peerConnection.add(audioTrack, streamIds: [streamId])

        // Video
        let videoSource = WebRTCHandler.factory.videoSource()
        let capturer = RTCCameraVideoCapturer(delegate: videoSource)
        self.videoCapturer = capturer

        let videoTrack = WebRTCHandler.factory.videoTrack(with: videoSource, trackId: "video0")
        self.localVideoTrack = videoTrack
        peerConnection.add(videoTrack, streamIds: [streamId])

        // NOTE: remoteVideoTrack is nil here — set after setRemoteDescription
        // when transceivers are populated.
    }

    private func setupDataChannel() {
        let config = RTCDataChannelConfiguration()
        config.isOrdered = true
        guard let channel = peerConnection.dataChannel(forLabel: "BlurrrData", configuration: config) else {
            print("⚠️ Could not create data channel")
            return
        }
        channel.delegate = self
        self.localDataChannel = channel
    }

    private func configureAudioSession() {
        rtcAudioSession.lockForConfiguration()
        defer { rtcAudioSession.unlockForConfiguration() }
        do {
            try rtcAudioSession.setCategory(AVAudioSession.Category.playAndRecord.rawValue)
            try rtcAudioSession.setMode(AVAudioSession.Mode.voiceChat.rawValue)
            try rtcAudioSession.setActive(true)
        } catch {
            print("⚠️ AVAudioSession error: \(error)")
        }
    }

    // MARK: - Capture

    /// Starts the front camera and attaches it to the given renderer.
    func startLocalVideo(renderer: RTCVideoRenderer) {
        guard let capturer = videoCapturer else {
            print("⚠️ No video capturer available")
            return
        }
        guard let frontCamera = RTCCameraVideoCapturer.captureDevices()
            .first(where: { $0.position == .front }) else {
            print("⚠️ No front camera found")
            return
        }
        // Highest resolution format
        let formats = RTCCameraVideoCapturer.supportedFormats(for: frontCamera)
        guard let format = formats.sorted(by: {
            CMVideoFormatDescriptionGetDimensions($0.formatDescription).width <
            CMVideoFormatDescriptionGetDimensions($1.formatDescription).width
        }).last else {
            print("⚠️ No supported camera format found")
            return
        }
        // Highest FPS
        guard let fps = format.videoSupportedFrameRateRanges
            .sorted(by: { $0.maxFrameRate < $1.maxFrameRate })
            .last else {
            print("⚠️ No supported FPS found")
            return
        }

        capturer.startCapture(with: frontCamera, format: format, fps: Int(fps.maxFrameRate))
        localVideoTrack?.add(renderer)
    }

    func renderRemoteVideo(to renderer: RTCVideoRenderer) {
        remoteVideoTrack?.add(renderer)
    }

    // MARK: - Signaling

    func offer(completion: @escaping (RTCSessionDescription) -> Void) {
        let constraints = RTCMediaConstraints(mandatoryConstraints: mediaConstraints, optionalConstraints: nil)
        peerConnection.offer(for: constraints) { [weak self] sdp, error in
            guard let self, let sdp else {
                if let error { print("⚠️ Offer error: \(error)") }
                return
            }
            self.peerConnection.setLocalDescription(sdp) { error in
                if let error { print("⚠️ setLocalDescription error: \(error)") }
                completion(sdp)
            }
        }
    }

    func answer(completion: @escaping (RTCSessionDescription) -> Void) {
        let constraints = RTCMediaConstraints(mandatoryConstraints: mediaConstraints, optionalConstraints: nil)
        peerConnection.answer(for: constraints) { [weak self] sdp, error in
            guard let self, let sdp else {
                if let error { print("⚠️ Answer error: \(error)") }
                return
            }
            self.peerConnection.setLocalDescription(sdp) { error in
                if let error { print("⚠️ setLocalDescription error: \(error)") }
                completion(sdp)
            }
        }
    }

    func set(remoteSdp: RTCSessionDescription, completion: @escaping (Error?) -> Void) {
        peerConnection.setRemoteDescription(remoteSdp) { [weak self] error in
            guard let self else { return }
            if let error {
                print("⚠️ setRemoteDescription error: \(error)")
                completion(error)
                return
            }
            // Transceivers populated after remote SDP — safe to grab remote video track now
            self.remoteVideoTrack = self.peerConnection.transceivers
                .first(where: { $0.mediaType == .video })?
                .receiver.track as? RTCVideoTrack
            completion(nil)
        }
    }

    func set(remoteCandidate: RTCIceCandidate, completion: @escaping (Error?) -> Void) {
        peerConnection.add(remoteCandidate, completionHandler: completion)
    }

    // MARK: - Data Channel

    func sendData(_ data: Data) {
        let buffer = RTCDataBuffer(data: data, isBinary: true)
        remoteDataChannel?.sendData(buffer)
    }

    // MARK: - Media Toggle

    func setVideoEnabled(_ enabled: Bool) {
        localVideoTrack?.isEnabled = enabled
    }

    func setAudioEnabled(_ enabled: Bool) {
        peerConnection.transceivers
            .compactMap { $0.sender.track as? RTCAudioTrack }
            .forEach { $0.isEnabled = enabled }
    }

    // MARK: - Disconnect

    func disconnect() {
        videoCapturer?.stopCapture()
        videoCapturer = nil

        localDataChannel?.close()
        localDataChannel = nil
        remoteDataChannel?.close()
        remoteDataChannel = nil

        localVideoTrack = nil
        remoteVideoTrack = nil

        peerConnection.close()
        peerConnection = nil
    }
}

// MARK: - RTCPeerConnectionDelegate

extension WebRTCHandler: RTCPeerConnectionDelegate {

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        print("📡 Signaling state: \(stateChanged.rawValue)")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        print("📡 Stream added")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        print("📡 Stream removed")
    }

    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        print("📡 Negotiation needed")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        print("🧊 ICE connection state: \(newState.rawValue)")
        delegate?.webRTC(self, didChangeConnectionState: newState)
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        print("🧊 ICE gathering state: \(newState.rawValue)")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        delegate?.webRTC(self, didDiscoverLocalCandidate: candidate)
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        print("🧊 ICE candidates removed")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        print("📦 Remote data channel opened")
        dataChannel.delegate = self
        self.remoteDataChannel = dataChannel
    }
}

// MARK: - RTCDataChannelDelegate

extension WebRTCHandler: RTCDataChannelDelegate {
    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        print("📦 Data channel state: \(dataChannel.readyState.rawValue)")
    }

    func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        delegate?.webRTC(self, didReceiveData: buffer.data)
    }
}
