import SwiftUI
import GoogleSignIn

struct ContentView: View {
    @StateObject private var socketManager = SocketIOManager()
    @State private var userID: String = ""
    @State private var navigateToVideoCall: Bool = false
    @State private var isUserSignedIn: Bool = false
    @State private var displayName: String = ""
    @State private var email: String = ""
    @State private var avatarURL: URL = URL(string: "https://example.com/default-avatar.png")!
    @State private var idToken: String = ""
    @State private var isBlurred: Bool = false

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
                .onReceive(NotificationCenter.default.publisher(for: .signInCompleted)) { notification in
                    if let userInfo = notification.userInfo {
                        self.displayName = userInfo["displayName"] as? String ?? ""
                        self.email = userInfo["email"] as? String ?? ""
                        self.avatarURL = userInfo["avatarURL"] as? URL ?? URL(string: "https://example.com/default-avatar.png")!
                        self.idToken = userInfo["idToken"] as? String ?? ""
                        self.isUserSignedIn = true
                    }
                }
        } else {
            NavigationView {
                VStack {
                    CameraPreviewView(isBlurred: $isBlurred)
                        .frame(height: 400)
                        .cornerRadius(15)
                        .padding()
                        .blur(radius: isBlurred ? 100 : 0)
                        .animation(.easeInOut, value: isBlurred)

                    Text("Hello, \(displayName)")
                        .padding()

                    Button(action: {
                        socketManager.joinRoom(userID: idToken)
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
                        NavigationLink(destination: VideoCallView(roomID: socketManager.roomID, displayName: displayName, email: email, avatarURL: avatarURL.absoluteString, idToken: idToken), isActive: $navigateToVideoCall) {
                            EmptyView()
                        }
                    } else {
                        Text("Waiting for room ID...")
                            .padding()
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

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

extension Notification.Name {
    static let signInCompleted = Notification.Name("signInCompleted")
}
