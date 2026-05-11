//
//  GameScene.swift
//  Ploong
//
//  Created by Matthew Fernando Anggrian on 11/05/26.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {

    enum MenuAction {
        case play
        case character
        case settings
    }

    private enum ModalType {
        case none
        case settings
        case character
    }

    var entities = [GKEntity]()
    var graphs = [String : GKGraph]()

    private var menuButtonEntities = [GKEntity]()
    private var modalButtonEntities = [GKEntity]()
    private var sliderEntities = [GKEntity]()
    private var modalEntities = [GKEntity]()
    private weak var activeSlider: SliderComponent?
    private var activeModal: ModalType = .none

    private struct CharacterData {
        let name: String
        let subtitle: String
        let color: NSColor
        var isLocked: Bool
        let price: Int
    }

    private struct GameConfig: Decodable {
        let coins: Int
        let characters: [CharacterConfig]
    }

    private struct CharacterConfig: Decodable {
        let name: String
        let subtitle: String
        let color: String
        let locked: Bool
        let price: Int?
    }

    private var characterIndex = 0
    private var selectedCharacterIndex = 0
    private var coins = 0
    private var characters: [CharacterData] = []
    private var purchaseActive = false
    private var pendingPurchaseIndex: Int?
    private var purchaseEntities: [GKEntity] = []

    private weak var characterNameNode: SKLabelNode?
    private weak var characterSubtitleNode: SKLabelNode?
    private weak var coinLabelNode: SKLabelNode?
    private weak var selectedIndicatorNode: SKShapeNode?
    private weak var selectButtonNode: SKShapeNode?
    private weak var selectButtonLabelNode: SKLabelNode?

    override func sceneDidLoad() {
        backgroundColor = .white
        removeAllChildren()
        entities.removeAll()
        menuButtonEntities.removeAll()
        modalButtonEntities.removeAll()
        sliderEntities.removeAll()
        modalEntities.removeAll()
        activeSlider = nil
        activeModal = .none

        loadConfig()
        buildMainMenu()
        applyLayout()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        applyLayout()
    }

    override func mouseDown(with event: NSEvent) {
        let location = event.location(in: self)

        if purchaseActive {
            return
        }

        if activeModal != .none {
            if handleModalMouseDown(at: location) {
                return
            }
        }

        for entity in menuButtonEntities {
            guard
                let input = entity.component(ofType: InputComponent.self),
                let render = entity.component(ofType: RenderComponent.self)
            else { continue }

            if render.node.contains(location) {
                input.trigger()
            }
        }
    }

    private func handleModalMouseDown(at location: CGPoint) -> Bool {
        for entity in modalButtonEntities {
            guard
                let input = entity.component(ofType: InputComponent.self),
                let render = entity.component(ofType: RenderComponent.self)
            else { continue }

            if render.node.contains(location) {
                input.trigger()
                return true
            }
        }

        for entity in sliderEntities {
            guard
                let slider = entity.component(ofType: SliderComponent.self),
                let render = entity.component(ofType: RenderComponent.self)
            else { continue }

            if slider.beginDrag(at: location, in: render.node) {
                activeSlider = slider
                return true
            }
        }

        return false
    }

    override func mouseDragged(with event: NSEvent) {
        guard activeModal == .settings, let slider = activeSlider else { return }
        slider.drag(to: event.location(in: self), in: self)
    }

    override func mouseUp(with event: NSEvent) {
        guard activeModal == .settings else { return }
        activeSlider?.endDrag()
        activeSlider = nil
    }

    override func keyDown(with event: NSEvent) {
        guard purchaseActive else { return }

        switch event.keyCode {
        case 0x24: // return
            confirmPurchaseIfPossible()
        case 0x35: // escape
            dismissPurchaseConfirmation()
        default:
            break
        }
    }

    override func update(_ currentTime: TimeInterval) {
        for entity in entities {
            entity.update(deltaTime: currentTime)
        }
    }

    private func buildMainMenu() {
        addEntity(makeTitleEntity(text: "TITLE TEXT"))
        addEntity(makeHighscoreEntity(text: "HIGHSCORE: XXX"))

        addMenuButton(title: "PLAY", action: .play, size: CGSize(width: 420.0, height: 140.0))
        addMenuButton(title: "CHARACTER", action: .character, size: CGSize(width: 280.0, height: 80.0))
        addMenuButton(title: "SETTINGS", action: .settings, size: CGSize(width: 280.0, height: 80.0))
    }

    private func addEntity(_ entity: GKEntity) {
        entities.append(entity)

        if let render = entity.component(ofType: RenderComponent.self) {
            addChild(render.node)
        }
    }

    private func addMenuEntity(_ entity: GKEntity) {
        addEntity(entity)

        if entity.component(ofType: InputComponent.self) != nil {
            menuButtonEntities.append(entity)
        }
    }

    private func addModalEntity(_ entity: GKEntity) {
        addEntity(entity)
        modalEntities.append(entity)

        if entity.component(ofType: InputComponent.self) != nil {
            modalButtonEntities.append(entity)
        }

        if entity.component(ofType: SliderComponent.self) != nil {
            sliderEntities.append(entity)
        }
    }

    private func addPurchaseEntity(_ entity: GKEntity) {
        addEntity(entity)
        purchaseEntities.append(entity)
    }

    private func applyLayout() {
        for entity in entities {
            entity.component(ofType: LayoutComponent.self)?.applyLayout(sceneSize: size)
        }
    }

    private func makeTitleEntity(text: String) -> GKEntity {
        let label = SKLabelNode(text: text)
        label.fontName = "Helvetica-Bold"
        label.fontColor = .black
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center

        let entity = GameEntity(node: label)
        entity.addComponent(LayoutComponent { node, sceneSize in
            guard let labelNode = node as? SKLabelNode else { return }
            let scale = min(sceneSize.width / 1280.0, sceneSize.height / 800.0)
            labelNode.fontSize = 64.0 * scale
            labelNode.position = CGPoint(x: sceneSize.width * 0.5, y: sceneSize.height * 0.78)
        })

        return entity
    }

    private func makeHighscoreEntity(text: String) -> GKEntity {
        let label = SKLabelNode(text: text)
        label.fontName = "Helvetica-Bold"
        label.fontColor = .black
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center

        let entity = GameEntity(node: label)
        entity.addComponent(LayoutComponent { node, sceneSize in
            guard let labelNode = node as? SKLabelNode else { return }
            let scale = min(sceneSize.width / 1280.0, sceneSize.height / 800.0)
            labelNode.fontSize = 24.0 * scale
            labelNode.position = CGPoint(x: sceneSize.width * 0.5, y: sceneSize.height * 0.68)
        })

        return entity
    }

    private func addMenuButton(title: String, action: MenuAction, size: CGSize) {
        let buttonNode = SKShapeNode()
        buttonNode.fillColor = NSColor(white: 0.75, alpha: 1.0)
        buttonNode.strokeColor = .clear
        buttonNode.isAntialiased = true

        let label = SKLabelNode(text: title)
        label.fontName = "Helvetica-Bold"
        label.fontColor = .black
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        buttonNode.addChild(label)

        let entity = GameEntity(node: buttonNode)
        entity.addComponent(InputComponent { [weak self] in
            self?.handleMenuAction(action)
        })

        entity.addComponent(LayoutComponent { node, sceneSize in
            guard let shapeNode = node as? SKShapeNode else { return }
            let scale = min(sceneSize.width / 1280.0, sceneSize.height / 800.0)
            let scaledSize = CGSize(width: size.width * scale, height: size.height * scale)
            let cornerRadius = scaledSize.height * 0.25
            shapeNode.path = CGPath(roundedRect: CGRect(origin: .zero, size: scaledSize),
                                    cornerWidth: cornerRadius,
                                    cornerHeight: cornerRadius,
                                    transform: nil)
            shapeNode.position = CGPoint(x: sceneSize.width * 0.5 - scaledSize.width * 0.5,
                                         y: self.buttonYPosition(for: title, sceneSize: sceneSize))

            if let labelNode = shapeNode.children.first as? SKLabelNode {
                labelNode.fontSize = (title == "PLAY" ? 48.0 : 26.0) * scale
                labelNode.position = CGPoint(x: scaledSize.width * 0.5, y: scaledSize.height * 0.5)
            }
        })

        addMenuEntity(entity)
    }

    private func buttonYPosition(for title: String, sceneSize: CGSize) -> CGFloat {
        switch title {
        case "PLAY":
            return sceneSize.height * 0.50
        case "CHARACTER":
            return sceneSize.height * 0.34
        case "SETTINGS":
            return sceneSize.height * 0.22
        default:
            return sceneSize.height * 0.30
        }
    }

    private func handleMenuAction(_ action: MenuAction) {
        switch action {
        case .play:
            break
        case .character:
            if activeModal == .character {
                dismissActiveModal()
            } else {
                presentCharacterModal()
            }
        case .settings:
            if activeModal == .settings {
                dismissActiveModal()
            } else {
                presentSettingsModal()
            }
        }
    }

    private func loadConfig() {
        let fallback = [
            CharacterData(name: "Joy", subtitle: "your daily joyful gurl",
                          color: NSColor(calibratedRed: 0.31, green: 0.39, blue: 0.74, alpha: 1.0),
                          isLocked: false, price: 0),
            CharacterData(name: "TiuTiu", subtitle: "calm and ready",
                          color: NSColor(calibratedRed: 0.74, green: 0.31, blue: 0.31, alpha: 1.0),
                          isLocked: false, price: 0),
            CharacterData(name: "???-1", subtitle: "locked",
                          color: NSColor(white: 0.2, alpha: 1.0), isLocked: true, price: 20),
            CharacterData(name: "???-2", subtitle: "locked",
                          color: NSColor(white: 0.2, alpha: 1.0), isLocked: true, price: 20),
            CharacterData(name: "???-3", subtitle: "locked",
                          color: NSColor(white: 0.2, alpha: 1.0), isLocked: true, price: 20)
        ]

        guard let url = Bundle.main.url(forResource: "GameConfig", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let config = try? JSONDecoder().decode(GameConfig.self, from: data)
        else {
            coins = 34
            characters = fallback
            return
        }

        coins = config.coins
        characters = config.characters.map { entry in
            CharacterData(
                name: entry.name,
                subtitle: entry.subtitle,
                color: Self.colorFromHex(entry.color) ?? NSColor(white: 0.2, alpha: 1.0),
                isLocked: entry.locked,
                price: entry.price ?? (entry.locked ? 20 : 0)
            )
        }
    }

    private static func colorFromHex(_ hex: String) -> NSColor? {
        let cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        guard cleaned.count == 6, let value = Int(cleaned, radix: 16) else { return nil }

        let red = CGFloat((value >> 16) & 0xFF) / 255.0
        let green = CGFloat((value >> 8) & 0xFF) / 255.0
        let blue = CGFloat(value & 0xFF) / 255.0
        return NSColor(calibratedRed: red, green: green, blue: blue, alpha: 1.0)
    }

    private func panelFrame(for sceneSize: CGSize) -> CGRect {
        let scale = min(sceneSize.width / 1280.0, sceneSize.height / 800.0)
        let panelSize = CGSize(width: 1120.0 * scale, height: 680.0 * scale)
        let origin = CGPoint(x: sceneSize.width * 0.5 - panelSize.width * 0.5,
                             y: sceneSize.height * 0.5 - panelSize.height * 0.5)
        return CGRect(origin: origin, size: panelSize)
    }

    private func makeSettingsPanelEntity() -> GKEntity {
        let panelNode = SKShapeNode()
        panelNode.fillColor = NSColor(white: 0.88, alpha: 1.0)
        panelNode.strokeColor = .clear
        panelNode.zPosition = 20

        let entity = GameEntity(node: panelNode)
        entity.addComponent(LayoutComponent { [weak self] node, sceneSize in
            guard let self = self, let shapeNode = node as? SKShapeNode else { return }
            let panelFrame = self.panelFrame(for: sceneSize)
            let cornerRadius = panelFrame.height * 0.08
            shapeNode.path = CGPath(roundedRect: CGRect(origin: .zero, size: panelFrame.size),
                                    cornerWidth: cornerRadius,
                                    cornerHeight: cornerRadius,
                                    transform: nil)
            shapeNode.position = panelFrame.origin
        })

        return entity
    }

    private func makeCloseButtonEntity() -> GKEntity {
        let buttonNode = SKShapeNode()
        buttonNode.fillColor = NSColor(white: 0.65, alpha: 1.0)
        buttonNode.strokeColor = NSColor(white: 0.35, alpha: 1.0)
        buttonNode.zPosition = 30

        let label = SKLabelNode(text: "X")
        label.fontName = "Helvetica-Bold"
        label.fontColor = .white
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        buttonNode.addChild(label)

        let entity = GameEntity(node: buttonNode)
        entity.addComponent(InputComponent { [weak self] in
            self?.dismissActiveModal()
        })

        entity.addComponent(LayoutComponent { [weak self] node, sceneSize in
            guard let self = self, let shapeNode = node as? SKShapeNode else { return }
            let panelFrame = self.panelFrame(for: sceneSize)
            let scale = min(sceneSize.width / 1280.0, sceneSize.height / 800.0)
            let diameter = 56.0 * scale
            shapeNode.path = CGPath(ellipseIn: CGRect(origin: .zero, size: CGSize(width: diameter, height: diameter)),
                                    transform: nil)
            shapeNode.position = CGPoint(x: panelFrame.minX + 24.0 * scale,
                                         y: panelFrame.maxY - diameter - 24.0 * scale)

            if let labelNode = shapeNode.children.first as? SKLabelNode {
                labelNode.fontSize = 22.0 * scale
                labelNode.position = CGPoint(x: diameter * 0.5, y: diameter * 0.5)
            }
        })

        return entity
    }

    private func makePreviewEntity() -> GKEntity {
        let previewNode = SKShapeNode()
        previewNode.fillColor = .white
        previewNode.strokeColor = NSColor(white: 0.8, alpha: 1.0)
        previewNode.zPosition = 25

        let label = SKLabelNode(text: "Game preview")
        label.fontName = "Helvetica"
        label.fontColor = .black
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        previewNode.addChild(label)

        let entity = GameEntity(node: previewNode)
        entity.addComponent(LayoutComponent { [weak self] node, sceneSize in
            guard let self = self, let shapeNode = node as? SKShapeNode else { return }
            let panelFrame = self.panelFrame(for: sceneSize)
            let scale = min(sceneSize.width / 1280.0, sceneSize.height / 800.0)
            let previewSize = CGSize(width: 520.0 * scale, height: 260.0 * scale)
            let center = CGPoint(x: sceneSize.width * 0.5, y: panelFrame.maxY - 180.0 * scale)
            let origin = CGPoint(x: center.x - previewSize.width * 0.5,
                                 y: center.y - previewSize.height * 0.5)

            shapeNode.path = CGPath(rect: CGRect(origin: .zero, size: previewSize), transform: nil)
            shapeNode.position = origin

            if let labelNode = shapeNode.children.first as? SKLabelNode {
                labelNode.fontSize = 18.0 * scale
                labelNode.position = CGPoint(x: previewSize.width * 0.5, y: previewSize.height * 0.5)
            }
        })

        return entity
    }

    private func makeSliderRow(title: String, value: CGFloat) -> (GKEntity, GKEntity) {
        let labelNode = SKLabelNode(text: title)
        labelNode.fontName = "Helvetica-Bold"
        labelNode.fontColor = .black
        labelNode.horizontalAlignmentMode = .left
        labelNode.verticalAlignmentMode = .center
        labelNode.zPosition = 25

        let labelEntity = GameEntity(node: labelNode)
        labelEntity.addComponent(LayoutComponent { [weak self] node, sceneSize in
            guard let self = self, let label = node as? SKLabelNode else { return }
            let panelFrame = self.panelFrame(for: sceneSize)
            let scale = min(sceneSize.width / 1280.0, sceneSize.height / 800.0)
            label.fontSize = 20.0 * scale
            label.position = CGPoint(x: panelFrame.minX + panelFrame.width * 0.20,
                                     y: self.sliderRowYPosition(for: title, sceneSize: sceneSize))
        })

        let sliderContainer = SKNode()
        sliderContainer.zPosition = 25
        let trackNode = SKShapeNode()
        trackNode.fillColor = NSColor(white: 0.8, alpha: 1.0)
        trackNode.strokeColor = .clear

        let knobNode = SKShapeNode()
        knobNode.fillColor = NSColor(white: 0.95, alpha: 1.0)
        knobNode.strokeColor = NSColor(white: 0.7, alpha: 1.0)

        sliderContainer.addChild(trackNode)
        sliderContainer.addChild(knobNode)

        let sliderEntity = GameEntity(node: sliderContainer)
        let sliderComponent = SliderComponent(trackNode: trackNode, knobNode: knobNode, value: value)
        sliderEntity.addComponent(sliderComponent)

        sliderEntity.addComponent(LayoutComponent { [weak self] node, sceneSize in
            guard let self = self else { return }
            let panelFrame = self.panelFrame(for: sceneSize)
            let scale = min(sceneSize.width / 1280.0, sceneSize.height / 800.0)
            let rowY = self.sliderRowYPosition(for: title, sceneSize: sceneSize)

            let trackSize = CGSize(width: panelFrame.width * 0.45, height: 8.0 * scale)
            let trackOrigin = CGPoint(x: panelFrame.minX + panelFrame.width * 0.42,
                                      y: rowY - trackSize.height * 0.5)
            trackNode.path = CGPath(roundedRect: CGRect(origin: .zero, size: trackSize),
                                    cornerWidth: trackSize.height * 0.5,
                                    cornerHeight: trackSize.height * 0.5,
                                    transform: nil)
            trackNode.position = trackOrigin

            let knobDiameter = 26.0 * scale
            knobNode.path = CGPath(ellipseIn: CGRect(origin: .zero,
                                                    size: CGSize(width: knobDiameter, height: knobDiameter)),
                                   transform: nil)

            let knobRadius = knobDiameter * 0.5
            let minX = trackOrigin.x + knobRadius
            let maxX = trackOrigin.x + trackSize.width - knobRadius
            sliderComponent.configure(range: minX...maxX, centerY: rowY)
        })

        return (labelEntity, sliderEntity)
    }

    private func presentCharacterModal() {
        dismissActiveModal()
        activeModal = .character

        addModalEntity(makeDimOverlayEntity())
        addModalEntity(makeCharacterPanelEntity())
        addModalEntity(makeCloseButtonEntity())
        addModalEntity(makeCoinBadgeEntity())
        addModalEntity(makeCharacterChevronsEntity(direction: -1))
        addModalEntity(makeCharacterChevronsEntity(direction: 1))
        addModalEntity(makeCharacterRowEntity(slot: 0))
        addModalEntity(makeCharacterRowEntity(slot: 1))
        addModalEntity(makeCharacterRowEntity(slot: 2))
        addModalEntity(makeCharacterRowEntity(slot: 3))
        addModalEntity(makeCharacterRowEntity(slot: 4))
        addModalEntity(makeSelectedIndicatorEntity())
        addModalEntity(makeCharacterNameEntity())
        addModalEntity(makeCharacterSubtitleEntity())
        addModalEntity(makeCharacterSelectButtonEntity())

        applyLayout()
        updateCharacterDisplay()
    }

    private func presentSettingsModal() {
        dismissActiveModal()
        activeModal = .settings

        addModalEntity(makeDimOverlayEntity())
        addModalEntity(makeSettingsPanelEntity())
        addModalEntity(makeCloseButtonEntity())
        addModalEntity(makePreviewEntity())

        let (brightnessLabel, brightnessSlider) = makeSliderRow(title: "Background brightness", value: 0.5)
        addModalEntity(brightnessLabel)
        addModalEntity(brightnessSlider)

        let (musicLabel, musicSlider) = makeSliderRow(title: "Music", value: 0.6)
        addModalEntity(musicLabel)
        addModalEntity(musicSlider)

        let (sfxLabel, sfxSlider) = makeSliderRow(title: "SFX", value: 0.6)
        addModalEntity(sfxLabel)
        addModalEntity(sfxSlider)

        applyLayout()
    }

    private func dismissActiveModal() {
        guard activeModal != .none else { return }
        activeModal = .none

        for entity in modalEntities {
            if let render = entity.component(ofType: RenderComponent.self) {
                render.node.removeFromParent()
            }

            if let index = entities.firstIndex(where: { $0 === entity }) {
                entities.remove(at: index)
            }
        }

        modalEntities.removeAll()
        modalButtonEntities.removeAll()
        sliderEntities.removeAll()
        activeSlider = nil
        characterNameNode = nil
        characterSubtitleNode = nil
        coinLabelNode = nil
        selectedIndicatorNode = nil
        selectButtonNode = nil
        selectButtonLabelNode = nil
    }

    private func makeCharacterPanelEntity() -> GKEntity {
        let panelNode = SKShapeNode()
        panelNode.fillColor = NSColor(white: 0.88, alpha: 1.0)
        panelNode.strokeColor = .clear
        panelNode.zPosition = 20

        let entity = GameEntity(node: panelNode)
        entity.addComponent(LayoutComponent { [weak self] node, sceneSize in
            guard let self = self, let shapeNode = node as? SKShapeNode else { return }
            let panelFrame = self.panelFrame(for: sceneSize)
            let cornerRadius = panelFrame.height * 0.08
            shapeNode.path = CGPath(roundedRect: CGRect(origin: .zero, size: panelFrame.size),
                                    cornerWidth: cornerRadius,
                                    cornerHeight: cornerRadius,
                                    transform: nil)
            shapeNode.position = panelFrame.origin
        })

        return entity
    }

    private func makeCoinBadgeEntity() -> GKEntity {
        let badgeNode = SKShapeNode()
        badgeNode.fillColor = .white
        badgeNode.strokeColor = .clear
        badgeNode.zPosition = 30

        let coinNode = SKSpriteNode(imageNamed: "coin")
        coinNode.setScale(0.6)

        let label = SKLabelNode(text: "34")
        label.fontName = "Helvetica-Bold"
        label.fontColor = .black
        label.horizontalAlignmentMode = .left
        label.verticalAlignmentMode = .center
        coinLabelNode = label

        badgeNode.addChild(coinNode)
        badgeNode.addChild(label)

        let entity = GameEntity(node: badgeNode)
        entity.addComponent(LayoutComponent { [weak self] node, sceneSize in
            guard let self = self, let shapeNode = node as? SKShapeNode else { return }
            let panelFrame = self.panelFrame(for: sceneSize)
            let scale = min(sceneSize.width / 1280.0, sceneSize.height / 800.0)
            let badgeSize = CGSize(width: 140.0 * scale, height: 60.0 * scale)
            shapeNode.path = CGPath(roundedRect: CGRect(origin: .zero, size: badgeSize),
                                    cornerWidth: badgeSize.height * 0.5,
                                    cornerHeight: badgeSize.height * 0.5,
                                    transform: nil)
            shapeNode.position = CGPoint(x: panelFrame.maxX - badgeSize.width - 24.0 * scale,
                                         y: panelFrame.maxY - badgeSize.height - 24.0 * scale)

            coinNode.position = CGPoint(x: badgeSize.height * 0.5, y: badgeSize.height * 0.5)
            label.fontSize = 24.0 * scale
            label.position = CGPoint(x: badgeSize.height * 0.9, y: badgeSize.height * 0.5)
            label.text = "\(self.coins)"
        })

        return entity
    }

    private func makeCharacterChevronsEntity(direction: Int) -> GKEntity {
        let buttonNode = SKShapeNode()
        buttonNode.fillColor = .clear
        buttonNode.strokeColor = .clear
        buttonNode.zPosition = 30

        let label = SKLabelNode(text: direction < 0 ? "<" : ">")
        label.fontName = "Helvetica-Bold"
        label.fontColor = .black
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        buttonNode.addChild(label)

        let entity = GameEntity(node: buttonNode)
        entity.addComponent(InputComponent { [weak self] in
            self?.stepCharacterSelection(by: direction)
        })

        entity.addComponent(LayoutComponent { [weak self] node, sceneSize in
            guard let self = self, let shapeNode = node as? SKShapeNode else { return }
            let panelFrame = self.panelFrame(for: sceneSize)
            let scale = min(sceneSize.width / 1280.0, sceneSize.height / 800.0)
            let buttonSize = CGSize(width: 44.0 * scale, height: 44.0 * scale)
            let centerY = panelFrame.minY + panelFrame.height * 0.55
            let xOffset = panelFrame.width * 0.43
            let centerX = direction < 0 ? panelFrame.midX - xOffset : panelFrame.midX + xOffset
            shapeNode.path = CGPath(rect: CGRect(origin: .zero, size: buttonSize), transform: nil)
            shapeNode.position = CGPoint(x: centerX - buttonSize.width * 0.5,
                                         y: centerY - buttonSize.height * 0.5)

            label.fontSize = 32.0 * scale
            label.position = CGPoint(x: buttonSize.width * 0.5, y: buttonSize.height * 0.5)
        })

        return entity
    }

    private func makeCharacterRowEntity(slot: Int) -> GKEntity {
        let container = SKNode()
        container.zPosition = 25

        let bodyNode = SKShapeNode()
        bodyNode.strokeColor = .clear

        let nameLabel = SKLabelNode(text: "")
        nameLabel.fontName = "Helvetica-Bold"
        nameLabel.fontColor = .black
        nameLabel.horizontalAlignmentMode = .center
        nameLabel.verticalAlignmentMode = .center

        container.addChild(bodyNode)
        container.addChild(nameLabel)

        let entity = GameEntity(node: container)
        entity.addComponent(LayoutComponent { [weak self] _, sceneSize in
            guard let self = self else { return }
            let panelFrame = self.panelFrame(for: sceneSize)
            let scale = min(sceneSize.width / 1280.0, sceneSize.height / 800.0)
            let centers = self.characterSlotCenters(for: panelFrame)
            guard slot < centers.count else { return }

            let displayIndex = self.visibleCharacterIndex(for: slot)
            let isSelected = slot == 2
            let bodySize = isSelected
                ? CGSize(width: 120.0 * scale, height: 240.0 * scale)
                : CGSize(width: 70.0 * scale, height: 140.0 * scale)
            let center = centers[slot]

            bodyNode.path = CGPath(rect: CGRect(origin: .zero, size: bodySize), transform: nil)
            bodyNode.position = CGPoint(x: center.x - bodySize.width * 0.5,
                                        y: center.y - bodySize.height * 0.45)

            let entry = self.characters[displayIndex]
            bodyNode.fillColor = entry.color

            nameLabel.text = entry.name
            nameLabel.fontSize = (isSelected ? 22.0 : 16.0) * scale
            nameLabel.position = CGPoint(x: center.x,
                                         y: bodyNode.position.y - (isSelected ? 24.0 : 18.0) * scale)
        })

        return entity
    }

    private func makeSelectedIndicatorEntity() -> GKEntity {
        let indicatorNode = SKShapeNode()
        indicatorNode.fillColor = NSColor(calibratedRed: 0.31, green: 0.74, blue: 0.46, alpha: 1.0)
        indicatorNode.strokeColor = .clear
        indicatorNode.zPosition = 30
        selectedIndicatorNode = indicatorNode

        let entity = GameEntity(node: indicatorNode)
        entity.addComponent(LayoutComponent { [weak self] node, sceneSize in
            guard let self = self, let shapeNode = node as? SKShapeNode else { return }
            let panelFrame = self.panelFrame(for: sceneSize)
            let scale = min(sceneSize.width / 1280.0, sceneSize.height / 800.0)
            let centers = self.characterSlotCenters(for: panelFrame)
            guard !centers.isEmpty else { return }
            let slotIndex = self.selectedIndicatorSlotIndex(totalSlots: centers.count)
            let center = centers[slotIndex]
            let size = CGSize(width: 40.0 * scale, height: 32.0 * scale)

            let path = CGMutablePath()
            path.move(to: CGPoint(x: size.width * 0.5, y: 0.0))
            path.addLine(to: CGPoint(x: size.width, y: size.height))
            path.addLine(to: CGPoint(x: 0.0, y: size.height))
            path.closeSubpath()

            shapeNode.path = path
            shapeNode.position = CGPoint(x: center.x - size.width * 0.5,
                                         y: panelFrame.minY + panelFrame.height * 0.78)
        })

        return entity
    }

    private func makeCharacterNameEntity() -> GKEntity {
        let label = SKLabelNode(text: "")
        label.fontName = "Helvetica-Bold"
        label.fontColor = .black
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.zPosition = 25
        characterNameNode = label

        let entity = GameEntity(node: label)
        entity.addComponent(LayoutComponent { [weak self] node, sceneSize in
            guard let self = self, let labelNode = node as? SKLabelNode else { return }
            let panelFrame = self.panelFrame(for: sceneSize)
            let scale = min(sceneSize.width / 1280.0, sceneSize.height / 800.0)
            labelNode.fontSize = 36.0 * scale
            labelNode.position = CGPoint(x: panelFrame.midX,
                                         y: panelFrame.minY + panelFrame.height * 0.24)
        })

        return entity
    }

    private func makeCharacterSubtitleEntity() -> GKEntity {
        let label = SKLabelNode(text: "")
        label.fontName = "Helvetica"
        label.fontColor = .black
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.zPosition = 25
        characterSubtitleNode = label

        let entity = GameEntity(node: label)
        entity.addComponent(LayoutComponent { [weak self] node, sceneSize in
            guard let self = self, let labelNode = node as? SKLabelNode else { return }
            let panelFrame = self.panelFrame(for: sceneSize)
            let scale = min(sceneSize.width / 1280.0, sceneSize.height / 800.0)
            labelNode.fontSize = 18.0 * scale
            labelNode.position = CGPoint(x: panelFrame.midX,
                                         y: panelFrame.minY + panelFrame.height * 0.18)
        })

        return entity
    }

    private func makeCharacterSelectButtonEntity() -> GKEntity {
        let buttonNode = SKShapeNode()
        buttonNode.fillColor = NSColor(calibratedRed: 0.31, green: 0.39, blue: 0.74, alpha: 1.0)
        buttonNode.strokeColor = .clear
        buttonNode.zPosition = 25
        selectButtonNode = buttonNode

        let label = SKLabelNode(text: "SELECT")
        label.fontName = "Helvetica-Bold"
        label.fontColor = .white
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        buttonNode.addChild(label)
        selectButtonLabelNode = label

        let entity = GameEntity(node: buttonNode)
        entity.addComponent(InputComponent { [weak self] in
            guard let self = self else { return }
            let entry = self.characters[self.characterIndex]
            if entry.isLocked {
                self.presentPurchaseConfirmation(for: self.characterIndex)
            } else {
                self.selectedCharacterIndex = self.characterIndex
                self.updateCharacterDisplay()
            }
        })
        entity.addComponent(LayoutComponent { [weak self] node, sceneSize in
            guard let self = self, let shapeNode = node as? SKShapeNode else { return }
            let panelFrame = self.panelFrame(for: sceneSize)
            let scale = min(sceneSize.width / 1280.0, sceneSize.height / 800.0)
            let size = CGSize(width: 220.0 * scale, height: 64.0 * scale)
            shapeNode.path = CGPath(roundedRect: CGRect(origin: .zero, size: size),
                                    cornerWidth: size.height * 0.5,
                                    cornerHeight: size.height * 0.5,
                                    transform: nil)
            shapeNode.position = CGPoint(x: panelFrame.midX - size.width * 0.5,
                                         y: panelFrame.minY + panelFrame.height * 0.08)

            label.fontSize = 24.0 * scale
            label.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        })

        return entity
    }

    private func stepCharacterSelection(by direction: Int) {
        guard !characters.isEmpty else { return }
        let count = characters.count
        characterIndex = (characterIndex + direction + count) % count
        updateCharacterDisplay()
    }

    private func updateCharacterDisplay() {
        let entry = characters[characterIndex]
        characterNameNode?.text = entry.name
        characterSubtitleNode?.text = entry.subtitle

        if entry.isLocked {
            selectButtonLabelNode?.text = "UNLOCK \(entry.price)"
            selectButtonNode?.fillColor = NSColor(calibratedRed: 0.74, green: 0.31, blue: 0.31, alpha: 1.0)
        } else {
            let isSelected = characterIndex == selectedCharacterIndex
            selectButtonLabelNode?.text = isSelected ? "SELECTED" : "SELECT"
            selectButtonNode?.fillColor = isSelected
                ? NSColor(calibratedRed: 0.31, green: 0.74, blue: 0.46, alpha: 1.0)
                : NSColor(calibratedRed: 0.31, green: 0.39, blue: 0.74, alpha: 1.0)
        }
        applyLayout()
    }

    private func presentPurchaseConfirmation(for index: Int) {
        guard !purchaseActive else { return }
        purchaseActive = true
        pendingPurchaseIndex = index

        addPurchaseEntity(makePurchaseDimEntity())
        addPurchaseEntity(makePurchasePromptEntity())
        addPurchaseEntity(makePurchaseInstructionEntity())
        applyLayout()
    }

    private func dismissPurchaseConfirmation() {
        purchaseActive = false
        pendingPurchaseIndex = nil

        for entity in purchaseEntities {
            if let render = entity.component(ofType: RenderComponent.self) {
                render.node.removeFromParent()
            }

            if let index = entities.firstIndex(where: { $0 === entity }) {
                entities.remove(at: index)
            }
        }

        purchaseEntities.removeAll()
    }

    private func confirmPurchaseIfPossible() {
        guard let index = pendingPurchaseIndex, index < characters.count else {
            dismissPurchaseConfirmation()
            return
        }

        if characters[index].isLocked, coins >= characters[index].price {
            coins -= characters[index].price
            characters[index].isLocked = false
            selectedCharacterIndex = index
        }

        dismissPurchaseConfirmation()
        updateCharacterDisplay()
    }

    private func makePurchaseDimEntity() -> GKEntity {
        let overlayNode = SKShapeNode()
        overlayNode.fillColor = NSColor(white: 0.0, alpha: 0.55)
        overlayNode.strokeColor = .clear
        overlayNode.zPosition = 60

        let entity = GameEntity(node: overlayNode)
        entity.addComponent(LayoutComponent { node, sceneSize in
            guard let shapeNode = node as? SKShapeNode else { return }
            shapeNode.path = CGPath(rect: CGRect(origin: .zero, size: sceneSize), transform: nil)
            shapeNode.position = .zero
        })

        return entity
    }

    private func makePurchasePromptEntity() -> GKEntity {
        let label = SKLabelNode(text: "Unlock this character for \(characters[characterIndex].price) coins?")
        label.fontName = "Helvetica-Bold"
        label.fontColor = .white
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.zPosition = 70

        let entity = GameEntity(node: label)
        entity.addComponent(LayoutComponent { node, sceneSize in
            guard let labelNode = node as? SKLabelNode else { return }
            let scale = min(sceneSize.width / 1280.0, sceneSize.height / 800.0)
            labelNode.fontSize = 28.0 * scale
            labelNode.position = CGPoint(x: sceneSize.width * 0.5, y: sceneSize.height * 0.55)
        })

        return entity
    }

    private func makePurchaseInstructionEntity() -> GKEntity {
        let label = SKLabelNode(text: "Press Enter to purchase, Esc to cancel")
        label.fontName = "Helvetica"
        label.fontColor = .white
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.zPosition = 70

        let entity = GameEntity(node: label)
        entity.addComponent(LayoutComponent { node, sceneSize in
            guard let labelNode = node as? SKLabelNode else { return }
            let scale = min(sceneSize.width / 1280.0, sceneSize.height / 800.0)
            labelNode.fontSize = 18.0 * scale
            labelNode.position = CGPoint(x: sceneSize.width * 0.5, y: sceneSize.height * 0.48)
        })

        return entity
    }

    private func characterSlotCenters(for panelFrame: CGRect) -> [CGPoint] {
        let slotCount = 5
        let centerY = panelFrame.minY + panelFrame.height * 0.55
        let minX = panelFrame.minX + panelFrame.width * 0.15
        let maxX = panelFrame.maxX - panelFrame.width * 0.15
        let step = (maxX - minX) / CGFloat(slotCount - 1)

        return (0..<slotCount).map { index in
            CGPoint(x: minX + step * CGFloat(index), y: centerY)
        }
    }

    private func visibleCharacterIndex(for slot: Int) -> Int {
        let count = characters.count
        guard count > 0 else { return 0 }
        let offset = slot - 2
        return (characterIndex + offset + count) % count
    }

    private func selectedIndicatorSlotIndex(totalSlots: Int) -> Int {
        guard totalSlots > 0 else { return 0 }
        let count = characters.count
        guard count > 0 else { return min(2, totalSlots - 1) }

        var delta = selectedCharacterIndex - characterIndex
        if abs(delta) > count / 2 {
            delta += delta > 0 ? -count : count
        }

        let clampedDelta = max(-2, min(2, delta))
        let slot = 2 + clampedDelta
        return max(0, min(totalSlots - 1, slot))
    }

    private func sliderRowYPosition(for title: String, sceneSize: CGSize) -> CGFloat {
        let panelFrame = panelFrame(for: sceneSize)

        switch title {
        case "Background brightness":
            return panelFrame.minY + panelFrame.height * 0.43
        case "Music":
            return panelFrame.minY + panelFrame.height * 0.30
        case "SFX":
            return panelFrame.minY + panelFrame.height * 0.18
        default:
            return panelFrame.minY + panelFrame.height * 0.30
        }
    }

    private func makeDimOverlayEntity() -> GKEntity {
        let overlayNode = SKShapeNode()
        overlayNode.fillColor = NSColor(white: 0.0, alpha: 0.25)
        overlayNode.strokeColor = .clear
        overlayNode.zPosition = 10

        let entity = GameEntity(node: overlayNode)
        entity.addComponent(LayoutComponent { node, sceneSize in
            guard let shapeNode = node as? SKShapeNode else { return }
            shapeNode.path = CGPath(rect: CGRect(origin: .zero, size: sceneSize), transform: nil)
            shapeNode.position = .zero
        })

        return entity
    }
}
