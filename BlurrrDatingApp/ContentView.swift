import SwiftUI

struct ContentView: View {
    let signalingURL: URL
    let iceServers: [String]

    @State private var isUserSignedIn: Bool = UserDefaults.standard.bool(forKey: "isUserSignedIn")
    @State private var displayName: String = UserDefaults.standard.string(forKey: "displayName") ?? ""
    @State private var email: String = UserDefaults.standard.string(forKey: "email") ?? ""
    @State private var avatarURL: URL = {
        if let s = UserDefaults.standard.string(forKey: "avatarURL"), let u = URL(string: s) { return u }
        return URL(string: "https://example.com/default-avatar.png")!
    }()
    @State private var idToken: String = UserDefaults.standard.string(forKey: "idToken") ?? ""
    @State private var isBlurred: Bool = false
    @State private var showUserPopover: Bool = false
    @State private var isInCall: Bool = false

    // Lazily created when the user enters a call; nilled out when they leave
    @State private var webRTCHandler: WebRTCHandler?
    @State private var signalingHandler: SignalingHandler?

    var body: some View {
        NavigationView {
            if !isUserSignedIn {
                LoginView(
                    isUserSignedIn: $isUserSignedIn,
                    displayName: $displayName,
                    email: $email,
                    avatarURL: $avatarURL,
                    idToken: $idToken
                )
            } else {
                mainContent
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    // MARK: - Main Content

    private var mainContent: some View {
        VStack(spacing: 0) {
            // Top bar
            HStack {
                avatarButton
                    .padding([.leading, .top], 16)
                Spacer()
            }

            Spacer()

            // Camera preview (uses its own AVCaptureSession — separate from WebRTC)
            ZStack {
                // Camera view
                CameraPreviewView(isBlurred: $isBlurred)
                    .cornerRadius(15)
                    .frame(height: UIScreen.main.bounds.size.height * 0.50)
                    .blur(radius: isBlurred ? 20 : 0)
                    .mask(
                        RoundedRectangle(cornerRadius: 12)
                            .padding(3)
                            .blur(radius: 26)
                    )
                
                // Glow layer — bleeds outward
                if isBlurred {
                    LinearGradient.teal
                        .cornerRadius(15)
                        .blur(radius: 60)
                        .scaleEffect(1.15)
                        .opacity(0.9)
                }

                // Text on top of everything
                if isBlurred {
                    Text("Shielding Your Eyes")
                        .font(.headline.bold())
                        .foregroundColor(.white)
                }
            }
            .frame(height: UIScreen.main.bounds.size.height * 0.50)
            .padding()
            .animation(.easeInOut, value: isBlurred)
            .padding(.bottom, 10)

            Text("Hello, \(displayName)")
                .font(.headline)
                .padding(.bottom, 8)
                .foregroundColor(Color("appOrange"))

            // Navigate to video call — creates fresh handlers each time
            NavigationLink(
                destination: callDestination,
                isActive: $isInCall
            ) {
                Button(action: enterCall) {
                    Label("Start Video Call", systemImage: "video.fill")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .tealGradientBackground(cornerRadius: 14)
                        .padding(.horizontal)
                }
            }
            .padding(.bottom, 32)

            Spacer()
        }
        .background(Color(.systemBackground))
        .onAppear {
            NotificationCenter.default.post(name: .init("startCameraSession"), object: nil)
        }
        .onDisappear {
            NotificationCenter.default.post(name: .init("stopCameraSession"), object: nil)
        }
    }

    // MARK: - Call Destination

    @ViewBuilder
    private var callDestination: some View {
        if let rtc = webRTCHandler, let sig = signalingHandler {
            VideoView(signalingHandler: sig, webRTCHandler: rtc)
                .onDisappear {
                    // Tear down handlers when leaving call
                    webRTCHandler = nil
                    signalingHandler = nil
                }
        } else {
            ProgressView("Setting up call...")
        }
    }

    private func enterCall() {
        // Create fresh instances every time a call starts
        let newRTC = WebRTCHandler(iceServers: iceServers)
        let newSig = SignalingHandler(webSocket: StarscreamWebSocket(url: signalingURL))
        webRTCHandler = newRTC
        signalingHandler = newSig
        isInCall = true
    }

    // MARK: - Avatar / Popover

    private var avatarButton: some View {
        Button(action: { showUserPopover.toggle() }) {
            AsyncImage(url: avatarURL) { phase in
                if let image = phase.image {
                    image.resizable().aspectRatio(contentMode: .fill)
                } else {
                    Image(systemName: "person.fill").resizable()
                }
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
        }
        .popover(isPresented: $showUserPopover) {
            userPopoverContent
        }
    }

    private var userPopoverContent: some View {
        VStack(spacing: 12) {
            AsyncImage(url: avatarURL) { phase in
                if let image = phase.image {
                    image.resizable().aspectRatio(contentMode: .fill)
                } else {
                    Image(systemName: "person.fill").resizable()
                }
            }
            .frame(width: 60, height: 60)
            .clipShape(Circle())

            Text(displayName).font(.headline)
            Text(email).font(.subheadline).foregroundColor(.secondary)

            Button(role: .destructive, action: signOut) {
                Text("Sign Out")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Button("Cancel") { showUserPopover = false }
                .buttonStyle(.bordered)
        }
        .frame(width: 220)
        .padding()
    }

    // MARK: - Sign Out

    private func signOut() {
        isUserSignedIn = false
        showUserPopover = false
        let keys = ["isUserSignedIn", "displayName", "email", "avatarURL", "idToken"]
        keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
    }
}
