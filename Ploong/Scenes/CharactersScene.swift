//
//  CharactersScene.swift
//  Ploong
//
//  Created by Matthew Fernando Anggrian on 11/05/26.
//

import SpriteKit

final class CharactersScene: SKScene {
    private var didSetupLayout = false
    
    private var characterNodes: [SKSpriteNode] = []
    private var characterLabels: [SKSpriteNode] = []
    private var selectButton: SKSpriteNode?
    private var indicator: SKSpriteNode?
    
    private var currentlyHighlightedIndex = 0
    private var currentlySelectedCharacterIndex = 0
    
    private let charCount = 5

    // Tweakables stored as properties to ensure consistency between setup and touch events
    private let charBaseWidth: CGFloat = 130.0
    private let charSpacing: CGFloat = 210.0
    private let charY: CGFloat = 60.0
    private let highlightScaleMult: CGFloat = 1.35
    private let labelGap: CGFloat = 25.0
    private let labelHighlightShift: CGFloat = 15.0
    private let indicatorGap: CGFloat = 30.0

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
        BackgroundManager.shared.setupBackground(in: self)
        BackgroundManager.shared.setOrnamentsVisible(false, animated: false)
    }

    private func buildLayout() {
        // --- UI TWEAKABLES ---
        let coinUIPosition = CGPoint(x: 440, y: 330) // Positioned relative to modal center
        let selectButtonY: CGFloat = -235.0
        // ---------------------

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

        let mWidth = modal.size.width / modal.xScale

        // Close Button
        let closeTexture = SKTexture(imageNamed: "close_button")
        closeTexture.filteringMode = .nearest
        let closeButton = SKSpriteNode(texture: closeTexture)
        closeButton.name = "closeButton"
        closeButton.position = CGPoint(x: -mWidth * 0.44, y: modal.size.height * 0.40 / modal.yScale)
        closeButton.zPosition = 10 // High Z-position
        modal.addChild(closeButton)

        // Coin Logic - Ensure coin is child of modal and has high Z-index
        let coinBgTexture = SKTexture(imageNamed: "coin_bg")
        coinBgTexture.filteringMode = .nearest
        let coinBg = SKSpriteNode(texture: coinBgTexture)
        coinBg.position = coinUIPosition
        coinBg.zPosition = 10
        modal.addChild(coinBg)

        let coinImgTexture = SKTexture(imageNamed: "coin_img")
        coinImgTexture.filteringMode = .nearest
        let coinImg = SKSpriteNode(texture: coinImgTexture)
        coinImg.position = CGPoint(x: -35, y: 0)
        coinImg.zPosition = 1
        coinBg.addChild(coinImg)

        let coinLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        coinLabel.text = "67"
        coinLabel.fontSize = 28
        coinLabel.fontColor = .black
        coinLabel.horizontalAlignmentMode = .left
        coinLabel.verticalAlignmentMode = .center
        coinLabel.position = CGPoint(x: -10, y: 0)
        coinLabel.zPosition = 1
        coinBg.addChild(coinLabel)

        // Setup Characters
        let startX = -CGFloat(charCount - 1) * charSpacing * 0.5
        for i in 0..<charCount {
            let isJoy = (i == 0)
            let tex = SKTexture(imageNamed: isJoy ? "joy_char" : "unknown_char")
            tex.filteringMode = .nearest
            
            let char = SKSpriteNode(texture: tex)
            char.name = "char_\(i)"
            char.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            char.position = CGPoint(x: startX + CGFloat(i) * charSpacing, y: charY)
            char.zPosition = 3
            
            let initialScale = charBaseWidth / tex.size().width
            char.setScale(initialScale)
            
            modal.addChild(char)
            characterNodes.append(char)
            
            let lTex = SKTexture(imageNamed: isJoy ? "joy_text" : "unknown_text")
            lTex.filteringMode = .nearest
            let labelSprite = SKSpriteNode(texture: lTex)
            labelSprite.anchorPoint = CGPoint(x: 0.5, y: 1.0)
            labelSprite.position = CGPoint(x: char.position.x, y: 0)
            labelSprite.zPosition = 3
            modal.addChild(labelSprite)
            characterLabels.append(labelSprite)
        }

        let indTex = SKTexture(imageNamed: "selected_indicator")
        indTex.filteringMode = .nearest
        indicator = SKSpriteNode(texture: indTex)
        indicator?.anchorPoint = CGPoint(x: 0.5, y: 0)
        indicator?.zPosition = 5
        if let ind = indicator { modal.addChild(ind) }

        selectButton = SKSpriteNode(imageNamed: "selected_button")
        selectButton?.name = "selectButton"
        selectButton?.texture?.filteringMode = .nearest
        selectButton?.position = CGPoint(x: 0, y: selectButtonY)
        selectButton?.zPosition = 5
        if let sb = selectButton { modal.addChild(sb) }

        refreshSelectionUI()
    }

    private func refreshSelectionUI() {
        for (index, node) in characterNodes.enumerated() {
            let isHighlighted = (index == currentlyHighlightedIndex)
            let isSelected = (index == currentlySelectedCharacterIndex)
            
            guard let tex = node.texture else { continue }
            let baseScale = charBaseWidth / tex.size().width
            let targetScale: CGFloat = isHighlighted ? (baseScale * highlightScaleMult) : baseScale
            
            node.removeAllActions()
            node.run(SKAction.scale(to: targetScale, duration: 0.1))
            node.zPosition = isHighlighted ? 8 : 3
            
            let label = characterLabels[index]
            let currentGap = isHighlighted ? (labelGap + labelHighlightShift) : labelGap
            let targetFeetY = node.position.y - (tex.size().height * targetScale * 0.5)
            
            label.removeAllActions()
            label.run(SKAction.moveTo(y: targetFeetY - currentGap, duration: 0.1))

            if isSelected {
                let currentVisualScale = isHighlighted ? (baseScale * highlightScaleMult) : baseScale
                let targetHeadY = node.position.y + (tex.size().height * currentVisualScale * 0.5)
                
                indicator?.removeAllActions()
                indicator?.run(SKAction.group([
                    SKAction.moveTo(x: node.position.x, duration: 0.05),
                    SKAction.moveTo(y: targetHeadY + indicatorGap, duration: 0.05)
                ]))
            }
        }

        let isLookingAtSelected = (currentlyHighlightedIndex == currentlySelectedCharacterIndex)
        let texName = isLookingAtSelected ? "selected_button" : "unselected_button"
        selectButton?.texture = SKTexture(imageNamed: texName)
        selectButton?.texture?.filteringMode = .nearest
    }

    override func mouseDown(with event: NSEvent) {
        let location = event.location(in: self)
        let nodesAtPoint = nodes(at: location)

        if nodesAtPoint.contains(where: { $0.name == "closeButton" }) {
            presentMenu()
            return
        }

        for i in 0..<characterNodes.count {
            if nodesAtPoint.contains(characterNodes[i]) {
                currentlyHighlightedIndex = i
                refreshSelectionUI()
                return
            }
        }

        if nodesAtPoint.contains(where: { $0.name == "selectButton" }) {
            currentlySelectedCharacterIndex = currentlyHighlightedIndex
            refreshSelectionUI()
        }
    }

    private func presentMenu() {
        guard let view = view else { return }
        let scene = MenuScene(size: size)
        scene.scaleMode = scaleMode
        view.presentScene(scene)
    }
}
