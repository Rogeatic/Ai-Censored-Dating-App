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

            // Camera preview
            ZStack {
                CameraPreviewView(isBlurred: $isBlurred)
                    .cornerRadius(15)
                    .frame(height: UIScreen.main.bounds.size.height * 0.50)
                    .blur(radius: isBlurred ? 20 : 0)
                    .mask(
                        RoundedRectangle(cornerRadius: 12)
                            .padding(3)
                            .blur(radius: 26)
                    )

                if isBlurred {
                    LinearGradient.teal
                        .cornerRadius(15)
                        .blur(radius: 60)
                        .scaleEffect(1.15)
                        .opacity(0.9)
                }

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

            Text("Hello, \(displayName.components(separatedBy: " ").first ?? displayName)")
                .font(.headline)
                .padding(.bottom, 8)
                .foregroundColor(Color("appOrange"))

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
            Image(systemName: "ellipsis")
                .font(.title2)
                .foregroundColor(.primary)
                .frame(width: 40, height: 40)
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

// MARK: - Home Screen Blobs
// Three blobs spread across full screen width, centers at the edge of the frame
// so they appear half-visible peaking in from top or bottom.

struct HomeBlobs: View {
    // Each blob drifts independently
    @State private var o1: CGFloat = 0
    @State private var o2: CGFloat = 0
    @State private var o3: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack {
                // Left blob
                Circle()
                    .fill(Color("appOrange").opacity(0.55))
                    .frame(width: 200, height: 200)
                    .blur(radius: 40)
                    .position(x: w * 0.18, y: o1)

                // Centre blob — largest
                Circle()
                    .fill(Color("appOrange").opacity(0.45))
                    .frame(width: 240, height: 240)
                    .blur(radius: 50)
                    .position(x: w * 0.52, y: o2)

                // Right blob
                Circle()
                    .fill(Color("appOrange").opacity(0.50))
                    .frame(width: 190, height: 190)
                    .blur(radius: 38)
                    .position(x: w * 0.85, y: o3)
            }
            .frame(width: w, height: geo.size.height)
            .onAppear {
                let mid = geo.size.height / 2
                o1 = mid; o2 = mid; o3 = mid
                withAnimation(.easeInOut(duration: 4.5).repeatForever(autoreverses: true)) {
                    o1 = mid + 18
                }
                withAnimation(.easeInOut(duration: 3.8).repeatForever(autoreverses: true).delay(0.7)) {
                    o2 = mid - 14
                }
                withAnimation(.easeInOut(duration: 5.2).repeatForever(autoreverses: true).delay(1.3)) {
                    o3 = mid + 22
                }
            }
        }
    }
}
