import UIKit
import ARKit

class ARFaceTrackingViewController: UIViewController, ARSCNViewDelegate {
    var sceneView: ARSCNView!
    var statusLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupSceneView()
        setupStatusLabel()
    }

    func setupSceneView() {
        sceneView = ARSCNView()
        sceneView.delegate = self
        sceneView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sceneView)

        NSLayoutConstraint.activate([
            sceneView.topAnchor.constraint(equalTo: view.topAnchor),
            sceneView.leftAnchor.constraint(equalTo: view.leftAnchor),
            sceneView.rightAnchor.constraint(equalTo: view.rightAnchor),
            sceneView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let configuration = ARFaceTrackingConfiguration()
        sceneView.session.run(configuration)
    }

    func setupStatusLabel() {
        statusLabel = UILabel()
        view.addSubview(statusLabel)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.backgroundColor = .black.withAlphaComponent(0.7)
        statusLabel.textColor = .white
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0

        NSLayoutConstraint.activate([
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            statusLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
            statusLabel.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20)
        ])
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }

        DispatchQueue.main.async {
            // Burada yüzün boyutuna ve konumuna dayalı bir mesafe ve açı hesaplaması yapabilirsiniz.
            // Örnek hesaplama için aşağıdaki fonksiyonları kullanabilirsiniz.
        }
    }

    // Yüzün boyutuna ve konumuna dayalı basit bir mesafe ve açı hesaplama fonksiyonları
    // ...
}
