import Foundation
import WebRTC

class WebRTCClient: NSObject, ObservableObject {
    private var peerConnectionFactory: RTCPeerConnectionFactory!
    private var peerConnection: RTCPeerConnection!
    private var localVideoTrack: RTCVideoTrack?
    private var remoteVideoTrack: RTCVideoTrack?
    var webSocketManager: WebSocketManager!

    override init() {
        super.init()
        setup()
        webSocketManager = WebSocketManager(url: "wss://your-server-url")
        webSocketManager.webRTCClient = self
        webSocketManager.connect()
    }

    private func setup() {
        let config = RTCConfiguration()
        config.sdpSemantics = .unifiedPlan

        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: ["DtlsSrtpKeyAgreement": "true"])
        peerConnectionFactory = RTCPeerConnectionFactory()
        peerConnection = peerConnectionFactory.peerConnection(with: config, constraints: constraints, delegate: self)
    }

    func createLocalVideoTrack() -> RTCVideoTrack {
        let videoSource = peerConnectionFactory.videoSource()
        localVideoTrack = peerConnectionFactory.videoTrack(with: videoSource, trackId: "localVideoTrack")
        return localVideoTrack!
    }

    func startConnection() {
        let offerConstraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        peerConnection.offer(for: offerConstraints) { [weak self] sdp, error in
            guard let self = self else { return }
            guard let sdp = sdp else { return }
            self.peerConnection.setLocalDescription(sdp, completionHandler: { error in
                // Handle error if needed
            })
            self.webSocketManager.send(data: ["type": "offer", "sdp": sdp.sdp])
        }
    }

    func handleRemoteDescription(type: String, sdp: String) {
        let sdpType = type == "offer" ? RTCSdpType.offer : RTCSdpType.answer
        let sessionDescription = RTCSessionDescription(type: sdpType, sdp: sdp)
        peerConnection.setRemoteDescription(sessionDescription, completionHandler: { error in
            // Handle error if needed
        })
    }

    func addIceCandidate(candidate: String, sdpMLineIndex: Int32, sdpMid: String?) {
        let iceCandidate = RTCIceCandidate(sdp: candidate, sdpMLineIndex: sdpMLineIndex, sdpMid: sdpMid)
        peerConnection.add(iceCandidate)
    }

    func endConnection() {
        peerConnection.close()
        webSocketManager.disconnect()
    }
}

extension WebRTCClient: RTCPeerConnectionDelegate {
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        print("Signaling state changed: \(stateChanged)")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        if let videoTrack = stream.videoTracks.first {
            remoteVideoTrack = videoTrack
            // Handle remote video track (e.g., attach to a view)
        }
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        // Handle stream removal if necessary
    }

    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        // Handle renegotiation if necessary
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        print("ICE connection state changed: \(newState)")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        print("ICE gathering state changed: \(newState)")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        let candidateString = candidate.sdp
        webSocketManager.send(data: ["type": "candidate", "candidate": candidateString, "sdpMLineIndex": candidate.sdpMLineIndex, "sdpMid": candidate.sdpMid])
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        // Handle removed candidates if necessary
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        // Handle data channel opening if necessary
    }
}
