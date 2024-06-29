import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var socketManager = SocketIOManager()
    @State private var navigateToVideoCall: Bool = false
    @State private var isBlurred: Bool = false

    // Hardcoded user info
    private var displayName: String = "User"
    private var email: String = "user@example.com"
    private var avatarURL: URL = URL(string: "https://example.com/default-avatar.png")!
    private var idToken: String = "hardcodedUserID"

    var body: some View {
        NavigationView {
            VStack {
                // This is the starting view.
                CameraPreviewView(isBlurred: $isBlurred)
                    .frame(height: 400)
                    .cornerRadius(15)
                    .padding()
                    .blur(radius: isBlurred ? 100 : 0) // Apply the blur effect based on isBlurred
                    .animation(.easeInOut, value: isBlurred)

                Text("Hello, \(displayName)")
                    .font(.title)
                    .padding()

                Button(action: {
                    print("Join Room button pressed")
                    socketManager.joinRoom(userID: idToken) {
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

                NavigationLink(
                    destination: VideoCallView(roomID: socketManager.roomID, roomPassword: socketManager.roomPassword, displayName: displayName, email: email, avatarURL: avatarURL)
                        .navigationBarHidden(true),
                    isActive: $navigateToVideoCall
                ) {
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

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
