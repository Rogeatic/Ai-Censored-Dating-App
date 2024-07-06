import SwiftUI
import AVFoundation
import CoreML
import Vision
import NSFWDetector

struct CameraPreviewView: UIViewRepresentable {
    @Binding var isBlurred: Bool

    class CameraPreviewLayer: UIView, AVCaptureVideoDataOutputSampleBufferDelegate {
        var captureSession: AVCaptureSession
        var previewLayer: AVCaptureVideoPreviewLayer
        var nsfwDetector = NSFWDetector.shared
        @Binding var isBlurred: Bool
        
        private var blurTimer: Timer?

        init(session: AVCaptureSession, isBlurred: Binding<Bool>) {
            self.captureSession = session
            self.previewLayer = AVCaptureVideoPreviewLayer(session: session)
            self._isBlurred = isBlurred
            
            super.init(frame: .zero)
            
            previewLayer.videoGravity = .resizeAspectFill
            layer.addSublayer(previewLayer)
            
            setupVideoOutput()
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
        
        func setupVideoOutput() {
            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            captureSession.addOutput(videoOutput)
        }
        
        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            
            // Convert the pixel buffer to a UIImage
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let context = CIContext()
            guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
            let uiImage = UIImage(cgImage: cgImage)
            
            // Check the image for NSFW content
            nsfwDetector.check(image: uiImage, completion: { result in
                switch result {
                case let .success(nsfwConfidence: confidence):
                    DispatchQueue.main.async {
                        if confidence > 0.72 {
                            self.applyCensoring()
                            //print("NSFW content detected with confidence: \(confidence)")
                        } else {
                            self.scheduleRemoveCensoring()
                        }
                    }
                default:
                    break
                }
            })
        }
        
        func applyCensoring() {
            //print("Applying censoring...")
            blurTimer?.invalidate()
            isBlurred = true
            blurTimer = nil
        }
        
        func scheduleRemoveCensoring() {
            if blurTimer == nil {
                //print("Scheduling removal of censoring...")
                blurTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
                    //print("Removing censoring...")
                    self.isBlurred = false
                    self.blurTimer = nil
                }
            }
        }
    }
    
    func makeUIView(context: Context) -> CameraPreviewLayer {
        let session = AVCaptureSession()
        session.sessionPreset = .high
        
        guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            return CameraPreviewLayer(session: session, isBlurred: $isBlurred)
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let input = try AVCaptureDeviceInput(device: frontCamera)
                if session.canAddInput(input) {
                    session.addInput(input)
                }
                
                session.startRunning()
            } catch {
                print("Error setting up camera input: \(error)")
            }
        }
        
        return CameraPreviewLayer(session: session, isBlurred: $isBlurred)
    }
    
    func updateUIView(_ uiView: CameraPreviewLayer, context: Context) {
        uiView.updateVideoOrientation()
    }
    
    static func dismantleUIView(_ uiView: CameraPreviewLayer, coordinator: ()) {
        uiView.captureSession.stopRunning()
    }
}
