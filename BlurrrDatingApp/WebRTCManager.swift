import Foundation
import WebRTC

class WebRTCManager: NSObject, ObservableObject {
    static let shared = WebRTCManager()
    
    private var peerConnectionFactory: RTCPeerConnectionFactory
    private var peerConnection: RTCPeerConnection?
    private var localStream: RTCMediaStream?
    
    override init() {
        RTCInitializeSSL()
        let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
        let videoDecoderFactory = RTCDefaultVideoDecoderFactory()
        peerConnectionFactory = RTCPeerConnectionFactory(encoderFactory: videoEncoderFactory, decoderFactory: videoDecoderFactory)
        super.init()
    }
    
    func setupPeerConnection() {
        let configuration = RTCConfiguration()
        configuration.iceServers = [RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])]
        peerConnection = peerConnectionFactory.peerConnection(with: configuration, constraints: RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil), delegate: self)
        
        // Add local stream to peer connection
        if let localStream = self.localStream {
            peerConnection?.add(localStream)
        } else {
            // Handle local stream setup
            self.setupLocalStream()
        }
    }
    
    private func setupLocalStream() {
        let audioTrack = self.peerConnectionFactory.audioTrack(withTrackId: "audio0")
        let videoSource = self.peerConnectionFactory.videoSource()
        let videoTrack = self.peerConnectionFactory.videoTrack(with: videoSource, trackId: "video0")
        
        self.localStream = self.peerConnectionFactory.mediaStream(withStreamId: "localStream")
        self.localStream?.addAudioTrack(audioTrack)
        self.localStream?.addVideoTrack(videoTrack)
        
        if let localStream = self.localStream {
            self.peerConnection?.add(localStream)
        }
    }
    
    func createOffer() {
        let offerConstraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        peerConnection?.offer(for: offerConstraints) { (sessionDescription, error) in
            guard let sdp = sessionDescription else {
                print("Failed to create offer: \(String(describing: error))")
                return
            }
            self.peerConnection?.setLocalDescription(sdp, completionHandler: { error in
                if let error = error {
                    print("Failed to set local description: \(error)")
                }
            })
        }
    }
    
    func handleOffer(offerData: [String: Any]) {
        guard let sdp = offerData["sdp"] as? String,
              let typeString = offerData["type"] as? String,
              let type = self.sdpType(from: typeString) else {
            print("Invalid SDP offer data")
            return
        }
        
        let sessionDescription = RTCSessionDescription(type: type, sdp: sdp)
        peerConnection?.setRemoteDescription(sessionDescription, completionHandler: { error in
            if let error = error {
                print("Failed to set remote description: \(error)")
            } else {
                self.createAnswer()
            }
        })
    }
    
    private func createAnswer() {
        let answerConstraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        peerConnection?.answer(for: answerConstraints) { (sessionDescription, error) in
            guard let sdp = sessionDescription else {
                print("Failed to create answer: \(String(describing: error))")
                return
            }
            self.peerConnection?.setLocalDescription(sdp, completionHandler: { error in
                if let error = error {
                    print("Failed to set local description: \(error)")
                }
            })
        }
    }
    
    private func sdpType(from string: String) -> RTCSdpType? {
        switch string {
        case "offer":
            return .offer
        case "pranswer":
            return .prAnswer
        case "answer":
            return .answer
        default:
            return nil
        }
    }
    
    func endCall() {
        peerConnection?.close()
        peerConnection = nil
        localStream = nil
    }
    func joinRoom(roomID: String, roomToken: String) {
        guard let url = URL(string: "http://146.190.132.105:8000/join") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let json: [String: Any] = ["room_id": roomID, "room_token": roomToken]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Failed to join room: \(error?.localizedDescription ?? "No error description")")
                return
            }
            
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let sdp = jsonResponse["sdp"] as? String, let type = jsonResponse["type"] as? String {
                        let sessionDescription = RTCSessionDescription(type: self.sdpType(from: type) ?? .offer, sdp: sdp)
                        self.peerConnection?.setRemoteDescription(sessionDescription, completionHandler: { error in
                            if let error = error {
                                print("Failed to set remote description: \(error.localizedDescription)")
                            } else {
                                print("Remote description set successfully.")
                            }
                        })
                    }
                }
            } catch let error {
                print("Failed to parse response: \(error.localizedDescription)")
            }
        }
        
        task.resume()
    }
    func localVideoView() -> UIView {
        let videoTrack = localStream?.videoTracks.first
        let videoView = RTCEAGLVideoView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        
        videoTrack?.add(videoView)
        
        return videoView
    }
    
    func metalVideoView() -> UIView {
            let videoTrack = localStream?.videoTracks.first
            let videoView = RTCMTLVideoView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))

            videoTrack?.add(videoView)

            return videoView
        }

        func eaglVideoView() -> UIView {
            let videoTrack = localStream?.videoTracks.first
            let videoView = RTCEAGLVideoView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))

            videoTrack?.add(videoView)

            return videoView
        }
}

extension WebRTCManager: RTCPeerConnectionDelegate {
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        // Handle state changes
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        // Handle new stream added
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        // Handle stream removed
    }
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        // Handle renegotiation needed
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newConnectionState: RTCIceConnectionState) {
        // Handle connection state changes
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newGatheringState: RTCIceGatheringState) {
        // Handle gathering state changes
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        // Handle new ICE candidate
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        // Handle removed ICE candidates
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        // Handle new data channel opened
    }
}
