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

                    Button(action: requestRoomID) {
                        Text(isLoading ? "Joining..." : "Request Room")
                            .padding()
                            .background(isLoading ? Color.gray : Color.blue)
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

    func requestRoomID() {
        isLoading = true
        guard let url = URL(string: "https://blurrr-dating.com/join") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["user_id": email]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
            }
            guard let data = data, error == nil else {
                print("Error: \(error?.localizedDescription ?? "No data")")
                return
            }
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                if let responseJSON = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    DispatchQueue.main.async {
                        if let roomID = responseJSON["room_id"] as? String {
                            self.roomID = roomID
                            self.navigateToVideoCall = true
                        } else if let message = responseJSON["message"] as? String {
                            print(message)
                        }
                    }
                }
            }
        }.resume()
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
