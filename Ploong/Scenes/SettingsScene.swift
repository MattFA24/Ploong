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
        
        // Sync background and hide ornaments
        BackgroundManager.shared.setupBackground(in: self)
        BackgroundManager.shared.setOrnamentsVisible(false, animated: false)
    }

    private func buildLayout() {
            // --- LAYOUT TWEAKABLES: Change these values to move elements ---
            let previewY: CGFloat = 170.0          // Moves rectangle up/down
            let previewScale: CGFloat = 0.40       // Size of rectangle (0.45 = 45% of modal)
            
            let textColumnX: CGFloat = -400.0      // Move ALL text left (-) or right (+)
            let sliderColumnX: CGFloat = 200.0     // Move ALL sliders left (-) or right (+)
            let slidersWidth: CGFloat = 700.0      // How long the sliders are
            
            let startY: CGFloat = -80.0            // Vertical position of the first row
            let rowSpacing: CGFloat = -100.0        // Distance between rows
            // ---------------------------------------------------------------

            let dimmer = SKShapeNode(rectOf: size)
            dimmer.fillColor = NSColor(white: 0, alpha: 0.35)
            dimmer.strokeColor = .clear
            dimmer.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
            dimmer.zPosition = 0
            addChild(dimmer)

            let modalTexture = SKTexture(imageNamed: "modal_window")
            modalTexture.filteringMode = .nearest
            let modal = SKSpriteNode(texture: modalTexture)
            modal.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
            modal.zPosition = 1
            let modalScale = (size.width * 0.85) / modal.size.width
            modal.setScale(modalScale)
            addChild(modal)

            let modalContentWidth = modal.size.width / modal.xScale

            // Close Button
            let closeTexture = SKTexture(imageNamed: "close_button")
            closeTexture.filteringMode = .nearest
            let closeButton = SKSpriteNode(texture: closeTexture)
            closeButton.name = "closeButton"
            closeButton.position = CGPoint(x: -modalContentWidth * 0.44, y: modal.size.height * 0.40 / modal.yScale)
            closeButton.zPosition = 2
            modal.addChild(closeButton)

            // 1. Game Preview Window (16:10)
            let pWidth = modalContentWidth * previewScale
            let pHeight = (pWidth / 16) * 10
            let preview = SKShapeNode(rectOf: CGSize(width: pWidth, height: pHeight), cornerRadius: 4)
            preview.fillColor = NSColor(calibratedRed: 0.75, green: 0.82, blue: 0.85, alpha: 1.0)
            preview.strokeColor = .clear
            preview.position = CGPoint(x: 0, y: previewY)
            preview.zPosition = 2
            modal.addChild(preview)

            // 2. Row Setup
            let configs: [(String, CGFloat, (CGFloat) -> Void)] = [
                ("bgbrightness_text", BackgroundManager.shared.loadBrightness(), { val in BackgroundManager.shared.saveBrightness(val) }),
                ("music_text", 0.65, { _ in }),
                ("sfx_text", 0.6, { _ in })
            ]

            for (index, config) in configs.enumerated() {
                let yPos = startY + (CGFloat(index) * rowSpacing)
                
                // Text Sprite
                let textTexture = SKTexture(imageNamed: config.0)
                textTexture.filteringMode = .nearest
                let textSprite = SKSpriteNode(texture: textTexture)
                textSprite.anchorPoint = CGPoint(x: 0.5, y: 0.5)
                textSprite.position = CGPoint(x: textColumnX, y: yPos)
                textSprite.zPosition = 2
                modal.addChild(textSprite)
                
                // Slider
                let slider = SliderNode(length: slidersWidth)
                slider.value = config.1
                slider.onValueChange = config.2
                slider.position = CGPoint(x: sliderColumnX, y: yPos)
                slider.zPosition = 2
                modal.addChild(slider)
                sliders.append(slider)
            }
        }

    // MARK: - Input Handling
    override func mouseDown(with event: NSEvent) {
        let location = event.location(in: self)
        let touchedNodes = nodes(at: location)
        
        if touchedNodes.contains(where: { $0.name == "closeButton" }) {
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
    }

    override func mouseDragged(with event: NSEvent) {
        guard let slider = activeSlider else { return }
        let location = event.location(in: self)
        let localPoint = slider.convert(location, from: self)
        slider.updateValue(for: localPoint.x)
    }

    override func mouseUp(with event: NSEvent) {
        activeSlider = nil
    }

    private func presentMenu() {
        guard let view = view else { return }
        let scene = MenuScene(size: size)
        scene.scaleMode = scaleMode
        view.presentScene(scene)
    }
}

// MARK: - Helper Slider Node
// This class must be inside this file for the 'private' references to work correctly.
class SliderNode: SKNode {
    private let track: SKShapeNode
    private let fill: SKShapeNode
    private let knob: SKShapeNode
    private let length: CGFloat
    private let thickness: CGFloat = 6

    var value: CGFloat = 0 { didSet { updateVisuals() } }
    var onValueChange: ((CGFloat) -> Void)?

    init(length: CGFloat) {
        self.length = length
        
        track = SKShapeNode(rect: CGRect(x: -length/2, y: -thickness/2, width: length, height: thickness), cornerRadius: 2)
        track.fillColor = NSColor(white: 0.9, alpha: 1)
        track.strokeColor = .clear
        
        fill = SKShapeNode()
        fill.fillColor = NSColor(calibratedRed: 0.0, green: 0.5, blue: 1.0, alpha: 1.0)
        fill.strokeColor = .clear
        
        knob = SKShapeNode(rectOf: CGSize(width: 24, height: 14), cornerRadius: 4)
        knob.fillColor = .white
        knob.strokeColor = NSColor(white: 0.8, alpha: 1)
        
        super.init()
        addChild(track)
        addChild(fill)
        addChild(knob)
        updateVisuals()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func hitTest(_ point: CGPoint) -> Bool {
        // Larger hit area for easier dragging
        return CGRect(x: -length/2, y: -20, width: length, height: 40).contains(point)
    }

    func updateValue(for localX: CGFloat) {
        value = max(0, min(1, (localX + length/2) / length))
        onValueChange?(value)
    }

    private func updateVisuals() {
        let fillWidth = value * length
        fill.path = CGPath(roundedRect: CGRect(x: -length/2, y: -thickness/2, width: fillWidth, height: thickness), cornerWidth: 2, cornerHeight: 2, transform: nil)
        knob.position = CGPoint(x: -length/2 + fillWidth, y: 0)
    }
}
