import SwiftUI
import GoogleSignIn
import UIKit

struct ContentView: View {
    @StateObject private var socketManager = SocketIOManager()
    @State private var navigateToVideoCall: Bool = false
    @State private var isBlurred: Bool = false
    @State private var isUserSignedIn: Bool = false
    @State private var isWaitingForPair: Bool = false

    // State variables to hold user info
    @State private var displayName: String = ""
    @State private var email: String = ""
    @State private var avatarURL: URL = URL(string: "https://example.com/default-avatar.png")!
    @State private var idToken: String = ""
    @State private var roomID: String = ""

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

                    NotificationCenter.default.addObserver(forName: .signInCompleted, object: nil, queue: .main) { notification in
                        if let userInfo = notification.userInfo {
                            self.displayName = userInfo["displayName"] as? String ?? ""
                            self.email = userInfo["email"] as? String ?? ""
                            self.avatarURL = userInfo["avatarURL"] as? URL ?? URL(string: "https://example.com/default-avatar.png")!
                            self.idToken = userInfo["idToken"] as? String ?? ""
                            self.isUserSignedIn = true
                        }
                    }

                    NotificationCenter.default.addObserver(forName: .roomCreated, object: nil, queue: .main) { notification in
                        if let userInfo = notification.userInfo, let roomID = userInfo["room_id"] as? String {
                            self.roomID = roomID
                            self.navigateToVideoCall = true
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

                    Text("Hello, \(displayName)")
                        .font(.title)
                        .padding()

                    if isWaitingForPair {
                        Text("Waiting for another user to join...")
                            .padding()
                    } else {
                        Button(action: {
                            print("Join Room button pressed")
                            socketManager.joinRoom(userID: idToken) { response in
                                if let paired = response["paired"] as? Bool, paired, let roomID = response["room_id"] as? String {
                                    self.roomID = roomID
                                    self.navigateToVideoCall = true
                                } else {
                                    self.isWaitingForPair = true
                                }
                            }
                        }) {
                            Text("Join Room")
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .padding()
                    }

                    NavigationLink(
                        destination: VideoCallView(roomID: roomID, displayName: displayName, email: email, avatarURL: avatarURL, idToken: idToken)
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
}

extension Notification.Name {
    static let signInCompleted = Notification.Name("signInCompleted")
}

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
