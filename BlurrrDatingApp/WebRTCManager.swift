import WebRTC
import Combine
import Foundation

class WebRTCManager: NSObject, ObservableObject {
    @Published var remoteVideoTrack: RTCVideoTrack?
    @Published var localVideoTrack: RTCVideoTrack?
    var peerConnectionFactory: RTCPeerConnectionFactory!
    var peerConnection: RTCPeerConnection?
    var localView: RTCMTLVideoView!
    var remoteView: RTCMTLVideoView!
    var videoCapture: RTCCameraVideoCapturer?
    
    let sessionID = "a-static-uuid-string" // Replace with a static UUID
    var webSocket: URLSessionWebSocketTask?
    var isOfferer = false // Determine if this client should create the offer
    
    override init() {
        super.init()
        peerConnectionFactory = RTCPeerConnectionFactory()
        setupViews()
        setupWebSocket()
    }
    
    func setupViews() {
        localView = RTCMTLVideoView()
        localView.videoContentMode = .scaleAspectFill
        
        remoteView = RTCMTLVideoView()
        remoteView.videoContentMode = .scaleAspectFill
    }
    
    func setupWebSocket() {
        let url = URL(string: "ws://blurrr-dating.com/socket")!
        webSocket = URLSession.shared.webSocketTask(with: url)
        webSocket?.resume()
        receiveWebSocketMessages()
    }
    
    func receiveWebSocketMessages() {
        print("receive")
        webSocket?.receive { [weak self] result in
            switch result {
            case .failure(let error):
                print("WebSocket error: \(error.localizedDescription)")
            case .success(let message):
                switch message {
                case .string(let text):
                    self?.handleWebSocketMessage(text)
                case .data(_):
                    break
                @unknown default:
                    break
                }
            }
            self?.receiveWebSocketMessages() // Listen for next message
        }
    }
    
    func handleWebSocketMessage(_ message: String) {
        guard let data = message.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data, options: []),
              let dictionary = json as? [String: Any] else {
            return
        }
        
        DispatchQueue.main.async {
            if let offer = dictionary["offer"] as? String {
                let sdp = RTCSessionDescription(type: .offer, sdp: offer)
                self.handleRemoteDescription(sdp)
            } else if let answer = dictionary["answer"] as? String {
                let sdp = RTCSessionDescription(type: .answer, sdp: answer)
                self.peerConnection?.setRemoteDescription(sdp, completionHandler: { error in
                    if let error = error {
                        print("Error setting remote description for answer: \(error.localizedDescription)")
                    }
                })
            } else if let candidate = dictionary["candidate"] as? String {
                let candidate = RTCIceCandidate(sdp: candidate, sdpMLineIndex: 0, sdpMid: nil)
                self.peerConnection?.add(candidate)
            } else if let role = dictionary["role"] as? String {
                self.isOfferer = (role == "offerer")
                self.startConnection()
            }
        }
    }
    
    func startConnection() {
        let configuration = RTCConfiguration()
        configuration.iceServers = [RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])]
        print("Contacting Google STUN server")
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        peerConnection = peerConnectionFactory.peerConnection(with: configuration, constraints: constraints, delegate: self)
        
        setupLocalStream()
        
        if isOfferer {
            createOffer()
        }
    }
    
    func setupLocalStream() {
        let audioTrack = peerConnectionFactory.audioTrack(withTrackId: "audio0")
        let videoSource = peerConnectionFactory.videoSource()
        
        videoCapture = RTCCameraVideoCapturer(delegate: videoSource)
        
        guard let camera = (RTCCameraVideoCapturer.captureDevices().first { $0.position == .front }),
              let format = RTCCameraVideoCapturer.supportedFormats(for: camera).first else { return }
        
        let fps = format.videoSupportedFrameRateRanges.first?.maxFrameRate ?? 30
        videoCapture?.startCapture(with: camera, format: format, fps: Int(fps))
        
        localVideoTrack = peerConnectionFactory.videoTrack(with: videoSource, trackId: "video0")
        localVideoTrack?.add(localView)
        
        peerConnection?.add(audioTrack, streamIds: ["stream0"])
        peerConnection?.add(localVideoTrack!, streamIds: ["stream0"])
    }
    
    func createOffer() {
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        peerConnection?.offer(for: constraints) { [weak self] (sdp, error) in
            guard let sdp = sdp else { return }
            self?.peerConnection?.setLocalDescription(sdp, completionHandler: { (error) in
                if let error = error {
                    print("Error setting local description for offer: \(error.localizedDescription)")
                    return
                }
                print("Offer created: \(sdp.sdp)")
                self?.sendWebSocketMessage(["offer": sdp.sdp])
            })
        }
    }
    
    func createAnswer() {
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        peerConnection?.answer(for: constraints) { [weak self] (sdp, error) in
            guard let sdp = sdp else { return }
            self?.peerConnection?.setLocalDescription(sdp, completionHandler: { (error) in
                if let error = error {
                    print("Error setting local description for answer: \(error.localizedDescription)")
                    return
                }
                print("Answer created: \(sdp.sdp)")
                self?.sendWebSocketMessage(["answer": sdp.sdp])
            })
        }
    }
    
    func handleRemoteDescription(_ sdp: RTCSessionDescription) {
        peerConnection?.setRemoteDescription(sdp, completionHandler: { (error) in
            if let error = error {
                print("Error setting remote description: \(error.localizedDescription)")
                return
            }
            print("Remote description set: \(sdp.sdp)")
            if sdp.type == .offer {
                self.createAnswer()
            }
        })
    }
    
    func handleRemoteIceCandidate(_ candidate: RTCIceCandidate) {
        peerConnection?.add(candidate)
        print("Remote ICE candidate added: \(candidate.sdp)")
    }
    
    func sendWebSocketMessage(_ message: [String: Any]) {
        guard let webSocket = webSocket else { return }
        let data = try? JSONSerialization.data(withJSONObject: message, options: [])
        let string = String(data: data!, encoding: .utf8)!
        webSocket.send(.string(string)) { error in
            if let error = error {
                print("WebSocket send error: \(error.localizedDescription)")
            }
        }
    }
    
    func sendCandidate(_ candidate: RTCIceCandidate) {
        sendWebSocketMessage(["candidate": candidate.sdp])
    }
}

extension WebRTCManager: RTCPeerConnectionDelegate {
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        print("Renegotiation needed")
        // Handle renegotiation here if necessary
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        print("ICE candidates removed: \(candidates)")
        // Handle the removal of ICE candidates if necessary
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        print("Signaling state changed: \(stateChanged)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        DispatchQueue.main.async {
            if let track = stream.videoTracks.first {
                self.remoteVideoTrack = track
                self.remoteVideoTrack?.add(self.remoteView)
            }
            print("Remote stream added")
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        DispatchQueue.main.async {
            self.remoteVideoTrack = nil
        }
        print("Remote stream removed")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        print("ICE connection state changed: \(newState)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        self.sendCandidate(candidate)
        print("ICE candidate generated: \(candidate)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        print("ICE gathering state changed: \(newState)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        print("Data channel opened: \(dataChannel)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove dataChannel: RTCDataChannel) {
        print("Data channel removed: \(dataChannel)")
    }
}
