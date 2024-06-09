import SwiftUI
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    class CameraPreviewLayer: UIView {
        var captureSession: AVCaptureSession
        var previewLayer: AVCaptureVideoPreviewLayer
        
        init(session: AVCaptureSession) {
            self.captureSession = session
            self.previewLayer = AVCaptureVideoPreviewLayer(session: session)
            super.init(frame: .zero)
            
            previewLayer.videoGravity = .resizeAspectFill
            layer.addSublayer(previewLayer)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            previewLayer.frame = self.bounds
            updateVideoOrientation()
        }
        
        func updateVideoOrientation() {
            if let connection = previewLayer.connection {
                switch UIDevice.current.orientation {
                case .portrait:
                    connection.videoOrientation = .portrait
                case .landscapeLeft:
                    connection.videoOrientation = .landscapeRight
                case .landscapeRight:
                    connection.videoOrientation = .landscapeLeft
                case .portraitUpsideDown:
                    connection.videoOrientation = .portraitUpsideDown
                default:
                    connection.videoOrientation = .portrait
                }
            }
        }
    }
    
    func makeUIView(context: Context) -> CameraPreviewLayer {
        let session = AVCaptureSession()
        session.sessionPreset = .high
        
        guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            return CameraPreviewLayer(session: session)
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: frontCamera)
            if session.canAddInput(input) {
                session.addInput(input)
            }
        } catch {
            print("Error setting up camera input: \(error)")
        }
        
        session.startRunning()
        
        return CameraPreviewLayer(session: session)
    }
    
    func updateUIView(_ uiView: CameraPreviewLayer, context: Context) {
        uiView.updateVideoOrientation()
    }
    
    static func dismantleUIView(_ uiView: CameraPreviewLayer, coordinator: ()) {
        uiView.captureSession.stopRunning()
    }
}
