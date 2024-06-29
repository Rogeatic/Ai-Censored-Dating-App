import Foundation
import SocketIO

class SocketIOManager: ObservableObject {
    private var manager: SocketManager
    private var socket: SocketIOClient
    @Published var roomID: String = ""

    init() {
        let socketURL = URL(string: "http://146.190.132.105:8000")! // Update to your socket server URL
        manager = SocketManager(socketURL: socketURL, config: [.log(true), .compress])
        socket = manager.defaultSocket

        socket.on(clientEvent: .connect) { data, ack in
            print("Socket connected")
        }

        socket.on("room_ready") { data, ack in
            print("Received room_ready event")
            if let response = data[0] as? [String: Any], let roomID = response["room_id"] as? String {
                DispatchQueue.main.async {
                    self.roomID = roomID
                }
            }
        }

        socket.connect()
    }

    func requestRoomID() {
        // Request a new room ID from your Jitsi server
        guard let url = URL(string: "http://64.23.140.158/requestRoomID") else { return } // Update with your Jitsi server endpoint
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Error: \(error?.localizedDescription ?? "No data")")
                return
            }
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                if let responseJSON = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    DispatchQueue.main.async {
                        if let roomID = responseJSON["room_id"] as? String {
                            self.roomID = roomID
                            self.socket.emit("join", ["room_id": roomID])
                        }
                    }
                }
            }
        }.resume()
    }
}
