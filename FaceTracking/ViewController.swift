import UIKit
import AVFoundation
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    var captureSession: AVCaptureSession?
    var videoDataOutput: AVCaptureVideoDataOutput?
    var videoDataOutputQueue: DispatchQueue?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var statusLabel: UILabel?
    let faceMeasurement = FaceMeasurement()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let faceTrackingButton = UIButton(frame: CGRect(x: 100, y: 100, width: 200, height: 50))
        faceTrackingButton.backgroundColor = .blue
        faceTrackingButton.setTitle("Yüz Takibi Başlat", for: .normal)
        
        // Butonu görünüme ekleme
        self.view.addSubview(faceTrackingButton)
        
        
        setupCamera()
        setupUI()
        
        
    }
    
    func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .photo
        
        guard let camera = AVCaptureDevice.default(for: .video),
              let cameraInput = try? AVCaptureDeviceInput(device: camera),
              captureSession?.canAddInput(cameraInput) == true else {
            fatalError("Kamera erişimi sağlanamıyor.")
        }
        
        captureSession?.addInput(cameraInput)
        
        videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutputQueue = DispatchQueue(label: "VideoDataOutputQueue")
        videoDataOutput?.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        videoDataOutput?.alwaysDiscardsLateVideoFrames = true
        
        guard captureSession?.canAddOutput(videoDataOutput!) == true else {
            fatalError("Video çıkışı eklenemiyor.")
        }
        
        captureSession?.addOutput(videoDataOutput!)
        setupPreviewLayer()
        
        // AVCaptureSession'ı arka plan iş parçacığında başlat
        DispatchQueue.global(qos: .background).async {
            self.captureSession?.startRunning()
        }
    }
    
    func setupPreviewLayer() {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        previewLayer?.videoGravity = .resizeAspectFill
        DispatchQueue.main.async {
            self.previewLayer?.frame = self.view.bounds
            self.view.layer.addSublayer(self.previewLayer!)
        }
    }
    
    func setupUI() {
        guard let label = statusLabel else { return }
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Yüz Tespiti Aktif"
        label.textColor = .white
        // ... other properties and methods
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            label.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
            label.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20)
        ])
        
    }
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        var requestOptions: [VNImageOption : Any] = [:]
        if let cameraIntrinsicData = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil) {
            requestOptions = [.cameraIntrinsics: cameraIntrinsicData]
        }
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: requestOptions)
        let faceDetectionRequest = VNDetectFaceRectanglesRequest(completionHandler: { [weak self] request, error in
            guard let strongSelf = self else { return }
            if error != nil {
                DispatchQueue.main.async {
                    strongSelf.statusLabel?.text = "Yüz Tespiti Hatası"
                }
                return
            }
            if let results = request.results as? [VNFaceObservation] {
                DispatchQueue.main.async {
                    strongSelf.handleDetectedFaces(faces: results)
                }
            }
        })
        try? imageRequestHandler.perform([faceDetectionRequest])
    }
    
    func handleDetectedFaces(faces: [VNFaceObservation]) {
           DispatchQueue.main.async {
               // Önceki yüz çerçevelerini temizleyin
               self.view.subviews.forEach { subview in
                   if subview is FaceView {
                       subview.removeFromSuperview()
                   }
               }

               // Yeni tespit edilen yüzler için çerçeve oluşturun ve mesafe/açı hesaplayın
               faces.forEach { faceObservation in
                   var faceRect = self.transformBoundingBox(faceObservation.boundingBox)
                   if faceRect.width > faceRect.height {
                       faceRect.origin.y -= (faceRect.width - faceRect.height) / 2
                       faceRect.size.height = faceRect.width
                   } else {
                       faceRect.origin.x -= (faceRect.height - faceRect.width) / 2
                       faceRect.size.width = faceRect.height
                   }
                   let faceView = FaceView(frame: faceRect)
                   self.view.addSubview(faceView)
                   self.view.bringSubviewToFront(faceView)

                   // Mesafe ve açı hesaplamaları
                   let distance = self.faceMeasurement.calculateDistance(from: faceRect, cameraFieldOfView: 60.0, knownFaceWidth: 0.14) // Örnek değerler
                   let angle = self.faceMeasurement.calculateAngle(from: faceRect, in: self.view.bounds.size)

                   // Hesaplanan değerleri göstermek için etiket ekleme (bu bir örnektir, uygulamanıza uygun şekilde düzenleyebilirsiniz)
                   let infoLabel = UILabel(frame: CGRect(x: faceRect.origin.x, y: faceRect.origin.y - 30, width: faceRect.width, height: 30))
                   infoLabel.text = String(format: "Mesafe: %.2f m, Açı: %.2f°", distance, angle)
                   infoLabel.backgroundColor = .black
                   infoLabel.textColor = .white
                   infoLabel.textAlignment = .center
                   self.view.addSubview(infoLabel)
               }
           }
       }

    
    func transformBoundingBox(_ boundingBox: CGRect) -> CGRect {
        // Burada, boundingBox'ı ekrandaki koordinatlara dönüştürme işlemi yapılır.
        // Bu işlem, cihazın oryantasyonuna ve kamera önizleme katmanının özelliklerine bağlıdır.
        // Dönüştürme işlemi örnek olarak aşağıda verilmiştir:
        let size = previewLayer!.bounds.size
        let rect = VNImageRectForNormalizedRect(boundingBox, Int(size.width), Int(size.height))
        return rect
    }
}
    
    class FaceView: UIView {
        override init(frame: CGRect) {
            super.init(frame: frame)
            self.backgroundColor = .clear  // Arkaplanın şeffaf olmasını sağlar
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func draw(_ rect: CGRect) {
            guard let context = UIGraphicsGetCurrentContext() else { return }
            
            // Oval çerçevenin kalınlığını ayarla
            let lineWidth: CGFloat = 3.0
            context.setLineWidth(lineWidth)
            context.setStrokeColor(UIColor.green.cgColor)
            
            // Oval çerçeveyi çiz
            let path = UIBezierPath(ovalIn: rect.insetBy(dx: lineWidth / 2, dy: lineWidth / 2))
            path.stroke()
        }
    }
    
    class FaceMeasurement {
        
        // Bu metod, bir yüzün bounding box'ını alır ve yüzün kameraya olan mesafesini hesaplar
        func calculateDistance(from boundingBox: CGRect, cameraFieldOfView: CGFloat, knownFaceWidth: CGFloat) -> CGFloat {
            // Kamera açısını ve yüzün ekran üzerindeki genişliğini kullanarak mesafeyi hesaplayın
            // Bu sadece bir yaklaşımdır ve gerçek uygulamada kalibre edilmelidir
            let faceWidthOnScreen = boundingBox.width
            let distance = (knownFaceWidth / 2) / tan(cameraFieldOfView / 2 * .pi / 180) / faceWidthOnScreen
            return distance
        }
        
        // Bu metod, yüzün bounding box'ından yüzün kameraya olan açısını hesaplar
        func calculateAngle(from boundingBox: CGRect, in viewSize: CGSize) -> CGFloat {
            // Yüzün merkez noktasını bulun
            let faceCenter = CGPoint(x: boundingBox.midX, y: boundingBox.midY)
            // Yüzün merkezinin ekranın merkezine göre x koordinatındaki sapmasını hesaplayın
            let viewCenter = CGPoint(x: viewSize.width / 2, y: viewSize.height / 2)
            let angle = atan2(faceCenter.y - viewCenter.y, faceCenter.x - viewCenter.x) * 180 / .pi
            return angle
        }
    }
    

