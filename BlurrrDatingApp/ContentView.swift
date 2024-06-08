import SwiftUI
import SocketIO

struct ContentView: View {
    @State private var serverResponse: String = "Fetching data..."
    @State private var socketStatus: String = "Connecting to socket..."
    @State private var roomDetails: String = "Waiting for room details..."
    @State private var urlFetchResponse: String = "Fetching clients data..."
    
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

            Text("Server Response (Socket):")
                .font(.headline)
            Text(serverResponse)
                .padding()
                .multilineTextAlignment(.center)

            Text("Room Details:")
                .font(.headline)
            Text(roomDetails)
                .padding()
                .multilineTextAlignment(.center)
                
            Text("URL Fetch Response:")
                .font(.headline)
            Text(urlFetchResponse)
                .padding()
                .multilineTextAlignment(.center)
        }
        .onAppear {
            connectToSocket()
        }
    }

    func connectToSocket() {
        socket.on(clientEvent: .connect) { data, ack in
            print("Socket connected")
            DispatchQueue.main.async {
                socketStatus = "Connected to socket"
            }
            fetchConnectedClients()
        }

        socket.on("response") { data, ack in
            print("Received response event with data: \(data)")
            if let responseData = data.first as? [String: Any],
               let message = responseData["message"] as? String {
                print("Parsed response message: \(message)")
                DispatchQueue.main.async {
                    serverResponse = message
                }
            } else {
                print("Failed to parse response data")
                DispatchQueue.main.async {
                    serverResponse = "Failed to get response"
                }
            }
        }

        socket.on("room_details") { data, ack in
            print("Received room_details event with data: \(data)")
            if let roomData = data.first as? [String: Any] {
                print("roomData: \(roomData)")
                let roomId = "\(roomData["room_id"] ?? "N/A")"
                let roomPassword = "\(roomData["room_password"] ?? "N/A")"
                print("Parsed room details: \(roomId), \(roomPassword)")
                DispatchQueue.main.async {
                    roomDetails = "Room ID: \(roomId), Password: \(roomPassword)"
                }
            } else {
                print("Failed to parse room details")
                DispatchQueue.main.async {
                    roomDetails = "Failed to get room details"
                }
            }
        }

        socket.on(clientEvent: .error) { data, ack in
            print("Socket error: \(data)")
            DispatchQueue.main.async {
                socketStatus = "Socket error: \(data)"
            }
        }

        socket.on(clientEvent: .disconnect) { data, ack in
            print("Socket disconnected: \(data)")
            DispatchQueue.main.async {
                socketStatus = "Socket disconnected: \(data)"
            }
        }

        socket.connect()
    }

    func fetchConnectedClients() {
        guard let url = URL(string: "http://146.190.132.105:8000/connected_clients") else {
            urlFetchResponse = "Invalid URL"
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    urlFetchResponse = "Error: \(error.localizedDescription)"
                }
                return
            }

            guard let data = data, let responseString = String(data: data, encoding: .utf8) else {
                DispatchQueue.main.async {
                    urlFetchResponse = "No data received"
                }
                return
            }

            DispatchQueue.main.async {
                urlFetchResponse = responseString
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
