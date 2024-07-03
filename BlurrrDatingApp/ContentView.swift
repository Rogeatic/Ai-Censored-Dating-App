import SwiftUI
import GoogleSignIn

struct ContentView: View {
    @State private var roomID: String?
    @State private var isUserSignedIn: Bool = false
    @State private var displayName: String = ""
    @State private var email: String = ""
    @State private var avatarURL: URL = URL(string: "https://example.com/default-avatar.png")!
    @State private var idToken: String = ""
    @State private var isBlurred: Bool = false
    @State private var isLoading: Bool = false
    @State private var navigateToVideoCall: Bool = false

    var body: some View {
        NavigationView {
            if !isUserSignedIn {
                LoginView(isUserSignedIn: $isUserSignedIn, displayName: $displayName, email: $email, avatarURL: $avatarURL, idToken: $idToken)
            } else {
                VStack {
                    CameraPreviewView(isBlurred: $isBlurred)
                        .cornerRadius(15)
                        .frame(height: 400)
                        .padding()
                        .blur(radius: isBlurred ? 100 : 0)
                        .background(!isBlurred ? Color.clear : Color.darkTeal)
                        .animation(.easeInOut, value: isBlurred)
                        .cornerRadius(15)


                    Text("Hello, \(displayName)")
                        .padding()

                    Button(action: requestRoomID) {
                        Text(isLoading ? "Joining..." : "Request Room")
                            .padding()
                            .background(isLoading ? Color.gray : Color.darkTeal)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding()
                    .disabled(isLoading)

                    if let roomID = roomID {
                        Text("Room ID: \(roomID)")
                            .padding()
                        NavigationLink(
                            destination: VideoCallView(
                                roomID: roomID,
                                displayName: displayName,
                                email: email,
                                avatarURL: avatarURL.absoluteString,
                                idToken: idToken
                            ),
                            isActive: $navigateToVideoCall
                        ) {
                            EmptyView()
                        }
                        .hidden()
                        .onAppear {
                            navigateToVideoCall = true
                        }
                    } else {
                        Text("Waiting for room ID...")
                            .padding()
                    }
                }
                .padding()
                .background(Color.white)
                .onTapGesture {
                    UIApplication.shared.endEditing()
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private func requestRoomID() {
        // Implement room ID request logic
        isLoading = true
    }
}

// Helper function to dismiss keyboard
extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
