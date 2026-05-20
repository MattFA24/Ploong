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
    private weak var coinLabel: SKLabelNode?

    // Purchase Modal UI
    private var purchaseModal: SKNode?

    private var currentlyHighlightedIndex = 0
    private var currentlySelectedCharacterIndex = 0

    private let charNames = ["Joy", "Tiu", "Jevon", "Vey", "Farrell"]
    private let charCount = 5

    // ── Tweakables ───────────────────────────────────────────────────────────
    private let charBaseWidth: CGFloat       = 130.0
    private let charSpacing: CGFloat         = 210.0
    private let charY: CGFloat               = 60.0
    private let highlightScaleMult: CGFloat  = 1.35
    private let labelGap: CGFloat            = 25.0
    private let labelHighlightShift: CGFloat = 15.0
    private let indicatorGap: CGFloat        = 30.0
    // ─────────────────────────────────────────────────────────────────────────

    // MARK: - Scene lifecycle

    override func sceneDidLoad() {
        super.sceneDidLoad()
        backgroundColor = .clear

        let equipped = CharacterManager.shared.getEquippedCharacter()
        if let idx = charNames.firstIndex(of: equipped) {
            currentlySelectedCharacterIndex = idx
            currentlyHighlightedIndex = idx
        }
    }

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        if !didSetupLayout {
            didSetupLayout = true
            buildLayout()
            setupPurchaseModal()
        }
        BackgroundManager.shared.setupBackground(in: self)
        BackgroundManager.shared.setOrnamentsVisible(false, animated: false)
    }

    // MARK: - Layout

    private func buildLayout() {
        let coinUIPosition = CGPoint(x: 440, y: 330)
        let selectButtonY: CGFloat = -235.0

        let dimmer = SKShapeNode(rectOf: size)
        dimmer.fillColor   = NSColor(white: 0, alpha: 0.35)
        dimmer.strokeColor = .clear
        dimmer.position    = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        dimmer.zPosition   = 0
        addChild(dimmer)

        let modalTexture = SKTexture(imageNamed: "modal_window")
        modalTexture.filteringMode = .nearest
        let modal = SKSpriteNode(texture: modalTexture)
        modal.position  = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        modal.zPosition = 1
        modal.setScale((size.width * 0.85) / modal.size.width)
        addChild(modal)

        let mWidth = modal.size.width / modal.xScale

        let closeTex = SKTexture(imageNamed: "close_button")
        closeTex.filteringMode = .nearest
        let closeButton = SKSpriteNode(texture: closeTex)
        closeButton.name    = "closeButton"
        closeButton.position  = CGPoint(x: -mWidth * 0.44, y: modal.size.height * 0.40 / modal.yScale)
        closeButton.zPosition = 10
        modal.addChild(closeButton)

        // Coin display
        let coinBgTex = SKTexture(imageNamed: "coin_bg")
        coinBgTex.filteringMode = .nearest
        let coinBg = SKSpriteNode(texture: coinBgTex)
        coinBg.position  = coinUIPosition
        coinBg.zPosition = 10
        modal.addChild(coinBg)

        let coinImgTex = SKTexture(imageNamed: "coin_img")
        coinImgTex.filteringMode = .nearest
        let coinImg = SKSpriteNode(texture: coinImgTex)
        coinImg.position  = CGPoint(x: -35, y: 0)
        coinImg.zPosition = 1
        coinBg.addChild(coinImg)

        let lbl = SKLabelNode(fontNamed: "AvenirNext-Bold")
        lbl.text                = "\(UserDefaults.standard.integer(forKey: "TotalCoins"))"
        lbl.fontSize            = 28
        lbl.fontColor           = .black
        lbl.horizontalAlignmentMode = .left
        lbl.verticalAlignmentMode   = .center
        lbl.position            = CGPoint(x: -10, y: 0)
        lbl.zPosition           = 1
        coinBg.addChild(lbl)
        coinLabel = lbl

        // Characters
        let startX = -CGFloat(charCount - 1) * charSpacing * 0.5
        for i in 0..<charCount {
            let charName  = charNames[i]
            let isOwned   = CharacterManager.shared.getOwnedCharacters().contains(charName)
            let assetName = isOwned ? "\(charName.lowercased())_char" : "unknown_\(charName.lowercased())"

            let tex = SKTexture(imageNamed: assetName)
            tex.filteringMode = .nearest

            let char = SKSpriteNode(texture: tex)
            char.name      = "char_\(i)"
            char.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            char.position    = CGPoint(x: startX + CGFloat(i) * charSpacing, y: charY)
            char.zPosition   = 3
            char.setScale(charBaseWidth / tex.size().width)
            modal.addChild(char)
            characterNodes.append(char)

            let lblAsset = isOwned ? "\(charName.lowercased())_text" : "unknown_text"
            let lTex = SKTexture(imageNamed: lblAsset)
            lTex.filteringMode = .nearest
            let labelSprite = SKSpriteNode(texture: lTex)
            labelSprite.anchorPoint = CGPoint(x: 0.5, y: 1.0)
            let baseScale = charBaseWidth / tex.size().width
            let feetY     = charY - (tex.size().height * baseScale * 0.5)
            labelSprite.position  = CGPoint(x: char.position.x, y: feetY - labelGap)
            labelSprite.zPosition = 3
            modal.addChild(labelSprite)
            characterLabels.append(labelSprite)
        }

        // Indicator
        let indTex = SKTexture(imageNamed: "selected_indicator")
        indTex.filteringMode = .nearest
        indicator              = SKSpriteNode(texture: indTex)
        indicator?.anchorPoint = CGPoint(x: 0.5, y: 0)
        indicator?.zPosition   = 5
        if let ind = indicator { modal.addChild(ind) }

        // Select button
        let sbTex = SKTexture(imageNamed: "selected_button")
        sbTex.filteringMode = .nearest
        selectButton            = SKSpriteNode(texture: sbTex)
        selectButton?.name      = "selectButton"
        selectButton?.position  = CGPoint(x: 0, y: selectButtonY)
        selectButton?.zPosition = 5
        if let sb = selectButton { modal.addChild(sb) }

        snapIndicatorToSelected()
        refreshSelectionUI()
    }

    // MARK: - Indicator snap

    private func snapIndicatorToSelected() {
        guard currentlySelectedCharacterIndex < characterNodes.count else { return }
        let node = characterNodes[currentlySelectedCharacterIndex]
        guard let tex = node.texture else { return }

        let isHighlighted = (currentlySelectedCharacterIndex == currentlyHighlightedIndex)
        let baseScale     = charBaseWidth / tex.size().width
        let visualScale   = isHighlighted ? (baseScale * highlightScaleMult) : baseScale
        let headY         = node.position.y + (tex.size().height * visualScale * 0.5)
        indicator?.position = CGPoint(x: node.position.x, y: headY + indicatorGap)
    }

    // MARK: - Purchase modal

    private func setupPurchaseModal() {
        purchaseModal            = SKNode()
        purchaseModal?.zPosition = 100
        purchaseModal?.position  = .zero
        purchaseModal?.isHidden  = true
        addChild(purchaseModal!)

        let pmDimmer = SKShapeNode(rectOf: size)
        pmDimmer.fillColor   = NSColor(white: 0, alpha: 0.6)
        pmDimmer.strokeColor = .clear
        pmDimmer.position    = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        pmDimmer.zPosition   = 0
        purchaseModal?.addChild(pmDimmer)

        let bg      = SKSpriteNode(imageNamed: "unlock_confirmation_1")
        bg.name     = "modalBg"
        bg.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        bg.zPosition = 1
        purchaseModal?.addChild(bg)

        let confirmCoin = SKSpriteNode(imageNamed: "coin_img")
        confirmCoin.texture?.filteringMode = .nearest
        confirmCoin.position  = CGPoint(x: -20, y: 10)
        confirmCoin.zPosition = 2
        bg.addChild(confirmCoin)

        let yesBtn       = SKSpriteNode(imageNamed: "unlock_confirmation_2")
        yesBtn.name      = "pmYes"
        yesBtn.position  = CGPoint(x: 0, y: -90)
        yesBtn.zPosition = 2
        bg.addChild(yesBtn)
    }

    // MARK: - Selection UI

    private func refreshSelectionUI() {
        let owned = CharacterManager.shared.getOwnedCharacters()

        for (index, node) in characterNodes.enumerated() {
            let charName      = charNames[index]
            let isOwned       = owned.contains(charName)
            let isHighlighted = (index == currentlyHighlightedIndex)
            let isSelected    = (index == currentlySelectedCharacterIndex)

            let assetName = isOwned ? "\(charName.lowercased())_char" : "unknown_\(charName.lowercased())"
            let tex       = SKTexture(imageNamed: assetName)
            tex.filteringMode = .nearest
            node.texture      = tex

            let lblTex = SKTexture(imageNamed: isOwned ? "\(charName.lowercased())_text" : "unknown_text")
            lblTex.filteringMode         = .nearest
            characterLabels[index].texture = lblTex

            let baseScale   = charBaseWidth / tex.size().width
            let targetScale = isHighlighted ? (baseScale * highlightScaleMult) : baseScale
            node.removeAllActions()
            node.run(SKAction.scale(to: targetScale, duration: 0.1))
            node.zPosition = isHighlighted ? 8 : 3

            let label       = characterLabels[index]
            let currentGap  = isHighlighted ? (labelGap + labelHighlightShift) : labelGap
            let targetFeetY = node.position.y - (tex.size().height * targetScale * 0.5)
            label.removeAllActions()
            label.run(SKAction.moveTo(y: targetFeetY - currentGap, duration: 0.1))

            if isSelected {
                let visualScale = isHighlighted ? (baseScale * highlightScaleMult) : baseScale
                let targetHeadY = node.position.y + (tex.size().height * visualScale * 0.5)
                indicator?.removeAllActions()
                indicator?.run(SKAction.group([
                    SKAction.moveTo(x: node.position.x, duration: 0.05),
                    SKAction.moveTo(y: targetHeadY + indicatorGap, duration: 0.05)
                ]))
            }
        }

        let highlightedOwned  = owned.contains(charNames[currentlyHighlightedIndex])
        let isAlreadySelected = (currentlyHighlightedIndex == currentlySelectedCharacterIndex)

        selectButton?.parent?.childNode(withName: "priceNode")?.removeFromParent()

        if highlightedOwned {
            let btnTexName = isAlreadySelected ? "selected_button" : "unselected_button"
            let btnTex = SKTexture(imageNamed: btnTexName)
            btnTex.filteringMode   = .nearest
            selectButton?.texture  = btnTex
            selectButton?.isHidden = false
        } else {
            selectButton?.isHidden = true

            let priceNode = SKNode()
            priceNode.name      = "priceNode"
            priceNode.position  = selectButton?.position ?? .zero
            priceNode.zPosition = 5

            let priceCoin = SKSpriteNode(imageNamed: "coin_img")
            priceCoin.texture?.filteringMode = .nearest
            priceCoin.position      = CGPoint(x: -20, y: 0)
            priceNode.addChild(priceCoin)

            let priceNum = SKSpriteNode(imageNamed: "20")
            priceNum.texture?.filteringMode = .nearest
            priceNum.position      = CGPoint(x: 20, y: 0)
            priceNode.addChild(priceNum)

            selectButton?.parent?.addChild(priceNode)
        }
    }

    // MARK: - Input (mouse)

    override func mouseDown(with event: NSEvent) {
        let location    = event.location(in: self)
        let nodesAtPoint = nodes(at: location)

        if purchaseModal?.isHidden == false {
            if nodesAtPoint.contains(where: { $0.name == "pmYes" }) { attemptPurchase() }
            return
        }

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
            let charName = charNames[currentlyHighlightedIndex]
            if CharacterManager.shared.getOwnedCharacters().contains(charName) {
                currentlySelectedCharacterIndex = currentlyHighlightedIndex
                CharacterManager.shared.equipCharacter(name: charName)
                refreshSelectionUI()
            }
        }

        if nodesAtPoint.contains(where: { $0.name == "priceNode" || $0.parent?.name == "priceNode" }) {
            purchaseModal?.isHidden = false
        }
    }

    // MARK: - Input (keyboard)

    override func keyDown(with event: NSEvent) {
        guard purchaseModal?.isHidden == false else { return }
        switch event.keyCode {
        case 36, 76:
            attemptPurchase()
        case 53:
            purchaseModal?.isHidden = true
        default:
            break
        }
    }

    // MARK: - Purchase

    private func attemptPurchase() {
        let charName = charNames[currentlyHighlightedIndex]
        if CharacterManager.shared.purchaseCharacter(name: charName, currentCoins: UserDefaults.standard.integer(forKey: "TotalCoins")) {
            coinLabel?.text = "\(UserDefaults.standard.integer(forKey: "TotalCoins"))"
            purchaseModal?.isHidden = true
            refreshSelectionUI()
        } else {
            purchaseModal?.childNode(withName: "modalBg")?.run(SKAction.sequence([
                SKAction.moveBy(x:  10, y: 0, duration: 0.05),
                SKAction.moveBy(x: -20, y: 0, duration: 0.05),
                SKAction.moveBy(x:  10, y: 0, duration: 0.05)
            ]))
        }
    }

    // MARK: - Navigation

    private func presentMenu() {
        guard let view = view else { return }
        let scene = MenuScene(size: size)
        scene.scaleMode = scaleMode
        view.presentScene(scene)
    }
}
