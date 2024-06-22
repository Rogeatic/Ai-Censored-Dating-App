import SwiftUI
import GoogleSignIn
import UIKit

struct ContentView: View {
    @StateObject private var socketManager = SocketIOManager()
    @State private var userID: String = ""
    @State private var navigateToVideoCall: Bool = false
    @State private var isBlurred: Bool = false
    @State private var isUserSignedIn: Bool = false

    // State variables to hold user info
    @State private var displayName: String = ""
    @State private var email: String = ""
    @State private var avatarURL: URL = URL(string: "https://example.com/default-avatar.png")!
    @State private var idToken: String = ""

    var body: some View {
        if !isUserSignedIn {
            LoginView()
                .onAppear {
                    GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
                        if let user = user {
                            self.displayName = user.profile?.name ?? ""
                            self.email = user.profile?.email ?? ""
                            self.avatarURL = user.profile?.imageURL(withDimension: 100) ?? URL(string: "https://example.com/default-avatar.png")!
                            self.idToken = user.idToken?.tokenString ?? ""
                            self.isUserSignedIn = true
                        }
                    }
                }
        } else {
            NavigationView {
                VStack {
                    // This is the starting view.
                    CameraPreviewView(isBlurred: $isBlurred)
                        .frame(height: 400)
                        .cornerRadius(15)
                        .padding()
                        .blur(radius: isBlurred ? 100 : 0) // Apply the blur effect based on isBlurred
                        .animation(.easeInOut, value: isBlurred)

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

                    NavigationLink(
                        destination: VideoCallView(roomID: socketManager.roomID, displayName: displayName, email: email, avatarURL: avatarURL, idToken: idToken),
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
}

extension Notification.Name {
    static let signInCompleted = Notification.Name("signInCompleted")
}

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
