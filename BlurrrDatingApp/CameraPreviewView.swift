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
        private var processNextFrame = true

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
            processNextFrame.toggle()
            if !processNextFrame {
                return
            }

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
                        if confidence > 0.90 {
                            self.applyCensoring()
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
            blurTimer?.invalidate()
            isBlurred = true
            blurTimer = nil
        }
        
        func scheduleRemoveCensoring() {
            if blurTimer == nil {
                blurTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
                    self.isBlurred = false
                    self.blurTimer = nil
                }
            }
        }
        
        @objc func startSession() {
            DispatchQueue.global(qos: .background).async {
                if !self.captureSession.isRunning {
                    self.captureSession.startRunning()
                }
            }
        }
        
        @objc func stopSession() {
            DispatchQueue.global(qos: .background).async {
                if self.captureSession.isRunning {
                    self.captureSession.stopRunning()
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
        
        let cameraLayer = CameraPreviewLayer(session: session, isBlurred: $isBlurred)
        
        NotificationCenter.default.addObserver(cameraLayer, selector: #selector(cameraLayer.startSession), name: Notification.Name("startCameraSession"), object: nil)
        NotificationCenter.default.addObserver(cameraLayer, selector: #selector(cameraLayer.stopSession), name: Notification.Name("stopCameraSession"), object: nil)
        
        return cameraLayer
    }
    
    func updateUIView(_ uiView: CameraPreviewLayer, context: Context) {
        uiView.updateVideoOrientation()
    }
    
    static func dismantleUIView(_ uiView: CameraPreviewLayer, coordinator: ()) {
        uiView.stopSession()
    }
}
