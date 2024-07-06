import Foundation
import WebRTC

protocol SignalManager: AnyObject {
    func signalClientDidConnect(_ signalingHandler: SignalingHandler)
    func signalClientDidDisconnect(_ signalingHandler: SignalingHandler)
    func signalClient(_ signalingHandler: SignalingHandler, didReceiveRemoteSdp sdp: RTCSessionDescription)
    func signalClient(_ signalingHandler: SignalingHandler, didReceiveCandidate candidate: RTCIceCandidate)
}

final class SignalingHandler {
    private let webSocket: WebSocketHandler
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    weak var delegate: SignalManager?
    
    init(webSocket: WebSocketHandler) {
        self.webSocket = webSocket
    }
    
    func connect() {
        self.webSocket.delegate = self
        self.webSocket.connect()
    }
    
    func send(sdp rtcSdp: RTCSessionDescription) {
        let message = Message.sdp(SessionDescription(from: rtcSdp))
        do {
            let dataMessage = try self.encoder.encode(message)
            
            self.webSocket.send(data: dataMessage)
        }
        catch {
            debugPrint("Warning: Could not encode sdp: \(error)")
        }
    }
    
    func send(candidate rtcIceCandidate: RTCIceCandidate) {
        let message = Message.candidate(IceCandidate(from: rtcIceCandidate))
        do {
            let dataMessage = try self.encoder.encode(message)
            self.webSocket.send(data: dataMessage)
        }
        catch {
            debugPrint("Warning: Could not encode candidate: \(error)")
        }
    }
}


extension SignalingHandler: WebSocketManager {
    func webSocketDidConnect(_ webSocket: WebSocketHandler) {
        self.delegate?.signalClientDidConnect(self)
    }
    
    func webSocketDidDisconnect(_ webSocket: WebSocketHandler) {
        self.delegate?.signalClientDidDisconnect(self)
        
        // try to reconnect every two seconds
        DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
            debugPrint("Trying to reconnect to signaling server...")
            self.webSocket.connect()
        }
    }
    
    func webSocket(_ webSocket: WebSocketHandler, didReceiveData data: Data) {
        let message: Message
        do {
            message = try self.decoder.decode(Message.self, from: data)
        }
        catch {
            debugPrint("Warning: Could not decode incoming message: \(error)")
            return
        }
        
        switch message {
        case .candidate(let iceCandidate):
            self.delegate?.signalClient(self, didReceiveCandidate: iceCandidate.rtcIceCandidate)
        case .sdp(let sessionDescription):
            self.delegate?.signalClient(self, didReceiveRemoteSdp: sessionDescription.rtcSessionDescription)
        }

    }
}
