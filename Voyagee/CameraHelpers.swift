import SwiftUI
import AVFoundation
import Combine

// MARK: - Camera Manager

class CameraManager: NSObject, ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var isSessionRunning = false
    @Published var isCameraAvailable = false
    @Published var permissionDenied = false

    /// Normalized crop rect (0…1) relative to the preview view. Set by ScannerView.
    var cropRect: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1)
    /// The preview view size in points, needed to compute aspectFill mapping.
    var previewSize: CGSize = .zero

    let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "com.voyagee.camera")

    func configure() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    self?.sessionQueue.async { self?.setupSession() }
                } else {
                    DispatchQueue.main.async {
                        self?.isCameraAvailable = false
                        self?.permissionDenied = true
                    }
                }
            }
        case .authorized:
            DispatchQueue.main.async { self.permissionDenied = false }
            sessionQueue.async { [weak self] in self?.setupSession() }
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.isCameraAvailable = false
                self.permissionDenied = true
            }
        @unknown default:
            DispatchQueue.main.async { self.isCameraAvailable = false }
        }
    }

    private func setupSession() {
        guard !session.isRunning else { return }

        session.beginConfiguration()
        session.sessionPreset = .photo

        // Try back camera first, then fall back to any available video device
        let device: AVCaptureDevice? =
            AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
            ?? AVCaptureDevice.default(for: .video)

        guard let camera = device,
              let input = try? AVCaptureDeviceInput(device: camera) else {
            session.commitConfiguration()
            DispatchQueue.main.async { self.isCameraAvailable = false }
            return
        }

        if session.canAddInput(input) {
            session.addInput(input)
        }
        if session.canAddOutput(output) {
            session.addOutput(output)
        }

        session.commitConfiguration()
        session.startRunning()

        let running = session.isRunning
        DispatchQueue.main.async {
            self.isSessionRunning = running
            self.isCameraAvailable = running
        }
    }

    /// Current interface orientation angle for photo output.
    var currentRotationAngle: CGFloat = 90

    func takePhoto() {
        guard isCameraAvailable else { return }

        // Sync photo output orientation with the current interface orientation
        if let connection = output.connection(with: .video),
           connection.isVideoRotationAngleSupported(currentRotationAngle) {
            connection.videoRotationAngle = currentRotationAngle
        }

        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            self?.session.stopRunning()
        }
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let fullImage = UIImage(data: data) else { return }

        let cropped = Self.crop(fullImage, to: cropRect, previewSize: previewSize)

        DispatchQueue.main.async {
            self.capturedImage = cropped
        }
    }

    /// Crop a UIImage using a normalized rect (0…1) that was computed against
    /// a preview using `.resizeAspectFill`.
    private static func crop(_ image: UIImage, to normalizedRect: CGRect, previewSize: CGSize) -> UIImage {
        guard normalizedRect != CGRect(x: 0, y: 0, width: 1, height: 1),
              previewSize.width > 0, previewSize.height > 0 else { return image }

        // First, normalize orientation so cgImage matches image.size.
        let fixed = image.fixedOrientation()
        guard let cg = fixed.cgImage else { return image }

        // Use actual pixel dimensions from cgImage (not points from .size)
        let imgW = CGFloat(cg.width)
        let imgH = CGFloat(cg.height)
        let imgAspect = imgW / imgH
        let prevAspect = previewSize.width / previewSize.height

        // aspectFill: one axis fits exactly, the other overflows (centered).
        var visibleX: CGFloat = 0
        var visibleY: CGFloat = 0
        var visibleW: CGFloat = 1
        var visibleH: CGFloat = 1

        if imgAspect > prevAspect {
            visibleW = prevAspect / imgAspect
            visibleX = (1 - visibleW) / 2
        } else {
            visibleH = imgAspect / prevAspect
            visibleY = (1 - visibleH) / 2
        }

        let cropX = (visibleX + normalizedRect.origin.x * visibleW) * imgW
        let cropY = (visibleY + normalizedRect.origin.y * visibleH) * imgH
        let cropW = normalizedRect.width * visibleW * imgW
        let cropH = normalizedRect.height * visibleH * imgH

        let pixelRect = CGRect(x: cropX, y: cropY, width: cropW, height: cropH)
            .intersection(CGRect(x: 0, y: 0, width: imgW, height: imgH))

        guard !pixelRect.isEmpty,
              let cropped = cg.cropping(to: pixelRect.integral) else { return image }

        return UIImage(cgImage: cropped, scale: fixed.scale, orientation: .up)
    }
}

// MARK: - Camera Preview (UIViewRepresentable)

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    let cameraManager: CameraManager

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.cameraManager = cameraManager
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {
        uiView.previewLayer.session = session
    }

    /// Custom UIView that keeps the preview layer frame in sync with layout changes.
    class PreviewUIView: UIView {
        weak var cameraManager: CameraManager?

        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }

        var previewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            updateOrientation()
        }

        private func updateOrientation() {
            guard let connection = previewLayer.connection,
                  connection.isVideoRotationAngleSupported(0) || connection.isVideoRotationAngleSupported(90) else { return }

            let angle: CGFloat
            switch window?.windowScene?.interfaceOrientation {
            case .landscapeLeft:
                angle = 180
            case .landscapeRight:
                angle = 0
            case .portraitUpsideDown:
                angle = 270
            default:
                angle = 90
            }

            if connection.isVideoRotationAngleSupported(angle) {
                connection.videoRotationAngle = angle
            }
            // Keep photo output in sync
            cameraManager?.currentRotationAngle = angle
        }
    }
}

// MARK: - Image Picker (Photo Library)

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - UIImage Orientation Fix

extension UIImage {
    /// Re-draw the image as `.up` so that cgImage pixels match image.size coordinates.
    func fixedOrientation() -> UIImage {
        guard imageOrientation != .up else { return self }
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale  // Camera photos use scale=1; keep it so cgImage matches size.
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            draw(at: .zero)
        }
    }
}
