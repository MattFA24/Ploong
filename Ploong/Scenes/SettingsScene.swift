//
//  SettingsScene.swift
//  Ploong
//
//  Created by Matthew Fernando Anggrian on 11/05/26.
//

import SpriteKit

final class SettingsScene: SKScene {
    private var didSetupLayout = false
    private var sliders: [SliderNode] = []
    private weak var activeSlider: SliderNode?
    private var backgroundNodes: [SKSpriteNode] = []
    private weak var brightnessSlider: SliderNode?

    override func sceneDidLoad() {
        super.sceneDidLoad()
        backgroundColor = .clear
    }

    override func didMove(to view: SKView) {
        super.didMove(to: view)

        if !didSetupLayout {
            didSetupLayout = true
            buildLayout()
        }
    }

    private func buildLayout() {
        addScrollingBackground()
        applyBackgroundBrightness(loadBackgroundBrightness())

        let dimmer = SKShapeNode(rectOf: size)
        dimmer.fillColor = NSColor(white: 0, alpha: 0.35)
        dimmer.strokeColor = .clear
        dimmer.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        dimmer.zPosition = 0
        addChild(dimmer)

        let modalSize = CGSize(width: size.width * 0.82, height: size.height * 0.76)
        let modal = SKShapeNode(rectOf: modalSize, cornerRadius: 28)
        modal.fillColor = .white
        modal.strokeColor = .clear
        modal.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        modal.zPosition = 1
        addChild(modal)

        let closeButton = SKShapeNode(circleOfRadius: 26)
        closeButton.name = "closeButton"
        closeButton.fillColor = NSColor(white: 0.7, alpha: 1)
        closeButton.strokeColor = NSColor(white: 0.4, alpha: 1)
        closeButton.position = CGPoint(x: -modalSize.width * 0.5 + 44, y: modalSize.height * 0.5 - 44)
        closeButton.zPosition = 2
        modal.addChild(closeButton)

        let closeLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        closeLabel.text = "X"
        closeLabel.fontSize = 22
        closeLabel.fontColor = .white
        closeLabel.verticalAlignmentMode = .center
        closeLabel.zPosition = 3
        closeButton.addChild(closeLabel)

        let preview = SKShapeNode(rectOf: CGSize(width: modalSize.width * 0.55, height: modalSize.height * 0.35), cornerRadius: 12)
        preview.fillColor = NSColor(white: 0.95, alpha: 1)
        preview.strokeColor = NSColor(white: 0.85, alpha: 1)
        preview.position = CGPoint(x: 0, y: modalSize.height * 0.2)
        preview.zPosition = 2
        modal.addChild(preview)

        let previewLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        previewLabel.text = "Game preview"
        previewLabel.fontSize = 20
        previewLabel.fontColor = .black
        previewLabel.verticalAlignmentMode = .center
        preview.addChild(previewLabel)

        let sliderLength = modalSize.width * 0.55
        let leftColumnX = -modalSize.width * 0.22
        let rightColumnX = modalSize.width * 0.15
        let firstRowY = -modalSize.height * 0.05
        let rowSpacing: CGFloat = 70

        sliders = [
            makeSlider(title: "Background brightness", length: sliderLength, value: loadBackgroundBrightness()),
            makeSlider(title: "Music", length: sliderLength, value: 0.65),
            makeSlider(title: "SFX", length: sliderLength, value: 0.6)
        ]

        brightnessSlider = sliders.first
        brightnessSlider?.onValueChange = { [weak self] value in
            self?.storeBackgroundBrightness(value)
            self?.applyBackgroundBrightness(value)
        }

        for (index, slider) in sliders.enumerated() {
            let y = firstRowY - CGFloat(index) * rowSpacing

            slider.label.position = CGPoint(x: leftColumnX, y: y)
            slider.label.zPosition = 2
            modal.addChild(slider.label)

            slider.position = CGPoint(x: rightColumnX, y: y)
            slider.zPosition = 2
            modal.addChild(slider)
        }
    }

    private func makeSlider(title: String, length: CGFloat, value: CGFloat) -> SliderNode {
        let slider = SliderNode(length: length)
        slider.value = value

        let label = SKLabelNode(fontNamed: "AvenirNext-Medium")
        label.text = title
        label.fontSize = 18
        label.fontColor = .black
        label.horizontalAlignmentMode = .right
        label.verticalAlignmentMode = .center
        slider.label = label
        return slider
    }

    private func addScrollingBackground() {
        let texture = SKTexture(imageNamed: "main_menu_bg")
        let textureSize = texture.size()
        guard textureSize.width > 0, textureSize.height > 0 else {
            return
        }

        let speed: CGFloat = 18
        let scale = max(size.width / textureSize.width, size.height / textureSize.height)
        let scaledSize = CGSize(width: textureSize.width * scale, height: textureSize.height * scale)
        let duration = TimeInterval(scaledSize.width / speed)

        let elapsed = CGFloat(ProcessInfo.processInfo.systemUptime)
        let offset = (elapsed * speed).truncatingRemainder(dividingBy: scaledSize.width)

        let bg1 = SKSpriteNode(texture: texture, size: scaledSize)
        let bg2 = SKSpriteNode(texture: texture, size: scaledSize)

        let centerX = size.width * 0.5
        let centerY = size.height * 0.5
        bg1.position = CGPoint(x: centerX + offset, y: centerY)
        bg2.position = CGPoint(x: bg1.position.x - scaledSize.width, y: centerY)

        bg1.zPosition = -2
        bg2.zPosition = -2

        let move = SKAction.moveBy(x: scaledSize.width, y: 0, duration: duration)
        let reset = SKAction.moveBy(x: -scaledSize.width, y: 0, duration: 0)
        let loop = SKAction.repeatForever(SKAction.sequence([move, reset]))

        bg1.run(loop)
        bg2.run(loop)

        addChild(bg1)
        addChild(bg2)
        backgroundNodes = [bg1, bg2]
    }

    private func applyBackgroundBrightness(_ value: CGFloat) {
        let clamped = max(0, min(1, value))
        for node in backgroundNodes {
            node.alpha = 1
            node.color = .black
            node.colorBlendFactor = 1 - clamped
        }
    }

    private func loadBackgroundBrightness() -> CGFloat {
        let stored = UserDefaults.standard.object(forKey: "backgroundBrightness") as? NSNumber
        let value = stored?.doubleValue ?? 0.5
        return CGFloat(value)
    }

    private func storeBackgroundBrightness(_ value: CGFloat) {
        UserDefaults.standard.set(value, forKey: "backgroundBrightness")
    }

    override func mouseDown(with event: NSEvent) {
        let location = event.location(in: self)
        handleSelection(at: location)
    }

    override func mouseDragged(with event: NSEvent) {
        let location = event.location(in: self)
        handleDrag(at: location)
    }

    override func mouseUp(with event: NSEvent) {
        activeSlider = nil
    }

    override func touchesBegan(with event: NSEvent) {
        guard let view = view, let touch = event.allTouches().first else {
            return
        }

        let locationInView = touch.location(in: view)
        let location = convertPoint(fromView: locationInView)
        handleSelection(at: location)
    }

    override func touchesMoved(with event: NSEvent) {
        guard let view = view, let touch = event.allTouches().first else {
            return
        }

        let locationInView = touch.location(in: view)
        let location = convertPoint(fromView: locationInView)
        handleDrag(at: location)
    }

    override func touchesEnded(with event: NSEvent) {
        activeSlider = nil
    }

    private func handleSelection(at location: CGPoint) {
        if nodes(at: location).contains(where: { $0.name == "closeButton" }) {
            presentMenu()
            return
        }

        for slider in sliders {
            let localPoint = slider.convert(location, from: self)
            if slider.hitTest(localPoint) {
                activeSlider = slider
                slider.updateValue(for: localPoint.x)
                return
            }
        }

        activeSlider = nil
    }

    private func handleDrag(at location: CGPoint) {
        guard let slider = activeSlider else {
            return
        }

        let localPoint = slider.convert(location, from: self)
        slider.updateValue(for: localPoint.x)
    }

    private func presentMenu() {
        guard let view = view else {
            return
        }

        let scene = MenuScene(size: size)
        scene.scaleMode = scaleMode
        view.presentScene(scene)
    }
}

private final class SliderNode: SKNode {
    private let track: SKShapeNode
    private let fill: SKShapeNode
    private let knob: SKShapeNode
    private let length: CGFloat
    private let thickness: CGFloat

    var label = SKLabelNode()
    var value: CGFloat = 0 {
        didSet {
            value = max(0, min(1, value))
            updateVisuals()
        }
    }
    var onValueChange: ((CGFloat) -> Void)?

    init(length: CGFloat, thickness: CGFloat = 8) {
        self.length = length
        self.thickness = thickness

        let trackRect = CGRect(x: -length * 0.5, y: -thickness * 0.5, width: length, height: thickness)
        track = SKShapeNode(rect: trackRect, cornerRadius: thickness * 0.5)
        track.fillColor = NSColor(white: 0.85, alpha: 1)
        track.strokeColor = .clear

        fill = SKShapeNode()
        fill.fillColor = NSColor(calibratedRed: 0.1, green: 0.45, blue: 0.9, alpha: 1)
        fill.strokeColor = .clear
        fill.position = .zero

        knob = SKShapeNode(circleOfRadius: 12)
        knob.fillColor = .white
        knob.strokeColor = NSColor(white: 0.7, alpha: 1)

        super.init()

        addChild(track)
        addChild(fill)
        addChild(knob)
        updateVisuals()
    }

    required init?(coder: NSCoder) {
        return nil
    }

    func hitTest(_ point: CGPoint) -> Bool {
        let bounds = CGRect(x: -length * 0.5, y: -thickness * 1.5, width: length, height: thickness * 3)
        return bounds.contains(point)
    }

    func updateValue(for localX: CGFloat) {
        let clampedX = max(-length * 0.5, min(length * 0.5, localX))
        value = (clampedX + length * 0.5) / length
        onValueChange?(value)
    }

    private func updateVisuals() {
        let clampedValue = max(0, min(1, value))
        let fillWidth = clampedValue * length
        let fillRect = CGRect(x: -length * 0.5,
                              y: -thickness * 0.5,
                              width: fillWidth,
                              height: thickness)
        fill.path = CGPath(roundedRect: fillRect,
                           cornerWidth: thickness * 0.5,
                           cornerHeight: thickness * 0.5,
                           transform: nil)

        let x = -length * 0.5 + clampedValue * length
        knob.position = CGPoint(x: x, y: 0)
    }
}
