import SwiftUI
import AVFoundation
import JitsiMeetSDK

struct CallView: View {
    let roomName: String
    
    var body: some View {
        JitsiMeetViewWrapper(roomName: roomName)
            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
            .ignoresSafeArea()
    }
}
