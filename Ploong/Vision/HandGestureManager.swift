import SwiftUI

#if canImport(AppKit) && canImport(AVFoundation) && canImport(Vision)
import AppKit
@preconcurrency import AVFoundation
import Observation
import Vision

struct ContentView: View {
    var body: some View {
        HandTrackingView()
    }
}

private enum RuntimeEnvironment {
    static var isXcodePreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
            || ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PLAYGROUNDS"] == "1"
    }
}

@MainActor
@Observable
final class HandTrackingState {
    var cameraStatusText = "Checking camera permission..."
    var gestureText = "Show one hand to the camera"
    var landmarks: HandLandmarkFrame = .empty

    func apply(_ result: HandTrackingResult) {
        gestureText = result.gesture.displayText
        landmarks = result.landmarks
    }
}

struct HandLandmarkFrame: Sendable {
    var points: [CGPoint]
    var connections: [HandConnection]

    nonisolated static let empty = HandLandmarkFrame(points: [], connections: [])
}

struct HandConnection: Identifiable, Sendable {
    let id = UUID()
    let start: CGPoint
    let end: CGPoint
}

struct HandTrackingView: View {
    @State private var state = HandTrackingState()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color.gray.opacity(0.35)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                Text("Hand Gesture Camera Preview")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)

                ZStack {
                    if RuntimeEnvironment.isXcodePreview {
                        PreviewPlaceholderView()
                    } else {
                        HandTrackingContainerView(state: state)
                        HandLandmarkOverlay(landmarks: state.landmarks)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 520)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.25), lineWidth: 2)
                )
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.black.opacity(0.55))
                )

                VStack(alignment: .leading, spacing: 10) {
                    Text(RuntimeEnvironment.isXcodePreview ? "Preview mode" : state.cameraStatusText)
                        .font(.headline)
                    Text(RuntimeEnvironment.isXcodePreview ? "Camera disabled in Xcode canvas" : state.gestureText)
                        .font(.title3.weight(.semibold))
                }
                .foregroundStyle(.white)
                .padding(16)
                .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(24)
        }
        .frame(minWidth: 900, minHeight: 600)
    }
}

struct PreviewPlaceholderView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color.gray.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.2), lineWidth: 2)
                .padding(48)

            Image(systemName: "video")
                .font(.system(size: 72))
                .foregroundStyle(.white.opacity(0.7))
        }
    }
}

struct HandLandmarkOverlay: View {
    let landmarks: HandLandmarkFrame

    var body: some View {
        Canvas { context, _ in
            for connection in landmarks.connections {
                var path = Path()
                path.move(to: connection.start)
                path.addLine(to: connection.end)
                context.stroke(path, with: .color(.green), lineWidth: 3)
            }

            for point in landmarks.points {
                let rect = CGRect(x: point.x - 6, y: point.y - 6, width: 12, height: 12)
                context.fill(Path(ellipseIn: rect), with: .color(.red))
            }
        }
        .allowsHitTesting(false)
    }
}

struct HandTrackingContainerView: NSViewControllerRepresentable {
    let state: HandTrackingState

    func makeNSViewController(context: Context) -> HandTrackingViewController {
        HandTrackingViewController(state: state)
    }

    func updateNSViewController(_ nsViewController: HandTrackingViewController, context: Context) {}
}

final class PreviewContainerView: NSView {
    override func layout() {
        super.layout()
        layer?.sublayers?.forEach { $0.frame = bounds }
    }
}

final class HandTrackingViewController: NSViewController {
    private let state: HandTrackingState
    private let previewView = PreviewContainerView()

    init(state: HandTrackingState) {
        self.state = state
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        previewView.wantsLayer = true
        previewView.layer = CALayer()
        previewView.layer?.backgroundColor = NSColor.black.cgColor
        view = previewView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        HandGestureManager.shared.attachCalibrationPreview(to: previewView, state: state)
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        HandGestureManager.shared.hideCalibrationPreview()
    }
}

final class HandGestureManager {
    static let shared = HandGestureManager()

    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let videoOutputQueue = DispatchQueue(label: "camera.video.output.queue")
    private let handPoseProcessor: HandPoseProcessor

    private weak var calibrationState: HandTrackingState?
    private weak var previewView: PreviewContainerView?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var isConfigured = false
    private var lastBroadcastGesture: HandGesture = .unknown

    private(set) var currentGesture: HandGesture = .unknown
    var onGestureChanged: ((HandGesture) -> Void)?

    private init() {
        handPoseProcessor = HandPoseProcessor { result in
            Task { @MainActor in
                HandGestureManager.shared.handle(result)
            }
        }
    }

    func startDetection() {
        Task { await configureCameraAccess() }
    }

    func attachCalibrationPreview(to view: PreviewContainerView, state: HandTrackingState) {
        previewView = view
        calibrationState = state
        startDetection()
        installPreviewLayerIfNeeded()
    }

    func hideCalibrationPreview() {
        previewLayer?.removeFromSuperlayer()
        previewLayer = nil
        previewView = nil
        calibrationState = nil
        handPoseProcessor.previewLayerProvider = nil
    }

    func resetGestureChangeTracking() {
        lastBroadcastGesture = .unknown
    }

    private func handle(_ result: HandTrackingResult) {
        calibrationState?.cameraStatusText = "Camera active"
        calibrationState?.apply(result)

        currentGesture = result.gesture

        if result.gesture == .unknown {
            lastBroadcastGesture = .unknown
            return
        }

        guard result.gesture != lastBroadcastGesture else {
            return
        }

        lastBroadcastGesture = result.gesture
        onGestureChanged?(result.gesture)
    }

    private func configureCameraAccess() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            await MainActor.run {
                calibrationState?.cameraStatusText = "Camera active"
            }
            configureAndStartSession()
        case .notDetermined:
            await MainActor.run {
                calibrationState?.cameraStatusText = "Requesting camera access..."
            }
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            await MainActor.run {
                calibrationState?.cameraStatusText = granted ? "Camera active" : "Camera access denied"
                if !granted {
                    calibrationState?.gestureText = "Allow camera access in System Settings."
                }
            }
            if granted {
                configureAndStartSession()
            }
        case .denied, .restricted:
            await MainActor.run {
                calibrationState?.cameraStatusText = "Camera access denied"
                calibrationState?.gestureText = "Allow camera access in System Settings."
            }
        @unknown default:
            await MainActor.run {
                calibrationState?.cameraStatusText = "Unknown camera state"
                calibrationState?.gestureText = "Unable to access camera."
            }
        }
    }

    private func configureAndStartSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }

            if !self.isConfigured {
                self.session.beginConfiguration()
                self.session.sessionPreset = .high
                self.session.inputs.forEach { self.session.removeInput($0) }
                self.session.outputs.forEach { self.session.removeOutput($0) }

                guard
                    let device = AVCaptureDevice.default(for: .video),
                    let input = try? AVCaptureDeviceInput(device: device),
                    self.session.canAddInput(input)
                else {
                    Task { @MainActor in
                        self.calibrationState?.cameraStatusText = "Camera unavailable"
                        self.calibrationState?.gestureText = "No camera device was found."
                    }
                    self.session.commitConfiguration()
                    return
                }

                self.session.addInput(input)

                let output = AVCaptureVideoDataOutput()
                output.alwaysDiscardsLateVideoFrames = true
                output.videoSettings = [
                    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
                ]
                output.setSampleBufferDelegate(self.handPoseProcessor, queue: self.videoOutputQueue)

                guard self.session.canAddOutput(output) else {
                    Task { @MainActor in
                        self.calibrationState?.cameraStatusText = "Camera setup failed"
                        self.calibrationState?.gestureText = "Unable to configure video output."
                    }
                    self.session.commitConfiguration()
                    return
                }

                self.session.addOutput(output)
                output.connection(with: .video)?.videoRotationAngle = 0
                self.session.commitConfiguration()
                self.isConfigured = true
            }

            if !self.session.isRunning {
                self.session.startRunning()
            }

            DispatchQueue.main.async { [weak self] in
                self?.installPreviewLayerIfNeeded()
            }
        }
    }

    private func installPreviewLayerIfNeeded() {
        guard let previewView else {
            return
        }

        let layer: AVCaptureVideoPreviewLayer
        if let previewLayer {
            layer = previewLayer
            layer.session = session
        } else {
            layer = AVCaptureVideoPreviewLayer(session: session)
            layer.videoGravity = .resizeAspectFill
            previewLayer = layer
        }

        layer.frame = previewView.bounds
        layer.connection?.automaticallyAdjustsVideoMirroring = false
        layer.connection?.isVideoMirrored = true

        if layer.superlayer == nil {
            previewView.layer?.addSublayer(layer)
        }

        handPoseProcessor.previewLayerProvider = { [weak layer] in layer }
    }
}

final class HandPoseProcessor: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated(unsafe) private let handPoseRequest = VNDetectHumanHandPoseRequest()
    private let onObservationUpdate: @Sendable (HandTrackingResult) -> Void
    nonisolated(unsafe) var previewLayerProvider: (() -> AVCaptureVideoPreviewLayer?)?

    init(onObservationUpdate: @escaping @Sendable (HandTrackingResult) -> Void) {
        self.onObservationUpdate = onObservationUpdate
        super.init()
        handPoseRequest.maximumHandCount = 1
    }

    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        detectHandPose(sampleBuffer: sampleBuffer)
    }

    nonisolated private func detectHandPose(sampleBuffer: CMSampleBuffer) {
        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .up, options: [:])

        do {
            try handler.perform([handPoseRequest])

            guard let observation = handPoseRequest.results?.first else {
                onObservationUpdate(HandTrackingResult(gesture: .unknown, landmarks: .empty))
                return
            }

            let points = try observation.recognizedPoints(.all)
            let gesture = classifyGesture(from: points)
            let landmarks = buildLandmarks(from: points)
            onObservationUpdate(HandTrackingResult(gesture: gesture, landmarks: landmarks))
        } catch {
            onObservationUpdate(HandTrackingResult(gesture: .unknown, landmarks: .empty))
        }
    }

    nonisolated private func classifyGesture(from points: [VNHumanHandPoseObservation.JointName: VNRecognizedPoint]) -> HandGesture {
        func isExtended(_ tip: VNHumanHandPoseObservation.JointName, _ pip: VNHumanHandPoseObservation.JointName) -> Bool {
            guard
                let tipPoint = points[tip], tipPoint.confidence > 0.3,
                let pipPoint = points[pip], pipPoint.confidence > 0.3
            else {
                return false
            }

            return tipPoint.location.y > pipPoint.location.y
        }

        let indexOpen = isExtended(.indexTip, .indexPIP)
        let middleOpen = isExtended(.middleTip, .middlePIP)
        let ringOpen = isExtended(.ringTip, .ringPIP)
        let littleOpen = isExtended(.littleTip, .littlePIP)
        let openFingerCount = [indexOpen, middleOpen, ringOpen, littleOpen].filter { $0 }.count

        if openFingerCount == 0 {
            return .fist
        }

        if indexOpen || openFingerCount > 1 {
            return .point
        }

        return .unrecognized
    }

    nonisolated private func buildLandmarks(
        from points: [VNHumanHandPoseObservation.JointName: VNRecognizedPoint]
    ) -> HandLandmarkFrame {
        let jointGroups: [[VNHumanHandPoseObservation.JointName]] = [
            [.wrist, .thumbCMC, .thumbMP, .thumbIP, .thumbTip],
            [.wrist, .indexMCP, .indexPIP, .indexDIP, .indexTip],
            [.wrist, .middleMCP, .middlePIP, .middleDIP, .middleTip],
            [.wrist, .ringMCP, .ringPIP, .ringDIP, .ringTip],
            [.wrist, .littleMCP, .littlePIP, .littleDIP, .littleTip]
        ]

        let convertedPoints = points.compactMapValues { recognizedPoint -> CGPoint? in
            guard recognizedPoint.confidence > 0.3 else { return nil }
            return convertToLayerPoint(recognizedPoint.location)
        }

        let pointValues = Array(convertedPoints.values)
        let connections = jointGroups.flatMap { group -> [HandConnection] in
            zip(group, group.dropFirst()).compactMap { startJoint, endJoint in
                guard
                    let start = convertedPoints[startJoint],
                    let end = convertedPoints[endJoint]
                else {
                    return nil
                }

                return HandConnection(start: start, end: end)
            }
        }

        return HandLandmarkFrame(points: pointValues, connections: connections)
    }

    nonisolated private func convertToLayerPoint(_ point: CGPoint) -> CGPoint? {
        guard let previewLayer = previewLayerProvider?() else { return nil }
        let capturePoint = CGPoint(x: point.x, y: 1 - point.y)
        return previewLayer.layerPointConverted(fromCaptureDevicePoint: capturePoint)
    }
}

struct HandTrackingResult: Sendable {
    let gesture: HandGesture
    let landmarks: HandLandmarkFrame
}

#else

struct ContentView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "camera.slash")
                .font(.system(size: 40))
            Text("This target does not support camera-based hand tracking.")
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

#endif

#Preview {
    ContentView()
}
