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
    private var isTransitioningState = false
    private var statusMessageOverride: String?

    #if canImport(AppKit) && canImport(AVFoundation) && canImport(Vision)
    private let handTrackingState = HandTrackingState()
    private var cameraPreviewView: PreviewContainerView?
    private var topBackgroundView: NSView?
    private var bottomBackgroundView: NSView?
    private var landmarkOverlayView: CalibrationLandmarkOverlayView?
    private var instructionLabel: NSTextField?
    private var statusLabel: NSTextField?
    private var countdownLabel: NSTextField?
    #else
    private weak var topBackgroundNode: SKShapeNode?
    private weak var bottomBackgroundNode: SKShapeNode?
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
        
        #if canImport(AppKit) && canImport(AVFoundation) && canImport(Vision)
        // Mendaftarkan observer untuk mendeteksi perubahan ukuran jendela/full screen secara instan
        view.postsFrameChangedNotifications = true
        NotificationCenter.default.addObserver(self, selector: #selector(handleViewResize), name: NSView.frameDidChangeNotification, object: view)
        #endif
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        layoutOverlayViews()
        
        #if !canImport(AppKit)
        layoutSpriteKitFallback()
        #endif
    }

    override func willMove(from view: SKView) {
        super.willMove(from: view)
        removeAction(forKey: "gestureStatusUpdates")
        removeAction(forKey: "calibrationCompletionFlow")
        removeAction(forKey: "calibrationCountdown")
        removeAction(forKey: "stateTransitionDelay")

        #if canImport(AppKit) && canImport(AVFoundation) && canImport(Vision)
        // Membersihkan observer saat berpindah scene
        NotificationCenter.default.removeObserver(self, name: NSView.frameDidChangeNotification, object: view)
        
        HandGestureManager.shared.hideCalibrationPreview()
        cameraPreviewView?.removeFromSuperview()
        topBackgroundView?.removeFromSuperview()
        bottomBackgroundView?.removeFromSuperview()
        landmarkOverlayView?.removeFromSuperview()
        instructionLabel?.removeFromSuperview()
        statusLabel?.removeFromSuperview()
        countdownLabel?.removeFromSuperview()
        
        cameraPreviewView = nil
        topBackgroundView = nil
        bottomBackgroundView = nil
        landmarkOverlayView = nil
        instructionLabel = nil
        statusLabel = nil
        countdownLabel = nil
        #endif
    }

    #if canImport(AppKit) && canImport(AVFoundation) && canImport(Vision)
    @objc private func handleViewResize() {
        // Fungsi ini akan dipanggil otomatis setiap kali layar di resize/full screen
        layoutOverlayViews()
    }
    #endif

    private func buildLayout() {
        #if canImport(AppKit) && canImport(AVFoundation) && canImport(Vision)
        HandGestureManager.shared.onGestureChanged = nil
        #else
        // Fallback murni menggunakan proporsi persen tanpa nilai statis minimum
        let topBg = SKShapeNode()
        topBg.fillColor = SKColor.black.withAlphaComponent(0.50)
        topBg.strokeColor = .clear
        addChild(topBg)
        topBackgroundNode = topBg
        
        let bottomBg = SKShapeNode()
        bottomBg.fillColor = SKColor.black.withAlphaComponent(0.50)
        bottomBg.strokeColor = .clear
        addChild(bottomBg)
        bottomBackgroundNode = bottomBg
        
        let instruction = SKLabelNode(fontNamed: "AvenirNext-Bold")
        instruction.text = instructionText
        instruction.numberOfLines = 2
        instruction.fontColor = .white
        instruction.horizontalAlignmentMode = .center
        instruction.verticalAlignmentMode = .center
        addChild(instruction)
        instructionNode = instruction

        let status = SKLabelNode(fontNamed: "AvenirNext-Bold")
        status.text = "No hand detected.\nPlease position your hand in the frame."
        status.numberOfLines = 2
        status.fontColor = .white
        status.horizontalAlignmentMode = .center
        status.verticalAlignmentMode = .center
        addChild(status)
        statusNode = status

        let countdown = SKLabelNode(fontNamed: "AvenirNext-Bold")
        countdown.fontColor = .white
        countdown.horizontalAlignmentMode = .center
        countdown.verticalAlignmentMode = .center
        countdown.isHidden = true
        addChild(countdown)
        countdownNode = countdown
        
        layoutSpriteKitFallback()
        #endif
    }
    
    #if !canImport(AppKit)
    private func layoutSpriteKitFallback() {
        // Menggunakan proporsi tinggi murni (20% dari tinggi layar)
        let topHeight = size.height * 0.20
        let bottomHeight = size.height * 0.20
        
        topBackgroundNode?.path = CGPath(rect: CGRect(x: 0, y: size.height - topHeight, width: size.width, height: topHeight), transform: nil)
        bottomBackgroundNode?.path = CGPath(rect: CGRect(x: 0, y: 0, width: size.width, height: bottomHeight), transform: nil)
        
        // Ukuran font sama antara atas dan bawah
        let fontSize = size.width * 0.022
        
        // Menggunakan posisi Y persis di tengah background
        instructionNode?.position = CGPoint(x: size.width * 0.5, y: size.height - (topHeight * 0.5))
        instructionNode?.fontSize = fontSize
        
        statusNode?.position = CGPoint(x: size.width * 0.5, y: bottomHeight * 0.5)
        statusNode?.fontSize = fontSize
        
        countdownNode?.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        countdownNode?.fontSize = size.width * 0.10
    }
    #endif

    private var instructionText: String {
        "FIST ✊ for the lower lane, OPEN PALM ✋ for the upper lane.\n(Perform both gestures to the camera to start the game)"
    }

    private func attachCameraPreviewIfAvailable(to view: SKView) {
        #if canImport(AppKit) && canImport(AVFoundation) && canImport(Vision)
        
        // 1. Kamera Kamera / Frame Utama
        if cameraPreviewView == nil {
            let previewView = PreviewContainerView(frame: view.bounds)
            previewView.wantsLayer = true
            previewView.layer = CALayer()
            previewView.layer?.backgroundColor = NSColor.black.cgColor
            previewView.autoresizingMask = [.width, .height]
            view.addSubview(previewView)
            cameraPreviewView = previewView
        }

        // 2. Overlay Hitam Transparan (50% Opacity)
        if topBackgroundView == nil {
            let bgView = NSView()
            bgView.wantsLayer = true
            bgView.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.50).cgColor
            view.addSubview(bgView)
            topBackgroundView = bgView
        }
        
        if bottomBackgroundView == nil {
            let bgView = NSView()
            bgView.wantsLayer = true
            bgView.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.50).cgColor
            view.addSubview(bgView)
            bottomBackgroundView = bgView
        }
        
        // 3. Hand skeleton tracking layer
        if landmarkOverlayView == nil {
            let overlayView = CalibrationLandmarkOverlayView(frame: view.bounds)
            overlayView.autoresizingMask = [.width, .height]
            overlayView.landmarksProvider = { [weak self] in
                self?.handTrackingState.landmarks ?? .empty
            }
            view.addSubview(overlayView)
            landmarkOverlayView = overlayView
        }

        // 4. Label teks overlay
        if instructionLabel == nil {
            let label = makeOverlayLabel()
            label.stringValue = instructionText
            view.addSubview(label)
            instructionLabel = label
        }

        if statusLabel == nil {
            let label = makeOverlayLabel()
            label.stringValue = calibrationMessage(for: HandGestureManager.shared.currentGesture)
            view.addSubview(label)
            statusLabel = label
        }

        if countdownLabel == nil {
            let label = makeOverlayLabel()
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
    private func makeOverlayLabel() -> NSTextField {
        let label = NSTextField(labelWithString: "")
        label.alignment = .center
        label.maximumNumberOfLines = 3
        label.lineBreakMode = .byWordWrapping
        label.textColor = .white
        label.backgroundColor = .clear
        label.drawsBackground = false
        label.isBordered = false
        label.isEditable = false
        label.isSelectable = false
        label.wantsLayer = true
        
        label.layer?.shadowColor = NSColor.black.cgColor
        label.layer?.shadowOpacity = 0.85
        label.layer?.shadowRadius = 4
        label.layer?.shadowOffset = CGSize(width: 0, height: -2)
        return label
    }
#endif
    
    private func layoutOverlayViews() {
        #if canImport(AppKit) && canImport(AVFoundation) && canImport(Vision)
        guard let view else { return }
        let bounds = view.bounds

        cameraPreviewView?.frame = bounds
        landmarkOverlayView?.frame = bounds

        // 1. Hitung ukuran bar hitam secara relatif penuh tanpa nilai minimum statis
        let topHeight = bounds.height * 0.20
        let bottomHeight = bounds.height * 0.20

        topBackgroundView?.frame = CGRect(x: 0, y: bounds.height - topHeight, width: bounds.width, height: topHeight)
        bottomBackgroundView?.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bottomHeight)

        // 2. Hitung ukuran font secara dinamis proporsional (Ukuran atas dan bawah disamakan)
        let responsiveTextFontSize = bounds.width * 0.021
        let countdownFontSize = bounds.width * 0.10
        
        let fontName = "AvenirNext-Bold"
        instructionLabel?.font = NSFont(name: fontName, size: responsiveTextFontSize) ?? NSFont.boldSystemFont(ofSize: responsiveTextFontSize)
        statusLabel?.font = NSFont(name: fontName, size: responsiveTextFontSize) ?? NSFont.boldSystemFont(ofSize: responsiveTextFontSize)
        countdownLabel?.font = NSFont(name: fontName, size: countdownFontSize) ?? NSFont.boldSystemFont(ofSize: countdownFontSize)

        // 3. Sizing Frame teks secara fleksibel agar center secara presisi pada Y Axis
        let textInset = bounds.width * 0.05
        let textWidth = bounds.width - (textInset * 2.0)

        // Menghitung estimasi tinggi teks yang dibutuhkan (bungkus rapat-rapat)
        let textBoundingHeight = responsiveTextFontSize * 3.0
        let countdownTextHeight = countdownFontSize * 1.5

        // Penempatan Y-Axis center untuk label instruksi (atas)
        instructionLabel?.frame = CGRect(
            x: textInset,
            y: bounds.height - topHeight + (topHeight - textBoundingHeight) / 2.0,
            width: textWidth,
            height: textBoundingHeight
        )
        
        // Penempatan Y-Axis center untuk label status (bawah)
        statusLabel?.frame = CGRect(
            x: textInset,
            y: (bottomHeight - textBoundingHeight) / 2.0,
            width: textWidth,
            height: textBoundingHeight
        )
        
        // Penempatan X-Axis & Y-Axis tepat di tengah-tengah untuk countdown
        countdownLabel?.frame = CGRect(
            x: 0,
            y: (bounds.height - countdownTextHeight) / 2.0,
            width: bounds.width,
            height: countdownTextHeight
        )
        #endif
    }

    private func startStatusUpdates() {
        let update = SKAction.run { [weak self] in
            guard let self else { return }

            #if canImport(AppKit) && canImport(AVFoundation) && canImport(Vision)
            let gesture = HandGestureManager.shared.currentGesture
            self.updateCalibrationProgress(with: gesture)
            
            if !self.isTransitioningState {
                self.setStatusMessage(self.calibrationMessage(for: gesture))
            }
            self.landmarkOverlayView?.needsDisplay = true
            #else
            self.setStatusMessage("Camera unavailable")
            #endif
        }

        run(.repeatForever(.sequence([update, .wait(forDuration: 0.1)])), withKey: "gestureStatusUpdates")
    }

    private func updateCalibrationProgress(with gesture: HandGesture) {
        guard !didStartCountdown, !isTransitioningState else {
            return
        }

        switch gesture {
        case .point:
            if hasConfirmedFist, !hasConfirmedOpenPalm {
                transitionState(confirmMessage: "OPEN PALM ✋ Confirmed.", completion: {
                    self.hasConfirmedOpenPalm = true
                    self.startCompletionFlow()
                })
            } else if !hasConfirmedOpenPalm {
                transitionState(confirmMessage: "OPEN PALM ✋ Confirmed.", completion: {
                    self.hasConfirmedOpenPalm = true
                })
            }
        case .fist:
            if hasConfirmedOpenPalm, !hasConfirmedFist {
                transitionState(confirmMessage: "FIST ✊ Confirmed.", completion: {
                    self.hasConfirmedFist = true
                    self.startCompletionFlow()
                })
            } else if !hasConfirmedFist {
                transitionState(confirmMessage: "FIST ✊ Confirmed.", completion: {
                    self.hasConfirmedFist = true
                })
            }
        case .unrecognized, .unknown:
            break
        }
    }
    
    private func transitionState(confirmMessage: String, completion: @escaping () -> Void) {
        isTransitioningState = true
        setStatusMessage(confirmMessage)
        
        let waitSequence = SKAction.sequence([
            .wait(forDuration: 1.25),
            .run { [weak self] in
                self?.isTransitioningState = false
                completion()
            }
        ])
        
        run(waitSequence, withKey: "stateTransitionDelay")
    }

    private func calibrationMessage(for gesture: HandGesture) -> String {
        if let statusMessageOverride {
            return statusMessageOverride
        }

        if hasConfirmedOpenPalm, hasConfirmedFist {
            return "Calibration Complete.\nInitializing Game..."
        }

        if hasConfirmedOpenPalm {
            return "OPEN PALM ✋ Confirmed.\nAwaiting FIST ✊ gesture."
        }

        if hasConfirmedFist {
            return "FIST ✊ Confirmed.\nAwaiting OPEN PALM ✋ gesture."
        }

        switch gesture {
        case .unknown:
            return "No hand detected.\nPlease position your hand in the frame."
        case .unrecognized:
            return "Hand tracking active.\nWaiting for gesture..."
        case .point:
            return "OPEN PALM ✋ Confirmed.\nAwaiting FIST ✊ gesture."
        case .fist:
            return "FIST ✊ Confirmed.\nAwaiting OPEN PALM ✋ gesture."
        }
    }

    private func setStatusMessage(_ message: String) {
        #if canImport(AppKit) && canImport(AVFoundation) && canImport(Vision)
        guard statusLabel?.stringValue != message else { return }
        // Animasi transisi dihapus
        statusLabel?.stringValue = message
        #else
        guard statusNode?.text != message else { return }
        // Animasi transisi dihapus
        statusNode?.text = message
        #endif
    }

    private func startCompletionFlow() {
        didStartCountdown = true
        statusMessageOverride = "Calibration Complete.\nInitializing Game..."
        removeAction(forKey: "gestureStatusUpdates")
        setStatusMessage("Calibration Complete.\nInitializing Game...")

        let sequence = SKAction.sequence([
            .wait(forDuration: 1.0),
            .run { [weak self] in self?.startCountdownToGameplay() }
        ])

        run(sequence, withKey: "calibrationCompletionFlow")
    }

    private func startCountdownToGameplay() {
        // Background dan teks tidak lagi di-fade out di sini. Mereka akan tetap muncul
        // saat hitungan mundur berlangsung.
        
        let sequence = SKAction.sequence([
            .wait(forDuration: 0.5),
            .run { [weak self] in self?.showCountdownText("3") },
            .wait(forDuration: 1.0),
            .run { [weak self] in self?.showCountdownText("2") },
            .wait(forDuration: 1.0),
            .run { [weak self] in self?.showCountdownText("1") },
            .wait(forDuration: 1.0),
            .run { [weak self] in self?.showCountdownText("GO!") },
            .wait(forDuration: 0.5),
            .run { [weak self] in self?.presentGameLoop() }
        ])

        run(sequence, withKey: "calibrationCountdown")
    }

    private func showCountdownText(_ text: String) {
        #if canImport(AppKit) && canImport(AVFoundation) && canImport(Vision)
        // Animasi transisi dihapus
        countdownLabel?.stringValue = text
        countdownLabel?.isHidden = false
        #else
        // Animasi transisi dihapus
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
        guard let view = view else { return }
        let scene = MenuScene(size: size)
        scene.scaleMode = scaleMode
        view.presentScene(scene)
    }

    private func presentGameLoop() {
        guard let view = view else { return }
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
            path.lineWidth = max(2, frame.width * 0.003) // Ketebalan skeleton line ikut mengecil/membesar
            path.stroke()
        }

        NSColor.systemRed.setFill()
        let dotSize = max(4, frame.width * 0.008) // Ukuran titik merah ikut mengecil/membesar
        let halfDot = dotSize * 0.5
        for point in landmarks.points {
            let rect = CGRect(x: point.x - halfDot, y: point.y - halfDot, width: dotSize, height: dotSize)
            NSBezierPath(ovalIn: rect).fill()
        }
    }
}
#endif
