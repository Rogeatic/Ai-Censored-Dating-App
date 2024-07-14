import SwiftUI

struct ContentView: View {
    @State private var isUserSignedIn: Bool = false
    @State private var displayName: String = ""
    @State private var email: String = ""
    @State private var avatarURL: URL = URL(string: "https://example.com/default-avatar.png")!
    @State private var idToken: String = ""
    @State private var isBlurred: Bool = false
    @State private var showUserPopover: Bool = false
    
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
                VStack {
                    HStack {
                        VStack {
                            Button(action: {
                                showUserPopover.toggle()
                            }) {
                                AsyncImage(url: avatarURL) { phase in
                                    if let image = phase.image {
                                        image
                                            .resizable()
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
                                        ProgressView()
                                            .frame(width: 40, height: 40)
                                    }
                                }
                            }
                            .popover(isPresented: $showUserPopover) {
                                VStack(alignment: .center) {
                                    AsyncImage(url: avatarURL) { phase in
                                        if let image = phase.image {
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 60, height: 60) // Increased the frame size
                                                .clipShape(Circle())
                                        } else if phase.error != nil {
                                            Image(systemName: "person.fill")
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 60, height: 60) // Increased the frame size
                                                .clipShape(Circle())
                                        } else {
                                            ProgressView()
                                                .frame(width: 60, height: 60) // Increased the frame size
                                        }
                                    }
                                    
                                    Text(displayName)
                                        .font(.headline)
                                        .padding(.top, 5)
                                    Text(email)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .padding(.bottom, 10) // Add some spacing below the email
                                    
                                    Button(action: {
                                        // Sign out action
                                        isUserSignedIn = false
                                        showUserPopover = false
                                    }) {
                                        Text("Sign Out")
                                            .foregroundColor(.red)
                                            .padding(.horizontal, 25) // Increased padding
                                            .padding(.vertical, 12) // Increased padding
                                            .background(Color.gray.opacity(0.2))
                                            .cornerRadius(8)
                                    }
                                    .padding(.bottom, 5)
                                    .padding(.top, 10)
                                    
                                    Button(action: {
                                        // Cancel action
                                        showUserPopover = false
                                    }) {
                                        Text("Cancel")
                                            .foregroundColor(.black)
                                            .padding(.horizontal, 20) // Increased padding
                                            .padding(.vertical, 10) // Increased padding
                                            .background(Color.gray.opacity(0.2))
                                            .cornerRadius(8)
                                    }
                                }
                                .frame(width: 230, height: 260) // Increased the height
                                .padding()
                                .background(Color.white)
                                .cornerRadius(15)
                            }
                        }
                        .padding(.leading, 16) // Adjust left padding
                        .padding(.top, 16) // Adjust top padding

                        Spacer()
                    }
                    .padding(.top, 0) // Remove extra top padding
                    
                    Spacer() // Add a spacer to push the content towards the center

                    VStack {
                        CameraPreviewView(isBlurred: $isBlurred, videoTrack: webRTCHandler.localVideoTrack)
                            .cornerRadius(15)
                            .frame(height: UIScreen.main.bounds.size.height * 0.50)
                            .padding()
                            .blur(radius: isBlurred ? 100 : 0)
                            .background(isBlurred ? AnyView(LinearGradient(gradient: Gradient(colors: [Color.darkTeal, Color.darkTeal1]), startPoint: .topLeading, endPoint: .bottomTrailing)) : AnyView(Color.clear))
                            .animation(.easeInOut, value: isBlurred)
                            .cornerRadius(15)
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
                    
                    Spacer() // Add another spacer here to center the content vertically
                }
                .padding()
                .background(Color.white)
                .onTapGesture {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
