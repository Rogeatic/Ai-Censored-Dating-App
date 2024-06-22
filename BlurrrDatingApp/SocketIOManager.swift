import Foundation
import SocketIO

class SocketIOManager: ObservableObject {
    private var manager: SocketManager
    private var socket: SocketIOClient
    @Published var roomID: String = ""

    init() {
        let socketURL = URL(string: "http://146.190.132.105:8000")! // Update server IP and port
        manager = SocketManager(socketURL: socketURL, config: [.log(true), .compress])
        socket = manager.defaultSocket

        socket.on(clientEvent: .connect) { data, ack in
            print("Socket connected")
        }

        socket.on("room_created") { data, ack in
            if let response = data[0] as? [String: Any], let roomID = response["room_id"] as? String {
                DispatchQueue.main.async {
                    self.roomID = roomID
                    NotificationCenter.default.post(name: .roomCreated, object: nil, userInfo: response)
                }
            }
        }

        socket.connect()
    }

    func joinRoom(userID: String, completion: @escaping ([String: Any]) -> Void) {
        guard let url = URL(string: "http://146.190.132.105:8000/join") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let parameters: [String: String] = ["user_id": userID]
        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)

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
                        }
                        completion(responseJSON)
                    }
                }
            }
        }.resume()
    }
}

extension Notification.Name {
    static let roomCreated = Notification.Name("roomCreated")
}
