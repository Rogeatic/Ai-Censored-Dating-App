
import SwiftUI
import SocketIO

class SocketIOManager: ObservableObject {
    @Published var roomID: String = "hardcodedRoomID"
    @Published var roomPassword: String = "hardcodedRoomPassword"

    func joinRoom(userID: String, completion: @escaping () -> Void) {
        DispatchQueue.main.async {
            completion()
        }
    }
}
