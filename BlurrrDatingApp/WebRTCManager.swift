import WebRTC
import Combine

class WebRTCManager: NSObject, ObservableObject {
    @Published var remoteVideoTrack: RTCVideoTrack?
    @Published var localVideoTrack: RTCVideoTrack?
    var peerConnectionFactory: RTCPeerConnectionFactory!
    var peerConnection: RTCPeerConnection?
    var localView: RTCMTLVideoView!
    var remoteView: RTCMTLVideoView!
    var videoCapture: RTCCameraVideoCapturer?

    let sessionID = "a-static-uuid-string" // Replace with a static UUID

    override init() {
        super.init()
        peerConnectionFactory = RTCPeerConnectionFactory()
        setupViews()
    }
    
    func setupViews() {
        localView = RTCMTLVideoView()
        localView.videoContentMode = .scaleAspectFill
        
        remoteView = RTCMTLVideoView()
        remoteView.videoContentMode = .scaleAspectFill
    }
    
    func startConnection() {
        let configuration = RTCConfiguration()
        configuration.iceServers = [RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])]
        
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        peerConnection = peerConnectionFactory.peerConnection(with: configuration, constraints: constraints, delegate: self)
        
        setupLocalStream()
        createOffer()
        pollForAnswer()
        pollForCandidates()
    }
    
    func setupLocalStream() {
        let audioTrack = peerConnectionFactory.audioTrack(withTrackId: "audio0")
        let videoSource = peerConnectionFactory.videoSource()
        
        videoCapture = RTCCameraVideoCapturer(delegate: videoSource)
        
        guard let camera = (RTCCameraVideoCapturer.captureDevices().first { $0.position == .front }),
              let format = RTCCameraVideoCapturer.supportedFormats(for: camera).first else {
            print("Error: Could not find camera or supported format")
            return
        }
        
        let fps = format.videoSupportedFrameRateRanges.first?.maxFrameRate ?? 30
        videoCapture?.startCapture(with: camera, format: format, fps: Int(fps))
        
        localVideoTrack = peerConnectionFactory.videoTrack(with: videoSource, trackId: "video0")
        localVideoTrack?.add(localView)
        
        peerConnection?.add(audioTrack, streamIds: ["stream0"])
        peerConnection?.add(localVideoTrack!, streamIds: ["stream0"])
        
        print("Local stream setup complete")
    }
    
    func createOffer() {
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        peerConnection?.offer(for: constraints) { [weak self] (sdp, error) in
            if let error = error {
                print("Error creating offer: \(error.localizedDescription)")
                return
            }
            guard let sdp = sdp else { return }
            self?.peerConnection?.setLocalDescription(sdp, completionHandler: { (error) in
                if let error = error {
                    print("Error setting local description: \(error.localizedDescription)")
                    return
                }
                self?.sendOffer(sdp)
            })
        }
    }
    
    func createAnswer() {
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        peerConnection?.answer(for: constraints) { [weak self] (sdp, error) in
            if let error = error {
                print("Error creating answer: \(error.localizedDescription)")
                return
            }
            guard let sdp = sdp else { return }
            self?.peerConnection?.setLocalDescription(sdp, completionHandler: { (error) in
                if let error = error {
                    print("Error setting local description: \(error.localizedDescription)")
                    return
                }
                self?.sendAnswer(sdp)
            })
        }
    }
    
    func handleRemoteDescription(_ sdp: RTCSessionDescription) {
        peerConnection?.setRemoteDescription(sdp, completionHandler: { (error) in
            if let error = error {
                print("Error setting remote description: \(error.localizedDescription)")
                return
            }
            if sdp.type == .offer {
                self.createAnswer()
            }
        })
    }
    
    func handleRemoteIceCandidate(_ candidate: RTCIceCandidate) {
        peerConnection?.add(candidate)
    }
    
    func sendOffer(_ sdp: RTCSessionDescription) {
        guard let url = URL(string: "https://blurrr-dating.com/offer") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["session_id": sessionID, "offer": sdp.sdp]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("Error sending offer: \(error.localizedDescription)")
                return
            }
            print("Offer sent successfully")
        }.resume()
    }
    
    func sendAnswer(_ sdp: RTCSessionDescription) {
        guard let url = URL(string: "https://blurrr-dating.com/answer") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["session_id": sessionID, "answer": sdp.sdp]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("Error sending answer: \(error.localizedDescription)")
                return
            }
            print("Answer sent successfully")
        }.resume()
    }
    
    func sendCandidate(_ candidate: RTCIceCandidate) {
        guard let url = URL(string: "https://blurrr-dating.com/candidate") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["session_id": sessionID, "candidate": candidate.sdp]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("Error sending candidate: \(error.localizedDescription)")
                return
            }
            print("Candidate sent successfully")
        }.resume()
    }
    
    func pollForOffer() {
        guard let url = URL(string: "https://blurrr-dating.com/get_offer?session_id=\(sessionID)") else { return }
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                print("Error polling for offer: \(error.localizedDescription)")
                return
            }
            guard let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: []), let dictionary = json as? [String: Any], let sdpString = dictionary["offer"] as? String else {
                print("No offer found")
                return
            }
            
            let sdp = RTCSessionDescription(type: .offer, sdp: sdpString)
            self.handleRemoteDescription(sdp)
        }.resume()
    }
    
    func pollForAnswer() {
        guard let url = URL(string: "https://blurrr-dating.com/get_answer?session_id=\(sessionID)") else { return }
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                print("Error polling for answer: \(error.localizedDescription)")
                return
            }
            guard let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: []), let dictionary = json as? [String: Any], let sdpString = dictionary["answer"] as? String else {
                print("No answer found")
                return
            }
            
            let sdp = RTCSessionDescription(type: .answer, sdp: sdpString)
            self.peerConnection?.setRemoteDescription(sdp, completionHandler: { (error) in
                if let error = error {
                    print("Error setting remote description for answer: \(error.localizedDescription)")
                }
            })
        }.resume()
    }
    
    func pollForCandidates() {
        guard let url = URL(string: "https://blurrr-dating.com/get_candidates?session_id=\(sessionID)") else { return }
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                print("Error polling for candidates: \(error.localizedDescription)")
                return
            }
            guard let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: []), let dictionary = json as? [String: Any], let candidatesArray = dictionary["candidates"] as? [[String: Any]] else {
                print("No candidates found")
                return
            }
            
            for candidateDict in candidatesArray {
                if let candidateString = candidateDict["candidate"] as? String {
                    let candidate = RTCIceCandidate(sdp: candidateString, sdpMLineIndex: 0, sdpMid: nil)
                    self.peerConnection?.add(candidate)
                    print("ICE candidate added: \(candidate)")
                }
            }
        }.resume()
    }
}

extension WebRTCManager: RTCPeerConnectionDelegate {
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        print("Renegotiation needed")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        print("ICE candidates removed: \(candidates)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        print("Signaling state changed: \(stateChanged.rawValue)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        if let track = stream.videoTracks.first {
            self.remoteVideoTrack = track
            DispatchQueue.main.async {
                self.remoteVideoTrack?.add(self.remoteView)
            }
            print("Remote stream added")
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        self.remoteVideoTrack = nil
        print("Remote stream removed")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        print("ICE connection state changed: \(newState.rawValue)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        self.sendCandidate(candidate)
        print("ICE candidate generated: \(candidate)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        print("ICE gathering state changed: \(newState.rawValue)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        print("Data channel opened: \(dataChannel)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove dataChannel: RTCDataChannel) {
        print("Data channel removed: \(dataChannel)")
    }
}
