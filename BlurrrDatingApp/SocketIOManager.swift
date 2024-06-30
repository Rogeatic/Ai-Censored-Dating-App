//import Foundation
//import SocketIO
//
//class SocketIOManager: ObservableObject {
//    private var manager: SocketManager
//    private var socket: SocketIOClient
//    @Published var roomID: String = ""
//
//    init() {
//        let socketURL = URL(string: "https://blurrr-dating.com")!
//        manager = SocketManager(socketURL: socketURL, config: [.log(true), .compress, .secure(true), .selfSigned(true)])
//        socket = manager.defaultSocket
//
//        socket.on(clientEvent: .connect) { data, ack in
//            print("Socket connected")
//        }
//
//        socket.on("room_ready") { data, ack in
//            print("Received room_ready event")
//            if let response = data[0] as? [String: Any], let roomID = response["room_id"] as? String {
//                DispatchQueue.main.async {
//                    self.roomID = roomID
//                }
//            }
//        }
//
//        socket.connect()
//    }
//
//    func requestRoomID() {
//        guard let url = URL(string: "https://blurrr-dating.com/join") else { return }
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        let requestBody: [String: Any] = ["user_id": "testuser"]
//
//        do {
//            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
//        } catch {
//            print("Error serializing JSON: \(error)")
//            return
//        }
//
//        URLSession.shared.dataTask(with: request) { data, response, error in
//            guard let data = data, error == nil else {
//                print("Error: \(error?.localizedDescription ?? "No data")")
//                return
//            }
//            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
//                if let responseJSON = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
//                    DispatchQueue.main.async {
//                        if let roomID = responseJSON["room_id"] as? String {
//                            self.roomID = roomID
//                            self.socket.emit("join", ["room_id": roomID])
//                        }
//                    }
//                }
//            }
//        }.resume()
//    }
//}
