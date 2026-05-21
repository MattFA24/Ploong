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
    private var previewBackgroundNodes: [SKSpriteNode] = []

    private enum PreviewLayout {
        static let virtualSize = CGSize(width: 960, height: 600)
        static let floorHeight: CGFloat = 115
        static let platformHeight: CGFloat = 28
        static let foamHeight: CGFloat = 100
        static let platformY: CGFloat = virtualSize.height * 0.5
        static let platformTopY: CGFloat = platformY + (platformHeight * 0.5)
        static let playerHalfHeight: CGFloat = PlayerEntity.Layout.visualHalfHeight
        static let bottomLaneY: CGFloat = floorHeight + playerHalfHeight
        static let topLaneY: CGFloat = platformTopY + playerHalfHeight
        static let gapHeight: CGFloat = (platformY - (platformHeight * 0.5)) - floorHeight
        static let bottomGateY: CGFloat = floorHeight + (gapHeight * 0.5)
        static let topGateY: CGFloat = platformTopY + (gapHeight * 0.5)
        static let gateHeight: CGFloat = gapHeight - 16
        static let bottomEnemyBaselineY: CGFloat = bottomLaneY - GameConstants.bottomEnemyFootOffset
        static let topEnemyBaselineY: CGFloat = topLaneY - GameConstants.topEnemyFootOffset
        static let playerY: CGFloat = bottomLaneY + GameConstants.bottomPlayerFootOffset
    }

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
            let previewWidthRatio: CGFloat = 0.56
            
            let textColumnX: CGFloat = -400.0
        let sliderColumnX: CGFloat = 200.0
            let slidersWidth: CGFloat = 700.0
            
            let startY: CGFloat = -115.0
        let rowSpacing: CGFloat = -100.0

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
            let modalContentHeight = modal.size.height / modal.yScale

            // Close Button
            let closeTexture = SKTexture(imageNamed: "close_button")
            closeTexture.filteringMode = .nearest
            let closeButton = SKSpriteNode(texture: closeTexture)
            closeButton.name = "closeButton"
            closeButton.position = CGPoint(x: -modalContentWidth * 0.44, y: modal.size.height * 0.40 / modal.yScale)
            closeButton.zPosition = 2
            modal.addChild(closeButton)

            // 1. Static Game Preview Window (16:10)
            let previewTopY = modalContentHeight * 0.37
            let previewBottomY = startY + 95
            let maxPreviewHeight = previewTopY - previewBottomY
            let maxPreviewWidth = modalContentWidth * previewWidthRatio
            let pHeight = min((maxPreviewWidth / 16) * 10, maxPreviewHeight)
            let pWidth = pHeight * 16 / 10
            let previewCenterY = previewBottomY + (pHeight * 0.5)
            let preview = makeGameplayPreview(size: CGSize(width: pWidth, height: pHeight))
            preview.position = CGPoint(x: -pWidth * 0.5, y: previewCenterY - pHeight * 0.5)
            preview.zPosition = 2
            modal.addChild(preview)

            let configs: [(String, CGFloat, (CGFloat) -> Void)] = [
                ("bgbrightness_text", BackgroundManager.shared.loadBrightness(), { [weak self] val in
                    BackgroundManager.shared.saveBrightness(val)
                    self?.applyPreviewBrightness(val)
                }),
                ("music_text", CGFloat(AudioManager.shared.musicVolume), { val in AudioManager.shared.musicVolume = Float(val) }),
                ("sfx_text", CGFloat(AudioManager.shared.sfxVolume), { val in AudioManager.shared.sfxVolume = Float(val) })
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

    private func makeGameplayPreview(size previewSize: CGSize) -> SKNode {
        previewBackgroundNodes.removeAll()

        let virtualSize = PreviewLayout.virtualSize
        let scale = min(previewSize.width / virtualSize.width, previewSize.height / virtualSize.height)

        let cropNode = SKCropNode()
        cropNode.setScale(scale)
        let mask = SKShapeNode(rect: CGRect(origin: .zero, size: virtualSize))
        mask.fillColor = .white
        mask.strokeColor = .clear
        cropNode.maskNode = mask

        let root = SKNode()
        cropNode.addChild(root)

        addPreviewBackground(to: root, virtualSize: virtualSize)
        addPreviewWorld(to: root, virtualSize: virtualSize)
        addPreviewHUD(to: root, virtualSize: virtualSize)
        applyPreviewBrightness(BackgroundManager.shared.loadBrightness())

        let frame = SKShapeNode(rectOf: previewSize, cornerRadius: 4)
        frame.position = CGPoint(x: previewSize.width * 0.5, y: previewSize.height * 0.5)
        frame.fillColor = .clear
        frame.strokeColor = SKColor(red: 0.46, green: 0.68, blue: 0.72, alpha: 1)
        frame.lineWidth = 3
        frame.zPosition = 3

        let container = SKNode()
        container.addChild(cropNode)
        container.addChild(frame)
        return container
    }

    private func addPreviewBackground(to root: SKNode, virtualSize: CGSize) {
        let bgTexture = SKTexture(imageNamed: "game_bg")
        bgTexture.filteringMode = .nearest

        let background = SKSpriteNode(texture: bgTexture, size: virtualSize)
        background.position = CGPoint(x: virtualSize.width * 0.5, y: virtualSize.height * 0.5)
        background.zPosition = -10
        root.addChild(background)
        previewBackgroundNodes.append(background)

        addPreviewSprite(
            "safe_zone_dark",
            to: root,
            position: CGPoint(x: 40, y: 1),
            size: CGSize(width: 88, height: virtualSize.height + 40),
            zPosition: -8,
            anchorPoint: CGPoint(x: 0, y: 0)
        )
        addPreviewSprite(
            "tiles_main",
            to: root,
            position: CGPoint(x: virtualSize.width * 0.5, y: PreviewLayout.floorHeight * 0.5),
            size: CGSize(width: virtualSize.width, height: PreviewLayout.floorHeight),
            zPosition: 7
        )
        addPreviewSprite(
            "mid_platform",
            to: root,
            position: CGPoint(x: virtualSize.width * 0.5, y: PreviewLayout.platformY),
            size: CGSize(width: virtualSize.width, height: PreviewLayout.platformHeight),
            zPosition: 5
        )
        addPreviewSprite(
            "foam_ornament",
            to: root,
            position: CGPoint(x: virtualSize.width * 0.5, y: PreviewLayout.foamHeight * 0.5),
            size: CGSize(width: virtualSize.width, height: PreviewLayout.foamHeight),
            zPosition: 8
        )
    }

    private func addPreviewWorld(to root: SKNode, virtualSize: CGSize) {
        addPreviewGate(to: root, position: CGPoint(x: 400, y: PreviewLayout.topGateY), text: "÷2")
        addPreviewGate(to: root, position: CGPoint(x: 400, y: PreviewLayout.bottomGateY), text: "-10")
        addPreviewGate(to: root, position: CGPoint(x: 690, y: PreviewLayout.topGateY), text: "×3")

        addPreviewSprite(
            "joy_1",
            to: root,
            position: CGPoint(x: 116, y: PreviewLayout.playerY),
            size: CGSize(width: 136, height: 106),
            zPosition: 10
        )
        addPreviewLabel("160", to: root, position: CGPoint(x: 126, y: PreviewLayout.playerY + 72), fontSize: 17, color: .red, zPosition: 12)

        let bulletPositions = [202, 270, 338, 506, 574, 642, 710]
        for x in bulletPositions {
            addPreviewSprite(
                "bullet",
                to: root,
                position: CGPoint(x: CGFloat(x), y: PreviewLayout.playerY + 10),
                size: CGSize(width: 9, height: 9),
                zPosition: 12
            )
        }

        addPreviewSprite("coin_img", to: root, position: CGPoint(x: 330, y: PreviewLayout.playerY + 6), size: CGSize(width: 22, height: 22), zPosition: 11)
        addPreviewSprite("coin_img", to: root, position: CGPoint(x: 620, y: PreviewLayout.topEnemyBaselineY + 28), size: CGSize(width: 20, height: 20), zPosition: 11)

        addPreviewEnemy("enemy1_1", to: root, position: CGPoint(x: 760, y: PreviewLayout.bottomEnemyBaselineY), hpText: "10", barColor: .red)
        addPreviewEnemy("enemy2_1", to: root, position: CGPoint(x: 840, y: PreviewLayout.bottomEnemyBaselineY), hpText: "50", barColor: .green)
        addPreviewEnemy("enemy3_1", to: root, position: CGPoint(x: 750, y: PreviewLayout.topEnemyBaselineY), hpText: "120", barColor: .yellow)
        addPreviewEnemy("enemy4_1", to: root, position: CGPoint(x: 835, y: PreviewLayout.topEnemyBaselineY), hpText: "250", barColor: .green)

        addPreviewBubble(to: root, position: CGPoint(x: 334, y: PreviewLayout.playerY + 1), radius: 9)
        addPreviewBubble(to: root, position: CGPoint(x: 560, y: PreviewLayout.floorHeight - 25), radius: 8)
        addPreviewBubble(to: root, position: CGPoint(x: 830, y: PreviewLayout.floorHeight - 38), radius: 7)
        addPreviewBubble(to: root, position: CGPoint(x: 705, y: PreviewLayout.topEnemyBaselineY + 35), radius: 6)
    }

    private func addPreviewHUD(to root: SKNode, virtualSize: CGSize) {
        addPreviewSprite(
            "main_score_bg",
            to: root,
            position: CGPoint(x: 116, y: virtualSize.height - 62),
            size: CGSize(width: 186, height: 66),
            zPosition: 85
        )
        addPreviewLabel("Score", to: root, position: CGPoint(x: 38, y: virtualSize.height - 46), fontSize: 24, color: .black, zPosition: 90, alignment: .left)
        addPreviewLabel("106", to: root, position: CGPoint(x: 184, y: virtualSize.height - 46), fontSize: 24, color: .black, zPosition: 90, alignment: .right)
        addPreviewLabel("Coin", to: root, position: CGPoint(x: 38, y: virtualSize.height - 75), fontSize: 24, color: .black, zPosition: 90, alignment: .left)
        addPreviewLabel("0", to: root, position: CGPoint(x: 184, y: virtualSize.height - 75), fontSize: 24, color: .black, zPosition: 90, alignment: .right)

        addPreviewSprite(
            "pause_hint_bg",
            to: root,
            position: CGPoint(x: virtualSize.width - 135, y: virtualSize.height - 58),
            size: CGSize(width: 244, height: 54),
            zPosition: 85
        )
        addPreviewSprite(
            "pause_hint_text",
            to: root,
            position: CGPoint(x: virtualSize.width - 135, y: virtualSize.height - 53),
            size: CGSize(width: 210, height: 32),
            zPosition: 90
        )
    }

    private func addPreviewGate(to root: SKNode, position: CGPoint, text: String) {
        addPreviewSprite(
            "main_multi_bg",
            to: root,
            position: position,
            size: CGSize(width: 66, height: PreviewLayout.gateHeight),
            zPosition: 7
        )
        addPreviewLabel(text, to: root, position: position, fontSize: 23, color: .white, zPosition: 8)
    }

    private func addPreviewEnemy(_ textureName: String, to root: SKNode, position: CGPoint, hpText: String, barColor: SKColor) {
        addPreviewSprite(
            textureName,
            to: root,
            position: position,
            size: CGSize(width: 70, height: 58),
            zPosition: 10,
            anchorPoint: CGPoint(x: 0.5, y: 0)
        )

        addPreviewLabel(hpText, to: root, position: CGPoint(x: position.x, y: position.y + 70), fontSize: 12, color: .white, zPosition: 12)

        let barBackground = SKSpriteNode(color: .black, size: CGSize(width: 34, height: 5))
        barBackground.position = CGPoint(x: position.x, y: position.y + 62)
        barBackground.zPosition = 12
        root.addChild(barBackground)

        let bar = SKSpriteNode(color: barColor, size: CGSize(width: 30, height: 3))
        bar.position = .zero
        bar.zPosition = 1
        barBackground.addChild(bar)
    }

    private func addPreviewBubble(to root: SKNode, position: CGPoint, radius: CGFloat) {
        let bubble = SKShapeNode(circleOfRadius: radius)
        bubble.position = position
        bubble.strokeColor = SKColor(red: 0.77, green: 0.96, blue: 1.0, alpha: 0.85)
        bubble.fillColor = SKColor(red: 0.77, green: 0.96, blue: 1.0, alpha: 0.16)
        bubble.lineWidth = 2
        bubble.zPosition = 13
        root.addChild(bubble)

        let highlight = SKShapeNode(circleOfRadius: radius * 0.28)
        highlight.position = CGPoint(x: -radius * 0.25, y: radius * 0.25)
        highlight.fillColor = SKColor.white.withAlphaComponent(0.45)
        highlight.strokeColor = .clear
        highlight.zPosition = 1
        bubble.addChild(highlight)
    }

    @discardableResult
    private func addPreviewSprite(
        _ textureName: String,
        to root: SKNode,
        position: CGPoint,
        size: CGSize,
        zPosition: CGFloat,
        anchorPoint: CGPoint = CGPoint(x: 0.5, y: 0.5)
    ) -> SKSpriteNode {
        let texture = SKTexture(imageNamed: textureName)
        texture.filteringMode = .nearest
        let sprite = SKSpriteNode(texture: texture, size: size)
        sprite.anchorPoint = anchorPoint
        sprite.position = position
        sprite.zPosition = zPosition
        root.addChild(sprite)
        return sprite
    }

    private func addPreviewLabel(
        _ text: String,
        to root: SKNode,
        position: CGPoint,
        fontSize: CGFloat,
        color: SKColor,
        zPosition: CGFloat,
        alignment: SKLabelHorizontalAlignmentMode = .center
    ) {
        let label = SKLabelNode(fontNamed: GameConstants.fontName)
        label.text = text
        label.fontSize = fontSize
        label.fontColor = color
        label.horizontalAlignmentMode = alignment
        label.verticalAlignmentMode = .center
        label.position = position
        label.zPosition = zPosition
        root.addChild(label)
    }

    private func applyPreviewBrightness(_ value: CGFloat) {
        let brightness = max(0.0, min(1.0, value))
        let blendFactor = 1.0 - brightness

        for node in previewBackgroundNodes {
            node.color = .black
            node.colorBlendFactor = blendFactor
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
