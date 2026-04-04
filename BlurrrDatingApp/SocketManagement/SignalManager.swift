import Foundation
import WebRTC

// MARK: - Protocol

protocol SignalManager: AnyObject {
    func signalClientDidConnect(_ signalingHandler: SignalingHandler)
    func signalClientDidDisconnect(_ signalingHandler: SignalingHandler)
    func signalClient(_ signalingHandler: SignalingHandler, didReceiveRemoteSdp sdp: RTCSessionDescription)
    func signalClient(_ signalingHandler: SignalingHandler, didReceiveCandidate candidate: RTCIceCandidate)
}

// MARK: - SignalingHandler

final class SignalingHandler {
    private let webSocket: WebSocketHandler
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    // Use weak to avoid retain cycles with SwiftUI views
    weak var delegate: SignalManager?

    private var isIntentionalDisconnect = false

    init(webSocket: WebSocketHandler) {
        self.webSocket = webSocket
    }

    func connect() {
        isIntentionalDisconnect = false
        webSocket.delegate = self
        webSocket.connect()
    }

    func disconnect() {
        isIntentionalDisconnect = true
        webSocket.disconnect()
    }

    func send(sdp rtcSdp: RTCSessionDescription) {
        encode(message: .sdp(SessionDescription(from: rtcSdp)))
    }

    func send(candidate rtcIceCandidate: RTCIceCandidate) {
        encode(message: .candidate(IceCandidate(from: rtcIceCandidate)))
    }

    private func encode(message: Message) {
        do {
            let data = try encoder.encode(message)
            webSocket.send(data: data)
        } catch {
            print("⚠️ Could not encode message: \(error)")
        }
    }
}

// MARK: - WebSocketManager

extension SignalingHandler: WebSocketManager {

    func webSocketDidConnect(_ webSocket: WebSocketHandler) {
        print("🔌 Signaling connected")
        delegate?.signalClientDidConnect(self)
    }

    func webSocketDidDisconnect(_ webSocket: WebSocketHandler) {
        print("🔌 Signaling disconnected")
        delegate?.signalClientDidDisconnect(self)

        // Only auto-reconnect if the disconnect was unintentional
        guard !isIntentionalDisconnect else { return }
        DispatchQueue.global().asyncAfter(deadline: .now() + 2) { [weak self] in
            guard let self, !self.isIntentionalDisconnect else { return }
            print("🔌 Reconnecting to signaling server...")
            self.webSocket.connect()
        }
    }

    func webSocket(_ webSocket: WebSocketHandler, didReceiveData data: Data) {
        do {
            let message = try decoder.decode(Message.self, from: data)
            switch message {
            case .sdp(let sd):
                delegate?.signalClient(self, didReceiveRemoteSdp: sd.rtcSessionDescription)
            case .candidate(let ic):
                delegate?.signalClient(self, didReceiveCandidate: ic.rtcIceCandidate)
            }
        } catch {
            print("⚠️ Could not decode message: \(error)")
        }
    }
}
