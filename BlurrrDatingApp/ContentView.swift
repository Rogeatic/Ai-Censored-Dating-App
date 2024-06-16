import SwiftUI

struct ContentView: View {
    @StateObject private var socketManager = SocketIOManager()
    @State private var userID: String = ""
    @State private var navigateToVideoCall: Bool = false

    var body: some View {
        NavigationView {
            VStack {
                CameraPreviewView()
                    .frame(height: 200) // Adjust the height as needed
                    .padding()

                Text("ContentView Loaded")
                    .padding()
                
                TextField("Enter your user ID", text: $userID, onEditingChanged: { isEditing in
                    if !isEditing {
                        UIApplication.shared.endEditing()
                    }
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                
                Button(action: {
                    print("Join Room button pressed with userID: \(userID)")
                    socketManager.joinRoom(userID: userID) {
                        navigateToVideoCall = true
                    }
                }) {
                    Text("Join Room")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding()

                if !socketManager.roomID.isEmpty {
                    Text("Room ID: \(socketManager.roomID)")
                        .padding()
                } else {
                    Text("Waiting for room ID...")
                        .padding()
                }

                NavigationLink(destination: VideoCallView(roomID: socketManager.roomID), isActive: $navigateToVideoCall) {
                    EmptyView()
                }
            }
            .padding()
            .onAppear {
                print("ContentView appeared")
            }
            .background(Color.white)
            .onTapGesture {
                UIApplication.shared.endEditing()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
