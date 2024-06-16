import Foundation
import Starscream

class WebSocketManager: WebSocketDelegate {
    func didReceive(event: Starscream.WebSocketEvent, client: any Starscream.WebSocketClient) {
        
    }
    
    private var socket: WebSocket!
    weak var webRTCClient: WebRTCClient?

    init(url: String) {
        var request = URLRequest(url: URL(string: url)!)
        request.timeoutInterval = 5
        socket = WebSocket(request: request)
        socket.delegate = self
    }

    func connect() {
        socket.connect()
    }

    func disconnect() {
        socket.disconnect()
    }

    func send(data: [String: Any]) {
        if let jsonData = try? JSONSerialization.data(withJSONObject: data, options: []) {
            socket.write(data: jsonData)
        }
    }

    func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .connected(let headers):
            print("WebSocket connected: \(headers)")
        case .disconnected(let reason, let code):
            print("WebSocket disconnected: \(reason) with code: \(code)")
        case .text(let string):
            print("Received text: \(string)")
            // Handle received messages (e.g., SDP, ICE candidates)
            if let data = string.data(using: .utf8) {
                if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let type = json["type"] as? String {
                        switch type {
                        case "offer", "answer":
                            if let sdp = json["sdp"] as? String {
                                webRTCClient?.handleRemoteDescription(type: type, sdp: sdp)
                            }
                        case "candidate":
                            if let candidate = json["candidate"] as? String,
                               let sdpMLineIndex = json["sdpMLineIndex"] as? Int32,
                               let sdpMid = json["sdpMid"] as? String {
                                webRTCClient?.addIceCandidate(candidate: candidate, sdpMLineIndex: sdpMLineIndex, sdpMid: sdpMid)
                            }
                        default:
                            break
                        }
                    }
                }
            }
        case .binary(let data):
            print("Received data: \(data)")
        case .ping(_):
            print("WebSocket ping")
        case .pong(_):
            print("WebSocket pong")
        case .viabilityChanged(let isViable):
            print("WebSocket viability changed: \(isViable)")
        case .reconnectSuggested(let shouldReconnect):
            print("WebSocket reconnect suggested: \(shouldReconnect)")
        case .cancelled:
            print("WebSocket cancelled")
        case .error(let error):
            print("WebSocket error: \(String(describing: error))")
        case .peerClosed:
            print("WebSocket peer closed")
        }
    }
}
