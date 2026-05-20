//
//  GameOverScene.swift
//  Ploong
//
//  Created by Matthew Fernando Anggrian on 11/05/26.
//

import SpriteKit

final class GameOverScene: SKScene {
    private enum NodeName: String {
        case retryButton
        case quitButton
    }

    private let finalScore: Int
    private var backgroundNode: SKSpriteNode!
    private var uiContainerNode: SKNode!

    init(size: CGSize, score: Int) {
        self.finalScore = score
        super.init(size: size)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func sceneDidLoad() {
        super.sceneDidLoad()
        buildUI()
        runSplatAnimation()
    }

    private func buildUI() {
        // --- LAYOUT TWEAKABLES: Adjust scales, positions, gaps, and vertical rows here ---
        let titleScale: CGFloat = 0.75
        let titleYOffset: CGFloat = size.height * 0.32
        
        let containerScale: CGFloat = 0.9
        let containerYOffset: CGFloat = size.height * 0.02
        
        let buttonScale: CGFloat = 1.0
        let buttonYOffset: CGFloat = -size.height * 0.28
        let buttonSpacingX: CGFloat = size.width * 0.22
        
        let fontName = "AvenirNext-Bold"
        let labelFontSize: CGFloat = 39.0
        
        // Horizontal separation constants (gaps from center point)
        let scoreGapX: CGFloat = 330.0
        let coinGapX: CGFloat = 330.0
        
        // EDITABLE ROW HEIGHT OFFSETS (Relative to the box center)
        // Adjust these to push specific metric strings up or down inside the asset window
        let scoreRowYOffset: CGFloat = 80.0      // Height position for Score text + amount
        let highScoreRowYOffset: CGFloat = 20.0   // Height position for High Score text + amount
        let coinsRowYOffset: CGFloat = -40.0     // Height position for Coins text + amount
        // --------------------------------------------------------------------------------

        let centerX = size.width * 0.5
        let centerY = size.height * 0.5

        // 1. Initial Animated Canvas Setup
        backgroundNode = SKSpriteNode(imageNamed: "poopie1")
        backgroundNode.size = size
        backgroundNode.position = CGPoint(x: centerX, y: centerY)
        backgroundNode.zPosition = -10
        addChild(backgroundNode)

        // 2. Main Wrapper Node
        uiContainerNode = SKNode()
        uiContainerNode.position = CGPoint.zero
        uiContainerNode.alpha = 0.0
        uiContainerNode.zPosition = 1
        addChild(uiContainerNode)

        // 3. Pixel Art Title Logo
        let titleTex = SKTexture(imageNamed: "gameover_text")
        titleTex.filteringMode = .nearest
        let titleSprite = SKSpriteNode(texture: titleTex)
        titleSprite.position = CGPoint(x: centerX, y: centerY + titleYOffset)
        titleSprite.setScale(titleScale)
        uiContainerNode.addChild(titleSprite)

        // 4. Score Container Box Block
        let scoreContainerTex = SKTexture(imageNamed: "gameover_scorecontainer")
        scoreContainerTex.filteringMode = .nearest
        let scoreContainer = SKSpriteNode(texture: scoreContainerTex)
        scoreContainer.position = CGPoint(x: centerX, y: centerY + containerYOffset)
        scoreContainer.setScale(containerScale)
        scoreContainer.zPosition = 5
        uiContainerNode.addChild(scoreContainer)

        // 5. Grid Row Placement Metrics (Applying your editable Y Offsets)
        let row1Y: CGFloat = centerY + containerYOffset + scoreRowYOffset
        let row2Y: CGFloat = centerY + containerYOffset + highScoreRowYOffset
        let row3Y: CGFloat = centerY + containerYOffset + coinsRowYOffset
        
        // --- Row 1: Score ---
        let scoreLabel = SKLabelNode(fontNamed: fontName)
        scoreLabel.text = "Score"
        scoreLabel.fontSize = labelFontSize
        scoreLabel.fontColor = .black
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.verticalAlignmentMode = .center
        scoreLabel.position = CGPoint(x: centerX - scoreGapX, y: row1Y)
        scoreLabel.zPosition = 10
        uiContainerNode.addChild(scoreLabel)

        let scoreValue = SKLabelNode(fontNamed: fontName)
        scoreValue.text = "\(finalScore)"
        scoreValue.fontSize = labelFontSize
        scoreValue.fontColor = .black
        scoreValue.horizontalAlignmentMode = .right
        scoreValue.verticalAlignmentMode = .center
        scoreValue.position = CGPoint(x: centerX + scoreGapX, y: row1Y)
        scoreValue.zPosition = 10
        uiContainerNode.addChild(scoreValue)

        // --- Row 2: High Score ---
        let highScore = UserDefaults.standard.integer(forKey: "HighScore")
        let highScoreLabel = SKLabelNode(fontNamed: fontName)
        highScoreLabel.text = "High Score"
        highScoreLabel.fontSize = labelFontSize
        highScoreLabel.fontColor = .black
        highScoreLabel.horizontalAlignmentMode = .left
        highScoreLabel.verticalAlignmentMode = .center
        highScoreLabel.position = CGPoint(x: centerX - scoreGapX, y: row2Y)
        highScoreLabel.zPosition = 10
        uiContainerNode.addChild(highScoreLabel)

        let highScoreValue = SKLabelNode(fontNamed: fontName)
        highScoreValue.text = "\(highScore)"
        highScoreValue.fontSize = labelFontSize
        highScoreValue.fontColor = .black
        highScoreValue.horizontalAlignmentMode = .right
        highScoreValue.verticalAlignmentMode = .center
        highScoreValue.position = CGPoint(x: centerX + scoreGapX, y: row2Y)
        highScoreValue.zPosition = 10
        uiContainerNode.addChild(highScoreValue)

        // --- Row 3: Coins ---
        let coinsCollected = UserDefaults.standard.integer(forKey: "CurrentSessionCoins")
        let coinsLabel = SKLabelNode(fontNamed: fontName)
        coinsLabel.text = "Coins"
        coinsLabel.fontSize = labelFontSize
        coinsLabel.fontColor = .black
        coinsLabel.horizontalAlignmentMode = .left
        coinsLabel.verticalAlignmentMode = .center
        coinsLabel.position = CGPoint(x: centerX - coinGapX, y: row3Y)
        coinsLabel.zPosition = 10
        uiContainerNode.addChild(coinsLabel)

        let coinsValue = SKLabelNode(fontNamed: fontName)
        coinsValue.text = "\(coinsCollected)"
        coinsValue.fontSize = labelFontSize
        coinsValue.fontColor = .black
        coinsValue.horizontalAlignmentMode = .right
        coinsValue.verticalAlignmentMode = .center
        coinsValue.position = CGPoint(x: centerX + coinGapX, y: row3Y)
        coinsValue.zPosition = 10
        uiContainerNode.addChild(coinsValue)

        // 6. Text Button Setup
        let retryTex = SKTexture(imageNamed: "retrytext_button")
        retryTex.filteringMode = .nearest
        let retryBtn = SKSpriteNode(texture: retryTex)
        retryBtn.name = NodeName.retryButton.rawValue
        retryBtn.position = CGPoint(x: centerX - buttonSpacingX, y: centerY + buttonYOffset)
        retryBtn.setScale(buttonScale)
        retryBtn.zPosition = 10
        uiContainerNode.addChild(retryBtn)

        let menuTex = SKTexture(imageNamed: "menutext_button")
        menuTex.filteringMode = .nearest
        let menuBtn = SKSpriteNode(texture: menuTex)
        menuBtn.name = NodeName.quitButton.rawValue
        menuBtn.position = CGPoint(x: centerX + buttonSpacingX, y: centerY + buttonYOffset)
        menuBtn.setScale(buttonScale)
        menuBtn.zPosition = 10
        uiContainerNode.addChild(menuBtn)
    }

    private func runSplatAnimation() {
        let frameNames = ["poopie1", "poopie2", "poopie3", "poopie4", "poopie5"]
        let animationFrames = frameNames.map { name -> SKTexture in
            let tex = SKTexture(imageNamed: name)
            tex.filteringMode = .nearest
            return tex
        }

        let animateAction = SKAction.animate(with: animationFrames, timePerFrame: 0.08, resize: false, restore: false)
        let lockFinalTexture = SKAction.run { [weak self] in
            guard let self = self else { return }
            let finalTex = SKTexture(imageNamed: "poopielast")
            finalTex.filteringMode = .nearest
            self.backgroundNode.texture = finalTex
        }
        
        let revealUIElements = SKAction.run { [weak self] in
            self?.uiContainerNode.run(SKAction.fadeIn(withDuration: 0.25))
        }

        backgroundNode.run(SKAction.sequence([animateAction, lockFinalTexture, revealUIElements]))
    }

    // MARK: - Input Handling
    override func mouseDown(with event: NSEvent) {
        let locationInScene = event.location(in: self)
        let clickedNodes = nodes(at: locationInScene)
        
        if clickedNodes.contains(where: { $0.name == NodeName.retryButton.rawValue }) {
            retryGame()
        } else if clickedNodes.contains(where: { $0.name == NodeName.quitButton.rawValue }) {
            quitToMenu()
        }
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 49 {
            retryGame()
        }
    }

    private func retryGame() {
        guard let view = view else { return }
        let scene = GameLoopScene(size: size)
        scene.scaleMode = scaleMode
        view.presentScene(scene, transition: SKTransition.crossFade(withDuration: 0.2))
    }

    private func quitToMenu() {
        guard let view = view else { return }
        AudioManager.shared.stopGameBgm()
        let scene = MenuScene(size: size)
        scene.scaleMode = scaleMode
        view.presentScene(scene, transition: SKTransition.crossFade(withDuration: 0.2))
    }
}
