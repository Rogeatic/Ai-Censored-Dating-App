import SwiftUI
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

        socket.connect()
    }

    func joinRoom(userID: String, completion: @escaping () -> Void) {
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
                            completion()
                        }
                    }
                }
            }
        }.resume()
    }
}
