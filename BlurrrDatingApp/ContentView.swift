import SwiftUI

struct ContentView: View {
    @State private var isUserSignedIn: Bool = UserDefaults.standard.bool(forKey: "isUserSignedIn")
    @State private var displayName: String = UserDefaults.standard.string(forKey: "displayName") ?? ""
    @State private var email: String = UserDefaults.standard.string(forKey: "email") ?? ""
    @State private var avatarURL: URL = {
        if let urlString = UserDefaults.standard.string(forKey: "avatarURL"),
           let url = URL(string: urlString) { return url }
        return URL(string: "https://example.com/default-avatar.png")!
    }()
    @State private var idToken: String = UserDefaults.standard.string(forKey: "idToken") ?? ""
    @State private var isBlurred: Bool = false
    @State private var showUserPopover: Bool = false
    @State private var isLoading: Bool = true
    
    var signalingHandler: SignalingHandler
    var webRTCHandler: WebRTCHandler

    init(signalingHandler: SignalingHandler, webRTCHandler: WebRTCHandler) {
        self.signalingHandler = signalingHandler
        self.webRTCHandler = webRTCHandler
    }

    var body: some View {
        NavigationView {
            if !isUserSignedIn {
                LoginView(isUserSignedIn: $isUserSignedIn, displayName: $displayName, email: $email, avatarURL: $avatarURL, idToken: $idToken)
            } else {
                mainContentView
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .onAppear {
            DispatchQueue.global(qos: .userInitiated).async {
                DispatchQueue.main.async {
                    isLoading = false
                }
            }
        }
    }

    var mainContentView: some View {
        VStack {
            headerView
            Spacer()
            mainContent
            Spacer()
        }
        .padding()
        .background(Color.white)
    }

    var headerView: some View {
        HStack {
            userButton
            Spacer()
        }
        .padding([.leading, .top], 16)
    }

    var userButton: some View {
        VStack {
            Button(action: { showUserPopover.toggle() }) {
                AsyncImage(url: avatarURL) { phase in
                    if let image = phase.image {
                        image.resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    } else if phase.error != nil {
                        Image(systemName: "person.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    } else {
                        EmptyView().frame(width: 40, height: 40)
                    }
                }
            }
            .popover(isPresented: $showUserPopover) {
                userPopover
            }
        }
    }

    var userPopover: some View {
        VStack(alignment: .center) {
            AsyncImage(url: avatarURL) { phase in
                if let image = phase.image {
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                } else if phase.error != nil {
                    Image(systemName: "person.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                } else {
                    ProgressView().frame(width: 60, height: 60)
                }
            }
            Text(displayName)
                .font(.headline)
                .padding(.top, 5)
            Text(email)
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.bottom, 10)

            Button(action: { signOut() }) {
                Text("Sign Out")
                    .foregroundColor(.red)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
            }
            .padding(.vertical, 5)

            Button(action: { showUserPopover = false }) {
                Text("Cancel")
                    .foregroundColor(.black)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
            }
        }
        .frame(width: 230, height: 260)
        .padding()
        .background(Color.white)
        .cornerRadius(15)
    }

    var mainContent: some View {
        VStack {
            if isLoading {
                ProgressView("Preparing Ai").padding()
            } else {
                CameraPreviewView(isBlurred: $isBlurred, videoTrack: webRTCHandler.localVideoTrack)
                    .cornerRadius(15)
                    .frame(height: UIScreen.main.bounds.size.height * 0.50)
                    .padding()
                    .background(
                        Group {
                            if isBlurred {
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.darkTeal, Color.darkTeal1]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                .cornerRadius(15)
                            } else {
                                Color.clear
                            }
                        }
                    )
                    .blur(radius: isBlurred ? 100 : 0)
                    .animation(.easeInOut, value: isBlurred)
                    .padding(.bottom, 10)

                Text("Hello, \(displayName)")
                NavigationLink(destination: VideoView(signalingHandler: signalingHandler, webRTCHandler: webRTCHandler)) {
                    Text("Go to Video View")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding()
            }
        }
    }

    private func signOut() {
        isUserSignedIn = false
        showUserPopover = false
        
        // Clear user defaults
        UserDefaults.standard.set(false, forKey: "isUserSignedIn")
        UserDefaults.standard.set(nil, forKey: "displayName")
        UserDefaults.standard.set(nil, forKey: "email")
        UserDefaults.standard.set(nil, forKey: "avatarURL")
        UserDefaults.standard.set(nil, forKey: "idToken")
    }
}
