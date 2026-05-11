//
//  CharactersScene.swift
//  Ploong
//
//  Created by Matthew Fernando Anggrian on 11/05/26.
//

import SpriteKit

final class CharactersScene: SKScene {
    private enum NavDirection {
        case left
        case right
    }

    private var didSetupLayout = false
    private var characterNodes: [SKShapeNode] = []
    private var characterLabels: [SKLabelNode] = []
    private var selectedIndex = 2
    private var chosenIndex = 2
    private weak var selectionIndicator: SKShapeNode?
    private weak var selectLabel: SKLabelNode?

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

        let dimmer = SKShapeNode(rectOf: size)
        dimmer.fillColor = NSColor(white: 0, alpha: 0.35)
        dimmer.strokeColor = .clear
        dimmer.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        dimmer.zPosition = 0
        addChild(dimmer)

        let modalSize = CGSize(width: size.width * 0.86, height: size.height * 0.76)
        let modal = SKShapeNode(rectOf: modalSize, cornerRadius: 28)
        modal.fillColor = NSColor(white: 0.88, alpha: 1)
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

        let leftChevron = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        leftChevron.text = "<"
        leftChevron.name = "navLeft"
        leftChevron.fontSize = 40
        leftChevron.fontColor = .black
        leftChevron.verticalAlignmentMode = .center
        leftChevron.position = CGPoint(x: -modalSize.width * 0.45, y: 0)
        leftChevron.zPosition = 2
        modal.addChild(leftChevron)

        let rightChevron = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        rightChevron.text = ">"
        rightChevron.name = "navRight"
        rightChevron.fontSize = 40
        rightChevron.fontColor = .black
        rightChevron.verticalAlignmentMode = .center
        rightChevron.position = CGPoint(x: modalSize.width * 0.45, y: 0)
        rightChevron.zPosition = 2
        modal.addChild(rightChevron)

        let centerY = modalSize.height * 0.1
        let spacing: CGFloat = 140
        let baseSize = CGSize(width: 70, height: 140)
        let highlightSize = CGSize(width: 110, height: 220)

        characterNodes = []
        characterLabels = []

        for index in 0..<5 {
            let node = SKShapeNode(rectOf: baseSize, cornerRadius: 12)
            node.name = "character_\(index)"
            node.fillColor = NSColor(white: 0.2, alpha: 1)
            node.strokeColor = .clear
            node.position = CGPoint(x: CGFloat(index - 2) * spacing, y: centerY)
            node.zPosition = 2
            modal.addChild(node)
            characterNodes.append(node)

            let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
            label.text = index == 1 ? "TiuTiu" : (index == 2 ? "Joy" : "???")
            label.fontSize = 20
            label.fontColor = .black
            label.verticalAlignmentMode = .center
            label.position = CGPoint(x: node.position.x, y: centerY - 120)
            label.zPosition = 2
            modal.addChild(label)
            characterLabels.append(label)
        }

        let title = SKLabelNode(fontNamed: "AvenirNext-Bold")
        title.text = "Joy"
        title.name = "characterTitle"
        title.fontSize = 34
        title.fontColor = .black
        title.verticalAlignmentMode = .center
        title.position = CGPoint(x: 0, y: -modalSize.height * 0.25)
        title.zPosition = 2
        modal.addChild(title)

        let subtitle = SKLabelNode(fontNamed: "AvenirNext-Regular")
        subtitle.text = "your daily joyful gurl"
        subtitle.name = "characterSubtitle"
        subtitle.fontSize = 16
        subtitle.fontColor = .black
        subtitle.verticalAlignmentMode = .center
        subtitle.position = CGPoint(x: 0, y: -modalSize.height * 0.32)
        subtitle.zPosition = 2
        modal.addChild(subtitle)

        let selectButton = SKShapeNode(rectOf: CGSize(width: 160, height: 46), cornerRadius: 23)
        selectButton.name = "selectButton"
        selectButton.fillColor = NSColor(calibratedRed: 0.35, green: 0.4, blue: 0.75, alpha: 1)
        selectButton.strokeColor = .clear
        selectButton.position = CGPoint(x: 0, y: -modalSize.height * 0.42)
        selectButton.zPosition = 2
        modal.addChild(selectButton)

        let selectLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        selectLabel.text = "SELECT"
        selectLabel.fontSize = 18
        selectLabel.fontColor = .white
        selectLabel.verticalAlignmentMode = .center
        selectLabel.zPosition = 3
        selectButton.addChild(selectLabel)
        self.selectLabel = selectLabel

        let indicator = SKShapeNode(path: trianglePath(size: CGSize(width: 28, height: 18)))
        indicator.name = "selectionIndicator"
        indicator.fillColor = NSColor(calibratedRed: 0.3, green: 0.7, blue: 0.3, alpha: 1)
        indicator.strokeColor = .clear
        indicator.zPosition = 4
        modal.addChild(indicator)
        selectionIndicator = indicator

        updateSelection(highlightSize: highlightSize)
    }

    private func addScrollingBackground() {
        let texture = SKTexture(imageNamed: "main_menu_bg")
        let textureSize = texture.size()
        guard textureSize.width > 0, textureSize.height > 0 else {
            return
        }

        let scale = max(size.width / textureSize.width, size.height / textureSize.height)
        let scaledSize = CGSize(width: textureSize.width * scale, height: textureSize.height * scale)
        let duration = TimeInterval(scaledSize.width / 18)

        let bg1 = SKSpriteNode(texture: texture, size: scaledSize)
        let bg2 = SKSpriteNode(texture: texture, size: scaledSize)

        bg1.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        bg2.position = CGPoint(x: bg1.position.x - scaledSize.width, y: bg1.position.y)

        bg1.zPosition = -2
        bg2.zPosition = -2

        let move = SKAction.moveBy(x: scaledSize.width, y: 0, duration: duration)
        let reset = SKAction.moveBy(x: -scaledSize.width, y: 0, duration: 0)
        let loop = SKAction.repeatForever(SKAction.sequence([move, reset]))

        bg1.run(loop)
        bg2.run(loop)

        addChild(bg1)
        addChild(bg2)
    }

    override func mouseDown(with event: NSEvent) {
        let location = event.location(in: self)
        handleSelection(at: location)
    }

    private func handleSelection(at location: CGPoint) {
        if nodes(at: location).contains(where: { $0.name == "closeButton" }) {
            presentMenu()
            return
        }

        if nodes(at: location).contains(where: { $0.name == "navLeft" }) {
            moveSelection(.left)
            return
        }

        if nodes(at: location).contains(where: { $0.name == "navRight" }) {
            moveSelection(.right)
            return
        }

        if nodes(at: location).contains(where: { $0.name == "selectButton" }) {
            chosenIndex = selectedIndex
            updateSelection(highlightSize: CGSize(width: 110, height: 220))
        }
    }

    private func moveSelection(_ direction: NavDirection) {
        let maxIndex = characterNodes.count - 1
        switch direction {
        case .left:
            selectedIndex = max(0, selectedIndex - 1)
        case .right:
            selectedIndex = min(maxIndex, selectedIndex + 1)
        }

        updateSelection(highlightSize: CGSize(width: 110, height: 220))
    }

    private func updateSelection(highlightSize: CGSize) {
        for (index, node) in characterNodes.enumerated() {
            let isSelected = index == selectedIndex
            let targetSize = isSelected ? highlightSize : CGSize(width: 70, height: 140)
            node.path = CGPath(roundedRect: CGRect(x: -targetSize.width * 0.5,
                                                   y: -targetSize.height * 0.5,
                                                   width: targetSize.width,
                                                   height: targetSize.height),
                               cornerWidth: 12,
                               cornerHeight: 12,
                               transform: nil)
            node.fillColor = isSelected ? NSColor(calibratedRed: 0.32, green: 0.4, blue: 0.75, alpha: 1) : NSColor(white: 0.2, alpha: 1)
            node.zPosition = isSelected ? 3 : 2
        }

        if chosenIndex < characterNodes.count {
            let chosen = characterNodes[chosenIndex]
            selectionIndicator?.position = CGPoint(x: chosen.position.x, y: chosen.position.y + 140)
        }

        if selectedIndex == chosenIndex {
            selectLabel?.text = "SELECTED"
            selectLabel?.fontColor = .white
        } else {
            selectLabel?.text = "SELECT"
            selectLabel?.fontColor = .white
        }

        for (index, label) in characterLabels.enumerated() {
            label.fontColor = index == selectedIndex ? .black : NSColor(white: 0.15, alpha: 1)
            label.fontSize = index == selectedIndex ? 22 : 18
        }
    }

    private func trianglePath(size: CGSize) -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: size.height))
        path.addLine(to: CGPoint(x: size.width, y: size.height))
        path.addLine(to: CGPoint(x: size.width * 0.5, y: 0))
        path.closeSubpath()
        return path
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
