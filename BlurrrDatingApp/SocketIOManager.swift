import Foundation
import SocketIO

class SocketIOManager: ObservableObject {
    static let shared = SocketIOManager()
    
    private let manager = SocketManager(socketURL: URL(string: "http://146.190.132.105:8000")!, config: [.log(true), .compress])
    private(set) var socket: SocketIOClient!
    
    @Published var roomID: String = ""
    @Published var roomToken: String = ""
    
    init() {
        socket = manager.defaultSocket
        
        socket.on(clientEvent: .connect) {data, ack in
            print("Socket connected")
        }
        
        socket.on(clientEvent: .disconnect) {data, ack in
            print("Socket disconnected")
        }
        
        socket.on("room_ready") { [weak self] data, ack in
            guard let self = self else { return }
            if let roomData = data[0] as? [String: Any] {
                self.roomID = roomData["room_id"] as? String ?? ""
                self.roomToken = roomData["room_token"] as? String ?? ""
            }
        }
    }
    
    func establishConnection() {
        socket.connect()
    }
    
    func closeConnection() {
        socket.disconnect()
    }
    
    func joinRoom(completion: @escaping () -> Void) {
        let userID = UUID().uuidString // Replace with actual user ID if available
        let joinData: [String: Any] = ["user_id": userID]
        
        socket.emit("join", joinData)
        socket.on("room_ready") { [weak self] data, ack in
            guard let self = self else { return }
            if let roomData = data[0] as? [String: Any] {
                self.roomID = roomData["room_id"] as? String ?? ""
                self.roomToken = roomData["room_token"] as? String ?? ""
                completion()
            }
        }
    }
    
    func sendOffer(offer: [String: Any]) {
        socket.emit("offer", offer)
    }
    
    func sendAnswer(answer: [String: Any]) {
        socket.emit("answer", answer)
    }
    
    func sendIceCandidate(candidate: [String: Any]) {
        socket.emit("ice-candidate", candidate)
    }
}
