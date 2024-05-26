import SwiftUI
import SocketIO

struct ContentView: View {
    @State private var serverResponse: String = "Fetching data..."
    @State private var socketStatus: String = "Connecting to socket..."
    @State private var roomDetails: String = "Waiting for room details..."
    let manager = SocketManager(socketURL: URL(string: "http://146.190.132.105:8000")!, config: [.log(true), .compress])
    var socket: SocketIOClient {
        return manager.defaultSocket
    }

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
        socket.on(clientEvent: .connect) { data, ack in
            DispatchQueue.main.async {
                socketStatus = "Connected to socket"
            }
            fetchConnectedClients()
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
