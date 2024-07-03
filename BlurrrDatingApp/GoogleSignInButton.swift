import SwiftUI
import GoogleSignIn

struct LoginView: View {
    @Binding var isUserSignedIn: Bool
    @Binding var displayName: String
    @Binding var email: String
    @Binding var avatarURL: URL
    @Binding var idToken: String

    var body: some View {
        VStack {
            Text("Please sign in to continue")
            signInButton
                .frame(width: 200, height: 50)
                .padding()
        }
    }

    private var signInButton: some View {
        Button(action: {
            signInWithGoogle()
        }) {
            Text("Sign In with Google")
                .padding()
                .background(Color.darkTeal)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
    }

    private func signInWithGoogle() {
        guard let clientID = GIDSignIn.sharedInstance.configuration?.clientID else { return }
        let signInConfig = GIDConfiguration(clientID: clientID)

        guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
            print("Failed to retrieve the root view controller")
            return
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
            if let error = error {
                print(error.localizedDescription)
                return
            }

            guard let user = result?.user else { return }

            displayName = user.profile?.name ?? ""
            email = user.profile?.email ?? ""
            avatarURL = user.profile?.imageURL(withDimension: 100) ?? URL(string: "https://example.com/default-avatar.png")!
            idToken = user.idToken?.tokenString ?? ""
            isUserSignedIn = true
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(isUserSignedIn: .constant(false), displayName: .constant(""), email: .constant(""), avatarURL: .constant(URL(string: "https://example.com/default-avatar.png")!), idToken: .constant(""))
    }
}
