//
//  CalibrationScene.swift
//  Ploong
//
//  Created by Matthew Fernando Anggrian on 11/05/26.
//

import SpriteKit

#if canImport(AppKit) && canImport(AVFoundation) && canImport(Vision)
import AppKit
#endif

final class CalibrationScene: SKScene {
    private var didSetupLayout = false
    private var hasConfirmedOpenPalm = false
    private var hasConfirmedFist = false
    private var didStartCountdown = false
    private var statusMessageOverride: String?

    #if canImport(AppKit) && canImport(AVFoundation) && canImport(Vision)
    private let handTrackingState = HandTrackingState()
    private var cameraPreviewView: PreviewContainerView?
    private var landmarkOverlayView: CalibrationLandmarkOverlayView?
    private var instructionLabel: NSTextField?
    private var statusLabel: NSTextField?
    private var countdownLabel: NSTextField?
    #else
    private weak var instructionNode: SKLabelNode?
    private weak var statusNode: SKLabelNode?
    private weak var countdownNode: SKLabelNode?
    #endif

    override func sceneDidLoad() {
        super.sceneDidLoad()
        backgroundColor = .black
        AudioManager.shared.stopMenuBgm()
    }

    override func didMove(to view: SKView) {
        super.didMove(to: view)

        if !didSetupLayout {
            didSetupLayout = true
            buildLayout()
        }

        attachCameraPreviewIfAvailable(to: view)
        startStatusUpdates()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        layoutOverlayViews()
    }

    override func willMove(from view: SKView) {
        super.willMove(from: view)
        removeAction(forKey: "gestureStatusUpdates")
        removeAction(forKey: "calibrationCompletionFlow")
        removeAction(forKey: "calibrationCountdown")

        #if canImport(AppKit) && canImport(AVFoundation) && canImport(Vision)
        HandGestureManager.shared.hideCalibrationPreview()
        cameraPreviewView?.removeFromSuperview()
        landmarkOverlayView?.removeFromSuperview()
        instructionLabel?.removeFromSuperview()
        statusLabel?.removeFromSuperview()
        countdownLabel?.removeFromSuperview()
        cameraPreviewView = nil
        landmarkOverlayView = nil
        instructionLabel = nil
        statusLabel = nil
        countdownLabel = nil
        #endif
    }

    private func buildLayout() {
        #if canImport(AppKit) && canImport(AVFoundation) && canImport(Vision)
        HandGestureManager.shared.onGestureChanged = nil
        #else
        let instruction = SKLabelNode(fontNamed: "AvenirNext-Bold")
        instruction.text = instructionText
        instruction.numberOfLines = 2
        instruction.fontSize = 24
        instruction.fontColor = .white
        instruction.horizontalAlignmentMode = .center
        instruction.verticalAlignmentMode = .center
        instruction.position = CGPoint(x: size.width * 0.5, y: size.height * 0.82)
        addChild(instruction)
        instructionNode = instruction

        let status = SKLabelNode(fontNamed: "AvenirNext-Bold")
        status.text = "No hand detected. Please position your hand in the frame."
        status.numberOfLines = 2
        status.fontSize = 22
        status.fontColor = .white
        status.horizontalAlignmentMode = .center
        status.verticalAlignmentMode = .center
        status.position = CGPoint(x: size.width * 0.5, y: size.height * 0.16)
        addChild(status)
        statusNode = status

        let countdown = SKLabelNode(fontNamed: "AvenirNext-Bold")
        countdown.fontSize = 96
        countdown.fontColor = .white
        countdown.horizontalAlignmentMode = .center
        countdown.verticalAlignmentMode = .center
        countdown.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        countdown.isHidden = true
        addChild(countdown)
        countdownNode = countdown
        #endif
    }

    private var instructionText: String {
        "FIST ✊ for the lower lane, OPEN PALM ✋ for the upper lane.\n(Perform both gestures to the camera to start the game)"
    }

    private func attachCameraPreviewIfAvailable(to view: SKView) {
        #if canImport(AppKit) && canImport(AVFoundation) && canImport(Vision)
        if cameraPreviewView == nil {
            let previewView = PreviewContainerView(frame: view.bounds)
            previewView.wantsLayer = true
            previewView.layer = CALayer()
            previewView.layer?.backgroundColor = NSColor.black.cgColor
            previewView.autoresizingMask = [.width, .height]
            view.addSubview(previewView)
            cameraPreviewView = previewView
        }

        if landmarkOverlayView == nil {
            let overlayView = CalibrationLandmarkOverlayView(frame: view.bounds)
            overlayView.autoresizingMask = [.width, .height]
            overlayView.landmarksProvider = { [weak self] in
                self?.handTrackingState.landmarks ?? .empty
            }
            view.addSubview(overlayView)
            landmarkOverlayView = overlayView
        }

        if instructionLabel == nil {
            let label = makeOverlayLabel(fontSize: 28)
            label.stringValue = instructionText
            view.addSubview(label)
            instructionLabel = label
        }

        if statusLabel == nil {
            let label = makeOverlayLabel(fontSize: 26)
            label.stringValue = calibrationMessage(for: HandGestureManager.shared.currentGesture)
            view.addSubview(label)
            statusLabel = label
        }

        if countdownLabel == nil {
            let label = makeOverlayLabel(fontSize: 100)
            label.isHidden = true
            view.addSubview(label)
            countdownLabel = label
        }

        layoutOverlayViews()

        if let cameraPreviewView {
            HandGestureManager.shared.attachCalibrationPreview(to: cameraPreviewView, state: handTrackingState)
        }
        #endif
    }

    #if canImport(AppKit) && canImport(AVFoundation) && canImport(Vision)
    private func makeOverlayLabel(fontSize: CGFloat) -> NSTextField {
        let label = NSTextField(labelWithString: "")
        label.alignment = .center
        label.maximumNumberOfLines = 3
        label.lineBreakMode = .byWordWrapping
        label.font = NSFont.boldSystemFont(ofSize: fontSize)
        label.textColor = .white
        label.backgroundColor = .clear
        label.drawsBackground = false
        label.isBordered = false
        label.isEditable = false
        label.isSelectable = false
        label.wantsLayer = true
        label.layer?.shadowColor = NSColor.black.cgColor
        label.layer?.shadowOpacity = 0.85
        label.layer?.shadowRadius = 5
        label.layer?.shadowOffset = CGSize(width: 0, height: -2)
        return label
    }
    #endif

    private func layoutOverlayViews() {
        #if canImport(AppKit) && canImport(AVFoundation) && canImport(Vision)
        guard let view else {
            return
        }

        cameraPreviewView?.frame = view.bounds
        landmarkOverlayView?.frame = view.bounds

        let horizontalInset: CGFloat = 52
        let labelWidth = max(0, view.bounds.width - horizontalInset * 2)
        instructionLabel?.frame = CGRect(
            x: horizontalInset,
            y: view.bounds.height * 0.73,
            width: labelWidth,
            height: 96
        )
        statusLabel?.frame = CGRect(
            x: horizontalInset,
            y: view.bounds.height * 0.1,
            width: labelWidth,
            height: 120
        )
        countdownLabel?.frame = CGRect(
            x: horizontalInset,
            y: view.bounds.height * 0.42,
            width: labelWidth,
            height: 130
        )
        #endif
    }

    private func startStatusUpdates() {
        let update = SKAction.run { [weak self] in
            guard let self else { return }

            #if canImport(AppKit) && canImport(AVFoundation) && canImport(Vision)
            let gesture = HandGestureManager.shared.currentGesture
            self.updateCalibrationProgress(with: gesture)
            self.setStatusMessage(self.calibrationMessage(for: gesture))
            self.landmarkOverlayView?.needsDisplay = true
            #else
            self.statusNode?.text = "Camera unavailable"
            #endif
        }

        run(.repeatForever(.sequence([update, .wait(forDuration: 0.1)])), withKey: "gestureStatusUpdates")
    }

    private func updateCalibrationProgress(with gesture: HandGesture) {
        guard !didStartCountdown else {
            return
        }

        switch gesture {
        case .point:
            if hasConfirmedFist, !hasConfirmedOpenPalm {
                hasConfirmedOpenPalm = true
                startCompletionFlow(secondGestureMessage: "OPEN PALM ✋ Confirmed.")
            } else if !hasConfirmedOpenPalm {
                hasConfirmedOpenPalm = true
            }
        case .fist:
            if hasConfirmedOpenPalm, !hasConfirmedFist {
                hasConfirmedFist = true
                startCompletionFlow(secondGestureMessage: "FIST ✊ Confirmed.")
            } else if !hasConfirmedFist {
                hasConfirmedFist = true
            }
        case .unrecognized, .unknown:
            break
        }
    }

    private func calibrationMessage(for gesture: HandGesture) -> String {
        if let statusMessageOverride {
            return statusMessageOverride
        }

        if hasConfirmedOpenPalm, hasConfirmedFist {
            return "Calibration Complete. Initializing Game..."
        }

        if hasConfirmedOpenPalm {
            return "OPEN PALM ✋ Confirmed. Awaiting FIST ✊ gesture."
        }

        if hasConfirmedFist {
            return "FIST ✊ Confirmed. Awaiting OPEN PALM ✋ gesture."
        }

        switch gesture {
        case .unknown:
            return "No hand detected. Please position your hand in the frame."
        case .unrecognized:
            return "Hand tracking active. Waiting for gesture..."
        case .point:
            return "OPEN PALM ✋ Confirmed. Awaiting FIST ✊ gesture."
        case .fist:
            return "FIST ✊ Confirmed. Awaiting OPEN PALM ✋ gesture."
        }
    }

    private func setStatusMessage(_ message: String) {
        #if canImport(AppKit) && canImport(AVFoundation) && canImport(Vision)
        statusLabel?.stringValue = message
        #else
        statusNode?.text = message
        #endif
    }

    private func startCompletionFlow(secondGestureMessage: String) {
        didStartCountdown = true
        statusMessageOverride = secondGestureMessage
        removeAction(forKey: "gestureStatusUpdates")
        setStatusMessage(secondGestureMessage)

        let sequence = SKAction.sequence([
            .wait(forDuration: 0.75),
            .run { [weak self] in
                self?.statusMessageOverride = "Calibration Complete. Initializing Game..."
                self?.setStatusMessage("Calibration Complete. Initializing Game...")
            },
            .wait(forDuration: 0.35),
            .run { [weak self] in self?.startCountdownToGameplay() }
        ])

        run(sequence, withKey: "calibrationCompletionFlow")
    }

    private func startCountdownToGameplay() {
        let sequence = SKAction.sequence([
            .run { [weak self] in self?.showCountdownText("3") },
            .wait(forDuration: 1.0),
            .run { [weak self] in self?.showCountdownText("2") },
            .wait(forDuration: 1.0),
            .run { [weak self] in self?.showCountdownText("1") },
            .wait(forDuration: 1.0),
            .run { [weak self] in self?.showCountdownText("GO") },
            .wait(forDuration: 0.25),
            .run { [weak self] in self?.presentGameLoop() }
        ])

        run(sequence, withKey: "calibrationCountdown")
    }

    private func showCountdownText(_ text: String) {
        #if canImport(AppKit) && canImport(AVFoundation) && canImport(Vision)
        countdownLabel?.stringValue = text
        countdownLabel?.alphaValue = 1
        countdownLabel?.isHidden = false
        #else
        countdownNode?.text = text
        countdownNode?.isHidden = false
        #endif
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            presentMenu()
            return
        }

        if event.keyCode == 36 || event.keyCode == 76 {
            presentGameLoop()
        }
    }

    private func presentMenu() {
        guard let view = view else {
            return
        }

        let scene = MenuScene(size: size)
        scene.scaleMode = scaleMode
        view.presentScene(scene)
    }

    private func presentGameLoop() {
        guard let view = view else {
            return
        }

        let scene = GameLoopScene(size: size)
        scene.scaleMode = scaleMode
        view.presentScene(scene)
    }
}

#if canImport(AppKit) && canImport(AVFoundation) && canImport(Vision)
private final class CalibrationLandmarkOverlayView: NSView {
    var landmarksProvider: (() -> HandLandmarkFrame)?

    override var isFlipped: Bool {
        true
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let landmarks = landmarksProvider?() else {
            return
        }

        NSColor.systemGreen.setStroke()
        for connection in landmarks.connections {
            let path = NSBezierPath()
            path.move(to: connection.start)
            path.line(to: connection.end)
            path.lineWidth = 4
            path.stroke()
        }

        NSColor.systemRed.setFill()
        for point in landmarks.points {
            let rect = CGRect(x: point.x - 6, y: point.y - 6, width: 12, height: 12)
            NSBezierPath(ovalIn: rect).fill()
        }
    }
}
#endif
