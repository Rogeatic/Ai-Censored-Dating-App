import SwiftUI

extension Color {
    /// Primary teal — used for gradients, buttons, and blur overlays
    static let darkTeal  = Color(red: 0/255, green: 150/255, blue: 136/255)  // #009688
    /// Slightly deeper teal for gradient endpoint
    static let darkTeal1 = Color(red: 0/255, green: 105/255, blue: 92/255)   // #00695C

    static let tealGradient = LinearGradient(
        gradient: Gradient(colors: [.darkTeal, .darkTeal1]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension LinearGradient {
    static let teal = LinearGradient(
        gradient: Gradient(colors: [Color.darkTeal, Color.darkTeal1]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension View {
    /// Applies the app's standard teal gradient as a background
    func tealGradientBackground(cornerRadius: CGFloat = 12) -> some View {
        self.background(
            LinearGradient.teal
                .cornerRadius(cornerRadius)
        )
    }
}
