import AVFoundation
import SwiftUI

/// Finds cameras (built-in and, on iOS 17+, external UVC cameras) and runs a capture session.
final class CameraManager: NSObject, ObservableObject {
    @Published var devices: [AVCaptureDevice] = []
    @Published var selectedID: String?
    @Published var status: String = "Starting…"
    @Published var authorized = false

    let session = AVCaptureSession()
    private let queue = DispatchQueue(label: "camera.session.queue")
    private var observers: [NSObjectProtocol] = []

    override init() {
        super.init()
        // Refresh the list when a camera is plugged in or removed.
        let nc = NotificationCenter.default
        observers.append(nc.addObserver(forName: .AVCaptureDeviceWasConnected, object: nil, queue: .main) { [weak self] _ in
            self?.refreshDevices()
        })
        observers.append(nc.addObserver(forName: .AVCaptureDeviceWasDisconnected, object: nil, queue: .main) { [weak self] _ in
            self?.refreshDevices()
        })
    }

    deinit { observers.forEach(NotificationCenter.default.removeObserver) }

    func start() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            authorized = true
            refreshDevices()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.authorized = granted
                    granted ? self?.refreshDevices() : (self?.status = "Camera permission denied. Enable it in Settings.")
                }
            }
        default:
            status = "Camera permission denied. Enable it in Settings."
        }
    }

    func refreshDevices() {
        var types: [AVCaptureDevice.DeviceType] = [.builtInWideAngleCamera]
        if #available(iOS 17.0, *) {
            types.append(.external)
        }
        let discovery = AVCaptureDevice.DiscoverySession(deviceTypes: types, mediaType: .video, position: .unspecified)
        devices = discovery.devices

        if devices.isEmpty {
            status = "No camera found."
            return
        }
        // Prefer an external camera when one is present.
        if selectedID == nil || !devices.contains(where: { $0.uniqueID == selectedID }) {
            if #available(iOS 17.0, *), let ext = devices.first(where: { $0.deviceType == .external }) {
                selectedID = ext.uniqueID
            } else {
                selectedID = devices.first?.uniqueID
            }
        }
        applySelection()
    }

    func select(_ id: String) {
        selectedID = id
        applySelection()
    }

    private func applySelection() {
        guard let id = selectedID, let device = devices.first(where: { $0.uniqueID == id }) else { return }
        queue.async { [weak self] in
            guard let self else { return }
            self.session.beginConfiguration()
            self.session.inputs.forEach { self.session.removeInput($0) }
            do {
                let input = try AVCaptureDeviceInput(device: device)
                if self.session.canAddInput(input) {
                    self.session.addInput(input)
                }
                self.session.commitConfiguration()
                if !self.session.isRunning { self.session.startRunning() }
                DispatchQueue.main.async { self.status = "Using: \(device.localizedName)" }
            } catch {
                self.session.commitConfiguration()
                DispatchQueue.main.async { self.status = "Could not open camera: \(error.localizedDescription)" }
            }
        }
    }

    func stop() {
        queue.async { [weak self] in self?.session.stopRunning() }
    }
}

/// SwiftUI wrapper around AVCaptureVideoPreviewLayer.
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspect
        view.backgroundColor = .black
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}
}
