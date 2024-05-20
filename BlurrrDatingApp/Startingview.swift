import SwiftUI

struct StartingView: View {
    var onConnect: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                
                CameraPreviewView()
                    .frame(height: geometry.size.height / 1.5)
                    .cornerRadius(12)
                    .padding()

                Spacer()
                
                Text("Welcome to The Blurrr")
                    .font(.largeTitle)
                    .padding()

                Button(action: onConnect) {
                    Text("Start Video Call")
                        .font(.title2)
                        .padding()
                        //.background(Color.blue)
                        .background(.appOrange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Spacer()
            }
            .onAppear {
                UIDevice.current.beginGeneratingDeviceOrientationNotifications()
                NotificationCenter.default.addObserver(
                    forName: UIDevice.orientationDidChangeNotification,
                    object: nil,
                    queue: .main
                ) { _ in
                    // This will force SwiftUI to recompute the layout
                    geometry.frame(in: .global)
                }
            }
            .onDisappear {
                NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
                UIDevice.current.endGeneratingDeviceOrientationNotifications()
            }
        }
    }
}

struct StartingView_Previews: PreviewProvider {
    static var previews: some View {
        StartingView {
            print("Connecting...")
        }
    }
}
