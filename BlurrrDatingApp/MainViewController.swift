import SwiftUI
import UIKit
import WebRTC

struct MainViewControllerRepresentable: UIViewControllerRepresentable {
    typealias UIViewControllerType = MainViewController
    
    var signalingHandler: SignalingHandler
    var webRTCHandler: WebRTCHandler
    @Binding var isLocalVideoActive: Bool
    @Binding var isRemoteVideoActive: Bool
    @Binding var signalingConnected: Bool
    @Binding var hasLocalSdp: Bool
    @Binding var localCandidateCount: Int
    @Binding var hasRemoteSdp: Bool
    @Binding var remoteCandidateCount: Int

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    func makeUIViewController(context: Context) -> MainViewController {
        let mainVC = MainViewController(signalClient: signalingHandler, webRTCHandler: webRTCHandler)
        context.coordinator.mainViewController = mainVC
        mainVC.onLocalVideoStateChange = { isActive in
            DispatchQueue.main.async {
                self.isLocalVideoActive = isActive
            }
        }
        mainVC.onRemoteVideoStateChange = { isActive in
            DispatchQueue.main.async {
                self.isRemoteVideoActive = isActive
            }
        }
        mainVC.onSignalingConnectedChange = { isConnected in
            DispatchQueue.main.async {
                self.signalingConnected = isConnected
            }
        }
        mainVC.onLocalSdpChange = { hasSdp in
            DispatchQueue.main.async {
                self.hasLocalSdp = hasSdp
            }
        }
        mainVC.onLocalCandidateCountChange = { count in
            DispatchQueue.main.async {
                self.localCandidateCount = count
            }
        }
        mainVC.onRemoteSdpChange = { hasSdp in
            DispatchQueue.main.async {
                self.hasRemoteSdp = hasSdp
            }
        }
        mainVC.onRemoteCandidateCountChange = { count in
            DispatchQueue.main.async {
                self.remoteCandidateCount = count
            }
        }
        return mainVC
    }

    func updateUIViewController(_ uiViewController: MainViewController, context: Context) {
        // Update the view controller if needed
    }

    class Coordinator: NSObject {
        var parent: MainViewControllerRepresentable
        var mainViewController: MainViewController?

        init(_ parent: MainViewControllerRepresentable) {
            self.parent = parent
        }

        func offer() {
            print("Coordinator offer called")
            mainViewController?.offer(nil)
        }

        func answer() {
            print("Coordinator answer called")
            mainViewController?.answer(nil)
        }
    }
}




class MainViewController: UIViewController {
    private let signalingHandler: SignalingHandler
    private let webRTCHandler: WebRTCHandler
    
    // UI Elements
    private let signalingStatusLabel = UILabel()
    private let localSdpStatusLabel = UILabel()
    private let localCandidatesLabel = UILabel()
    private let remoteSdpStatusLabel = UILabel()
    private let remoteCandidatesLabel = UILabel()
    private let webRTCStatusLabel = UILabel()
    private var localRenderer: RTCMTLVideoView?
    private var remoteRenderer: RTCMTLVideoView?
    
    public var onLocalVideoStateChange: ((Bool) -> Void)?
    public var onRemoteVideoStateChange: ((Bool) -> Void)?
    public var onSignalingConnectedChange: ((Bool) -> Void)?
    public var onLocalSdpChange: ((Bool) -> Void)?
    public var onLocalCandidateCountChange: ((Int) -> Void)?
    public var onRemoteSdpChange: ((Bool) -> Void)?
    public var onRemoteCandidateCountChange: ((Int) -> Void)?

    public var signalingConnected: Bool = false {
        didSet {
            DispatchQueue.main.async {
                self.signalingStatusLabel.text = self.signalingConnected ? "Connected" : "Not connected"
                self.signalingStatusLabel.textColor = self.signalingConnected ? .green : .red
                self.onSignalingConnectedChange?(self.signalingConnected)
            }
        }
    }
    
    public var hasLocalSdp: Bool = false {
        didSet {
            DispatchQueue.main.async {
                self.localSdpStatusLabel.text = self.hasLocalSdp ? "Yes" : "No"
                self.onLocalSdpChange?(self.hasLocalSdp)
            }
        }
    }
    
    private var localCandidateCount: Int = 0 {
        didSet {
            DispatchQueue.main.async {
                self.localCandidatesLabel.text = "\(self.localCandidateCount)"
                self.onLocalCandidateCountChange?(self.localCandidateCount)
            }
        }
    }
    
    public var hasRemoteSdp: Bool = false {
        didSet {
            DispatchQueue.main.async {
                self.remoteSdpStatusLabel.text = self.hasRemoteSdp ? "Yes" : "No"
                self.onRemoteSdpChange?(self.hasRemoteSdp)
            }
        }
    }
    
    private var remoteCandidateCount: Int = 0 {
        didSet {
            DispatchQueue.main.async {
                self.remoteCandidatesLabel.text = "\(self.remoteCandidateCount)"
                self.onRemoteCandidateCountChange?(self.remoteCandidateCount)
            }
        }
    }

    init(signalClient: SignalingHandler, webRTCHandler: WebRTCHandler) {
        self.signalingHandler = signalClient
        self.webRTCHandler = webRTCHandler
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "WebRTC Demo"
        setupUI()
        
        self.webRTCHandler.delegate = self
        self.signalingHandler.delegate = self
        self.signalingHandler.connect()
        
        // Setup video renderers
        setupVideoRenderers()
    }

    private func setupUI() {
        view.backgroundColor = .white
        
        let stackView = UIStackView(arrangedSubviews: [
            signalingStatusLabel, localSdpStatusLabel, localCandidatesLabel, remoteSdpStatusLabel, remoteCandidatesLabel, webRTCStatusLabel
        ])
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupVideoRenderers() {
        localRenderer = RTCMTLVideoView(frame: self.view.bounds)
        remoteRenderer = RTCMTLVideoView(frame: self.view.bounds)
        
        guard let localRenderer = localRenderer, let remoteRenderer = remoteRenderer else { return }
        
        localRenderer.videoContentMode = .scaleAspectFill
        remoteRenderer.videoContentMode = .scaleAspectFill
        
        view.addSubview(remoteRenderer)
        view.addSubview(localRenderer)
        
        self.webRTCHandler.LocalVideo(renderer: localRenderer)
        self.webRTCHandler.renderRemoteVideo(to: remoteRenderer)
        
        view.sendSubviewToBack(remoteRenderer)
    }
    
    @IBAction func offer(_ sender: UIButton?) {
        print("offer method called")
        self.webRTCHandler.offer { (sdp) in
            print("offer SDP created: \(sdp)")
            self.hasLocalSdp = true
            self.signalingHandler.send(sdp: sdp)
        }
    }
    
    @IBAction func answer(_ sender: UIButton?) {
        print("answer method called")
        self.webRTCHandler.answer { (localSdp) in
            print("answer SDP created: \(localSdp)")
            self.hasLocalSdp = true
            self.signalingHandler.send(sdp: localSdp)
        }
    }
    
    @IBAction private func videoDidTap(_ sender: UIButton) {
        print("GO TO VIDEO VIEW")
    }
    
    @IBAction func sendDataDidTap(_ sender: UIButton) {
        let alert = UIAlertController(title: "Send a message to the other peer",
                                      message: "This will be transferred over WebRTC data channel",
                                      preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "Message to send"
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Send", style: .default, handler: { [weak self, unowned alert] _ in
            guard let dataToSend = alert.textFields?.first?.text?.data(using: .utf8) else {
                return
            }
            self?.webRTCHandler.sendData(dataToSend)
        }))
        self.present(alert, animated: true, completion: nil)
    }
}

extension MainViewController: SignalManager {
    func signalClientDidConnect(_ signalingHandler: SignalingHandler) {
        print("Signal client connected")
        self.signalingConnected = true
    }
    
    func signalClientDidDisconnect(_ signalingHandler: SignalingHandler) {
        print("Signal client disconnected")
        self.signalingConnected = false
    }
    
    func signalClient(_ signalingHandler: SignalingHandler, didReceiveRemoteSdp sdp: RTCSessionDescription) {
        print("Received remote sdp: \(sdp)")
        self.webRTCHandler.set(remoteSdp: sdp) { (error) in
            print("Set remote sdp, error: \(String(describing: error))")
            self.hasRemoteSdp = true
            self.onRemoteVideoStateChange?(true)
        }
    }
    
    func signalClient(_ signalingHandler: SignalingHandler, didReceiveCandidate candidate: RTCIceCandidate) {
        print("Received remote candidate: \(candidate)")
        self.webRTCHandler.set(remoteCandidate: candidate) { error in
            print("Error setting remote candidate: \(String(describing: error))")
            self.remoteCandidateCount += 1
        }
    }
}

extension MainViewController: WebRTCManager {
    func webRTCHandler(_ client: WebRTCHandler, didDiscoverLocalCandidate candidate: RTCIceCandidate) {
        print("discovered local candidate: \(candidate)")
        self.localCandidateCount += 1
        self.signalingHandler.send(candidate: candidate)
    }
    
    func webRTCHandler(_ client: WebRTCHandler, didChangeConnectionState state: RTCIceConnectionState) {
        print("Connection state changed to: \(state)")
        let textColor: UIColor
        switch state {
        case .connected, .completed:
            textColor = .green
            self.onLocalVideoStateChange?(true)
            self.onRemoteVideoStateChange?(true)
        case .disconnected:
            textColor = .orange
            self.onLocalVideoStateChange?(false)
            self.onRemoteVideoStateChange?(false)
        case .failed, .closed:
            textColor = .red
            self.onLocalVideoStateChange?(false)
            self.onRemoteVideoStateChange?(false)
        case .new, .checking, .count:
            textColor = .black
        @unknown default:
            textColor = .black
        }
        DispatchQueue.main.async {
            self.webRTCStatusLabel.text = state.description.capitalized
            self.webRTCStatusLabel.textColor = textColor
        }
    }
    
    func webRTCHandler(_ client: WebRTCHandler, didReceiveData data: Data) {
        DispatchQueue.main.async {
            let message = String(data: data, encoding: .utf8) ?? "(Binary: \(data.count) bytes)"
            let alert = UIAlertController(title: "Message from WebRTC", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
}
