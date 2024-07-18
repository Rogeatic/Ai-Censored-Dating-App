import Foundation
import Starscream

protocol WebSocketHandler: AnyObject {
    var delegate: WebSocketManager? { get set }
    func connect()
    func disconnect()
    func send(data: Data)
}

protocol WebSocketManager: AnyObject {
    func webSocketDidConnect(_ webSocket: WebSocketHandler)
    func webSocketDidDisconnect(_ webSocket: WebSocketHandler)
    func webSocket(_ webSocket: WebSocketHandler, didReceiveData data: Data)
}


class StarscreamWebSocket: WebSocketHandler {

    var delegate: WebSocketManager?
    private let socket: WebSocket
    
    init(url: URL) {
        self.socket = WebSocket(request: URLRequest(url: url))
        self.socket.delegate = self
    }
    
    func connect() {
        self.socket.connect()
    }
    func disconnect() {
        self.socket.disconnect()
    }
    
    func send(data: Data) {
        self.socket.write(data: data)
    }
}

extension StarscreamWebSocket: Starscream.WebSocketDelegate {
    
    func didReceive(event: Starscream.WebSocketEvent, client: Starscream.WebSocket) {
        switch event {
        case .connected:
            self.delegate?.webSocketDidConnect(self)
        case .disconnected:
            self.delegate?.webSocketDidDisconnect(self)
        case .text:
            debugPrint("Warning: Expected to receive data format but received a string. Check the websocket server config.")
        case .binary(let data):
            self.delegate?.webSocket(self, didReceiveData: data)
        default:
            break
        }
    }
}
