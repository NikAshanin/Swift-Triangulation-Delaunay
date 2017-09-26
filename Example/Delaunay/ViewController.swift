import UIKit
import AVFoundation
import Vision
import Delaunay

final class ViewController: UIViewController {
    var session: AVCaptureSession?

    let faceDetection = VNDetectFaceRectanglesRequest()
    let faceLandmarks = VNDetectFaceLandmarksRequest()
    let faceLandmarksDetectionRequest = VNSequenceRequestHandler()
    let faceDetectionRequest = VNSequenceRequestHandler()

    lazy var previewLayer: AVCaptureVideoPreviewLayer? = {
        guard let session = self.session else { return nil }
        var previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        return previewLayer
    }()

    private lazy var triangleView: TriangleView = {
        let triangleView = TriangleView(frame: view.bounds)
        return triangleView
    }()

    var frontCamera: AVCaptureDevice? = {
        return AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera,
                                       for: AVMediaType.video, position: .front)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        sessionPrepare()
        session?.startRunning()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.frame
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard let previewLayer = previewLayer else { return }

        view.layer.addSublayer(previewLayer)

        view.insertSubview(triangleView, at: Int.max)
    }

    func sessionPrepare() {
        session = AVCaptureSession()
        guard let session = session, let captureDevice = frontCamera else { return }

        do {
            let deviceInput = try AVCaptureDeviceInput(device: captureDevice)
            session.beginConfiguration()

            if session.canAddInput(deviceInput) {
                session.addInput(deviceInput)
            }

            let output = AVCaptureVideoDataOutput()
            output.videoSettings = [
            String(kCVPixelBufferPixelFormatTypeKey): Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
            ]

            output.alwaysDiscardsLateVideoFrames = true

            if session.canAddOutput(output) {
                session.addOutput(output)
            }

            session.commitConfiguration()
            let queue = DispatchQueue(label: "output.queue")
            output.setSampleBufferDelegate(self, queue: queue)
            print("setup delegate")
        } catch {
            print("can't setup session")
        }
    }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {

        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)

        let attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate)
        let ciImage = CIImage(cvImageBuffer: pixelBuffer!, options: (attachments as? [String : Any]?)!)

        // leftMirrored for front camera
        let ciImageWithOrientation = ciImage.oriented(forExifOrientation: Int32(UIImageOrientation.leftMirrored.rawValue))

        detectFace(on: ciImageWithOrientation)
    }

}

extension ViewController {

    func detectFace(on image: CIImage) {
        try? faceDetectionRequest.perform([faceDetection], on: image)
        if let results = faceDetection.results as? [VNFaceObservation] {
            if !results.isEmpty {
                faceLandmarks.inputFaceObservations = results
                detectLandmarks(on: image)
            }
        }
    }

    func detectLandmarks(on image: CIImage) {
        try? faceLandmarksDetectionRequest.perform([faceLandmarks], on: image)
        if let landmarksResults = faceLandmarks.results as? [VNFaceObservation] {
            for observation in landmarksResults {
                if let boundingBox = self.faceLandmarks.inputFaceObservations?.first?.boundingBox {
                    let faceBoundingBox = boundingBox.scaled(to: UIScreen.main.bounds.size)

                    var maparr = [Vertex]()

                    for (index, element) in self.convertPointsForFace(observation.landmarks?.allPoints,
                                                                      faceBoundingBox).enumerated() {
                        maparr.append(Vertex(x: (Double(UIScreen.main.bounds.size.width - CGFloat(element.x))),
                                             y: (Double(UIScreen.main.bounds.size.height - CGFloat(element.y))),
                                             id: index))
                    }

                    triangleView.recalculate(vertexes: maparr)
                }
            }
        }
    }

    func convertPointsForFace(_ landmark: VNFaceLandmarkRegion2D?, _ boundingBox: CGRect) -> [Vertex] {
        if let points = landmark?.normalizedPoints {
            let faceLandmarkPoints = points.map { (point: CGPoint) -> Vertex in
                let pointX = point.x * boundingBox.width + boundingBox.origin.x
                let pointY = point.y * boundingBox.height + boundingBox.origin.y

                return Vertex(x: Double(pointX), y: Double(pointY), id: 0)
            }

            return faceLandmarkPoints
        }

        return []
    }

}
