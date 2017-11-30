import UIKit
import AVFoundation
import Vision
import Delaunay

final class ViewController: UIViewController {
    private var session: AVCaptureSession?

    private let faceDetection = VNDetectFaceRectanglesRequest()
    private let faceLandmarks = VNDetectFaceLandmarksRequest()
    private let faceLandmarksDetectionRequest = VNSequenceRequestHandler()
    private let faceDetectionRequest = VNSequenceRequestHandler()

    private lazy var previewLayer: AVCaptureVideoPreviewLayer? = {
        guard let session = self.session else {
            return nil
        }
        var previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        return previewLayer
    }()

    private lazy var triangleView: TriangleView = {
        TriangleView(frame: view.bounds)
    }()

    private var frontCamera: AVCaptureDevice? = {
        AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera,
                                for: AVMediaType.video, position: .front)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        sessionPrepare()
        session?.startRunning()

        guard let previewLayer = previewLayer else {
            return
        }

        view.layer.addSublayer(previewLayer)

        view.insertSubview(triangleView, at: Int.max)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.frame
    }

    private func sessionPrepare() {
        session = AVCaptureSession()
        guard let session = session, let captureDevice = frontCamera else {
            return
        }

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

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        guard let attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault,
                                                              sampleBuffer,
                                                              kCMAttachmentMode_ShouldPropagate)
            as? [String: Any] else {
            return
        }
        let ciImage = CIImage(cvImageBuffer: pixelBuffer,
                              options: attachments)

        // leftMirrored for front camera
        let ciImageWithOrientation = ciImage.oriented(forExifOrientation: Int32(UIImageOrientation.leftMirrored.rawValue))

        detectFace(on: ciImageWithOrientation)
    }

}

extension ViewController {

    fileprivate func detectFace(on image: CIImage) {
        try? faceDetectionRequest.perform([faceDetection], on: image)
        if let results = faceDetection.results as? [VNFaceObservation] {
            if !results.isEmpty {
                faceLandmarks.inputFaceObservations = results
                detectLandmarks(on: image)
            }
        }
    }

    private func detectLandmarks(on image: CIImage) {
        try? faceLandmarksDetectionRequest.perform([faceLandmarks], on: image)
        guard let landmarksResults = faceLandmarks.results as? [VNFaceObservation] else {
            return
        }

        for observation in landmarksResults {
            if let boundingBox = faceLandmarks.inputFaceObservations?.first?.boundingBox {
                let faceBoundingBox = boundingBox.scaled(to: UIScreen.main.bounds.size)

                var maparr = [Vertex]()

                for (index, element) in convertPointsForFace(observation.landmarks?.allPoints,
                                                                  faceBoundingBox).enumerated() {
                    let point = CGPoint(x: (Double(UIScreen.main.bounds.size.width - element.point.x)),
                                        y: (Double(UIScreen.main.bounds.size.height - element.point.y)))
                    maparr.append(Vertex(point: point, id: index))
                }

                triangleView.recalculate(vertexes: maparr)
            }
        }
    }

    private func convertPointsForFace(_ landmark: VNFaceLandmarkRegion2D?,
                                      _ boundingBox: CGRect) -> [Vertex] {
        guard let points = landmark?.normalizedPoints else {
            return []
        }
        let faceLandmarkPoints = points.map { (point: CGPoint) -> Vertex in
            let pointX = point.x * boundingBox.width + boundingBox.origin.x
            let pointY = point.y * boundingBox.height + boundingBox.origin.y

            return Vertex(point: CGPoint(x: Double(pointX), y: Double(pointY)), id: 0)
        }

        return faceLandmarkPoints
    }

}
