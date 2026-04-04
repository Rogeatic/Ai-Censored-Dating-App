import SwiftUI

extension LinearGradient {
    static let teal = LinearGradient(
        gradient: Gradient(colors: [.darkTeal, .darkTeal1]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension View {
    func tealGradientBackground(cornerRadius: CGFloat = 12) -> some View {
        self.background(LinearGradient.teal.cornerRadius(cornerRadius))
    }
}
