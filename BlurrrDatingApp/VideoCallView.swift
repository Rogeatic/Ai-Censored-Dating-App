import SwiftUI
import WebRTC

struct VideoView: UIViewControllerRepresentable {
    let webRTCHandler: WebRTCHandler

    func makeUIViewController(context: Context) -> VideoViewController {
        return VideoViewController(webRTCHandler: webRTCHandler)
    }

    func updateUIViewController(_ uiViewController: VideoViewController, context: Context) {
        // No update logic needed for now
    }
}

class VideoViewController: UIViewController {

    @IBOutlet private weak var localVideoView: UIView?
    private let webRTCHandler: WebRTCHandler

    init(webRTCHandler: WebRTCHandler) {
        self.webRTCHandler = webRTCHandler
        super.init(nibName: String(describing: VideoViewController.self), bundle: Bundle.main)
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let localRenderer = RTCMTLVideoView(frame: self.localVideoView?.frame ?? CGRect.zero)
        let remoteRenderer = RTCMTLVideoView(frame: self.view.frame)
        localRenderer.videoContentMode = .scaleAspectFill
        remoteRenderer.videoContentMode = .scaleAspectFill

        self.webRTCHandler.LocalVideo(renderer: localRenderer)
        self.webRTCHandler.renderRemoteVideo(to: remoteRenderer)
        
        if let localVideoView = self.localVideoView {
            self.embedView(localRenderer, into: localVideoView)
        }
        self.embedView(remoteRenderer, into: self.view)
        self.view.sendSubviewToBack(remoteRenderer)
    }
    
    private func embedView(_ view: UIView, into containerView: UIView) {
        containerView.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|",
                                                                    options: [],
                                                                    metrics: nil,
                                                                    views: ["view":view]))
        
        containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|",
                                                                    options: [],
                                                                    metrics: nil,
                                                                    views: ["view":view]))
        containerView.layoutIfNeeded()
    }
    
    @IBAction private func backDidTap(_ sender: Any) {
        self.dismiss(animated: true)
    }
}
