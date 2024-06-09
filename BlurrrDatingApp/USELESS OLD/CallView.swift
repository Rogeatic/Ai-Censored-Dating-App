import SwiftUI
import AVFoundation
import JitsiMeetSDK

struct CallView: View {
    let roomName: String
    let password: String
    
    
    
    var body: some View {
        JitsiMeetViewWrapper(roomName: roomName, password: password)
            .frame(height: UIScreen.main.bounds.height / 2) // Half the screen height
            .rotationEffect(.degrees(isPortrait ? 0 : 90)) // Rotate if device rotates
            .onAppear {
                UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
            }
    }
    
    var isPortrait: Bool {
        return UIScreen.main.bounds.height > UIScreen.main.bounds.width
    }
}
