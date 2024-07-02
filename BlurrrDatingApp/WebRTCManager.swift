import Foundation
import Starscream

class WebSocketManager: NSObject {
    static let shared = WebSocketManager()
    
    var socket: WebSocket!
    
    override init() {
        super.init()
        let url = URL(string: "wss://blurrr-dating.com/socket")!
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        socket = WebSocket(request: request)
        socket.delegate = self
        socket.connect()
    }
    
    func send(message: String) {
        socket.write(string: message)
    }
}

extension WebSocketManager: WebSocketDelegate {
    func didReceive(event: Starscream.WebSocketEvent, client: any Starscream.WebSocketClient) {
        switch event {
        case .connected(let headers):
            print("WebSocket is connected:", headers)
            
        case .disconnected(let reason, let code):
            print("WebSocket is disconnected:", reason, code)
            
        case .text(let string):
            print("Received text:", string)
            // Handle received text message
            
        case .binary(let data):
            print("Received data:", data)
            // Handle received binary data
            
        case .pong:
            print("WebSocket received pong")
            
        case .ping:
            print("WebSocket received ping")
            
        case .error(let error):
            print("WebSocket encountered an error:", error)
            
        case .viabilityChanged(let isViable):
            print("WebSocket viability changed:", isViable)
            // Handle viability change if needed
            
        case .reconnectSuggested(let shouldReconnect):
            print("WebSocket suggests reconnect:", shouldReconnect)
            // Handle reconnect suggestion if needed
            
        case .cancelled:
            print("WebSocket connection cancelled")
            // Handle cancellation if needed
            
        case .peerClosed:
            print("I genuinely hate my life and want to dier")
            // Handle peer closed connection if needed
        }
    }
    
    func websocketDidConnect(socket: WebSocketClient) {
        print("WebSocket connected")
    }
    
    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        print("WebSocket disconnected")
    }
    
    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        print("Received message: \(text)")
        // Handle received message here
    }
    
    func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        print("Received data: \(data)")
    }
}
