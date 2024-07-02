//import UIKit
//
//class ViewController: UIViewController {
//    var webRTCManager: WebRTCManager!
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        webRTCManager = WebRTCManager()
//        setupUI()
//        webRTCManager.startConnection()
//    }
//    
//    func setupUI() {
//        // Add local and remote views to the view controller's view
//        let localView = webRTCManager.localView!
//        let remoteView = webRTCManager.remoteView!
//        
//        localView.translatesAutoresizingMaskIntoConstraints = false
//        remoteView.translatesAutoresizingMaskIntoConstraints = false
//        
//        view.addSubview(localView)
//        view.addSubview(remoteView)
//        
//        NSLayoutConstraint.activate([
//            localView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
//            localView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
//            localView.widthAnchor.constraint(equalToConstant: 150),
//            localView.heightAnchor.constraint(equalToConstant: 200),
//            
//            remoteView.topAnchor.constraint(equalTo: view.topAnchor),
//            remoteView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//            remoteView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            remoteView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
//        ])
//    }
//}
