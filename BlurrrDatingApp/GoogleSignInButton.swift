import SwiftUI
import GoogleSignIn

struct LoginView: View {
    @Binding var isUserSignedIn: Bool
    @Binding var displayName: String
    @Binding var email: String
    @Binding var avatarURL: URL
    @Binding var idToken: String

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Logo / branding area
            VStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 60))
                    .foregroundStyle(LinearGradient.teal)

                Text("Blurrr")
                    .font(.largeTitle.bold())
                    .foregroundStyle(LinearGradient.teal)

                Text("Sign in to begin")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Sign in button
            Button(action: signInWithGoogle) {
                HStack(spacing: 10) {
                    Image(systemName: "g.circle.fill")
                        .font(.title3)
                    Text("Sign In with Google")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .tealGradientBackground(cornerRadius: 14)
                .padding(.horizontal, 32)
            }

            Spacer()
        }
        .background(Color(.systemBackground))
    }

    private func signInWithGoogle() {
        guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
            print("Failed to retrieve the root view controller")
            return
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
            if let error { print(error.localizedDescription); return }
            guard let user = result?.user else { return }

            displayName    = user.profile?.name ?? ""
            email          = user.profile?.email ?? ""
            avatarURL      = user.profile?.imageURL(withDimension: 100) ?? URL(string: "https://example.com/default-avatar.png")!
            idToken        = user.idToken?.tokenString ?? ""
            isUserSignedIn = true

            UserDefaults.standard.set(true,                       forKey: "isUserSignedIn")
            UserDefaults.standard.set(displayName,                forKey: "displayName")
            UserDefaults.standard.set(email,                      forKey: "email")
            UserDefaults.standard.set(avatarURL.absoluteString,   forKey: "avatarURL")
            UserDefaults.standard.set(idToken,                    forKey: "idToken")
        }
    }
}
