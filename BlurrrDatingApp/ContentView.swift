import SwiftUI
import SocketIO

struct ContentView: View {
    @State private var serverResponse: String = "Fetching data..."
    @State private var socketStatus: String = "Connecting to socket..."
    @State private var roomDetails: String = "Waiting for room details..."
    let manager = SocketManager(socketURL: URL(string: "http://146.190.132.105:8000")!, config: [.log(true), .compress])

    var body: some View {
        VStack {
            Text("Socket Status:")
                .font(.headline)
            Text(socketStatus)
                .padding()
                .multilineTextAlignment(.center)

            Text("Server Response:")
                .font(.headline)
            Text(serverResponse)
                .padding()
                .multilineTextAlignment(.center)

            Text("Room Details:")
                .font(.headline)
            Text(roomDetails)
                .padding()
                .multilineTextAlignment(.center)
        }
        .onAppear {
            connectToSocket()
        }
    }

    func connectToSocket() {
        let socket = manager.defaultSocket

        socket.on(clientEvent: .connect) { data, ack in
            DispatchQueue.main.async {
                socketStatus = "Connected to socket"
            }
            fetchConnectedClients()
        }

        socket.on(clientEvent: .error) { data, ack in
            DispatchQueue.main.async {
                socketStatus = "Socket error: \(data)"
            }
        }

        socket.on(clientEvent: .disconnect) { data, ack in
            DispatchQueue.main.async {
                socketStatus = "Socket disconnected: \(data)"
            }
        }

        socket.on("room_details") { data, ack in
            if let roomData = data.first as? [String: Any],
               let roomId = roomData["room_id"] as? String,
               let roomPassword = roomData["room_password"] as? String {
                DispatchQueue.main.async {
                    roomDetails = "Room ID: \(roomId), Password: \(roomPassword)"
                }
            } else {
                DispatchQueue.main.async {
                    roomDetails = "Failed to get room details"
                }
            }
        }

        socket.connect()
    }

    func fetchConnectedClients() {
        guard let url = URL(string: "http://146.190.132.105:8000/connected_clients") else {
            serverResponse = "Invalid URL"
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    serverResponse = "Error: \(error.localizedDescription)"
                }
                return
            }

            guard let data = data, let responseString = String(data: data, encoding: .utf8) else {
                DispatchQueue.main.async {
                    serverResponse = "No data received"
                }
                return
            }

            DispatchQueue.main.async {
                serverResponse = responseString
            }
        }

        task.resume()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: ContentView {
        ContentView()
    }
}


//import SwiftUI
//import JitsiMeetSDK
//import SocketIO
//
//struct ContentView: View {
//    @State private var roomName: String? = nil
//    @State private var password: String? = nil
//    @State private var isConnecting: Bool = false
//    @State private var connected: Bool = false
//    @State private var socketConnected: Bool = false
//    let manager = SocketManager(socketURL: URL(string: "http://146.190.132.105:8000")!, config: [.log(true), .compress, .connectParams(["EIO": "4"])])
//
//    var body: some View {
//        VStack {
//            if let roomName = roomName {
//                JitsiMeetViewWrapper(roomName: roomName, password: password ?? "")
//            } else if isConnecting {
//                ConnectingView(isConnecting: $isConnecting, connected: $connected, socketConnected: $socketConnected)
//                    .onAppear {
//                        fetchRoomName()
//                    }
//            } else {
//                StartingView {
//                    isConnecting = true
//                }
//            }
//        }
//    }
//
//    func fetchRoomName() {
//        let socket = manager.defaultSocket
//
//        socket.on(clientEvent: .connect) { data, ack in
//            print("Socket connected")
//            socketConnected = true
//            socket.emit("join", ["username": "user"])
//        }
//
//        socket.on("paired") { data, ack in
//            print("Paired event received: \(data)")
//            if let roomDetails = data[0] as? [String: Any],
//               let room = roomDetails["room"] as? String,
//               let password = roomDetails["password"] as? String {
//                DispatchQueue.main.async {
//                    self.roomName = room
//                    self.password = password
//                    self.connected = true
//                    self.isConnecting = false
//                }
//            } else {
//                print("Paired event did not have the expected data structure")
//            }
//        }
//
//        socket.on("waiting") { data, ack in
//            print("Waiting for another user to join...")
//        }
//
//        socket.on(clientEvent: .error) { data, ack in
//            print("Socket error: \(data)")
//        }
//
//        socket.on(clientEvent: .disconnect) { data, ack in
//            print("Socket disconnected: \(data)")
//            socketConnected = false
//        }
//
//        socket.connect()
//    }
//}
//
//struct ContentView_Previews: PreviewProvider {
//    static var previews: ContentView {
//        ContentView()
//    }
//}
