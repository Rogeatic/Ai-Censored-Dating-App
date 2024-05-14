import SwiftUI
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    class CameraPreviewLayer: UIView {
        var captureSession: AVCaptureSession
        
        init(session: AVCaptureSession) {
            self.captureSession = session
            super.init(frame: .zero)
            
            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            layer.addSublayer(previewLayer)
            
            previewLayer.frame = self.bounds
            previewLayer.connection?.videoOrientation = .portrait
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            if let sublayers = layer.sublayers {
                for layer in sublayers {
                    layer.frame = self.bounds
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
        // No update needed
    }
    
    static func dismantleUIView(_ uiView: CameraPreviewLayer, coordinator: ()) {
        uiView.captureSession.stopRunning()
    }
}
