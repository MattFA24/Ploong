//
//  GameOverScene.swift
//  Ploong
//

import SpriteKit

final class GameOverScene: SKScene {
    private enum NodeName: String {
        case retryButton
        case quitButton
    }

    private let finalScore: Int

    // Custom initializer to pass the score from the GameLoopScene
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
    }

    private func buildUI() {
        // 1. Background (Reuse the game background to make it look continuous)
        let background = SKSpriteNode(imageNamed: "game_bg")
        background.size = size
        background.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        background.zPosition = -10
        addChild(background)

        // 2. Dimmer overlay
        let dimmer = SKShapeNode(rectOf: size)
        dimmer.fillColor = NSColor(white: 0, alpha: 0.5)
        dimmer.strokeColor = .clear
        dimmer.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        addChild(dimmer)

        // 3. Modal Background
        let modalTexture = SKTexture(imageNamed: "pause_modal")
        modalTexture.filteringMode = .nearest
        let modal = SKSpriteNode(texture: modalTexture)
        modal.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        modal.zPosition = 1
        
        let modalScale = (size.width * 0.75) / modal.size.width
        modal.setScale(modalScale)
        addChild(modal)

        // 4. Game Over Title
        let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        titleLabel.text = "GAME OVER"
        titleLabel.fontSize = 40
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: 0, y: modal.size.height * 0.20 / modal.yScale)
        titleLabel.zPosition = 2
        modal.addChild(titleLabel)

        // 5. Current Score
        let scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreLabel.text = "Score: \(finalScore)"
        scoreLabel.fontSize = 28
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: 0, y: modal.size.height * 0.05 / modal.yScale)
        scoreLabel.zPosition = 2
        modal.addChild(scoreLabel)

        // 6. High Score
        let highScore = UserDefaults.standard.integer(forKey: "HighScore")
        let highScoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        highScoreLabel.text = "High Score: \(highScore)"
        highScoreLabel.fontSize = 20
        highScoreLabel.fontColor = .yellow
        highScoreLabel.position = CGPoint(x: 0, y: -modal.size.height * 0.05 / modal.yScale)
        highScoreLabel.zPosition = 2
        modal.addChild(highScoreLabel)

        // 7. Buttons (Retry & Quit)
        let buttonY = -modal.size.height * 0.22 / modal.yScale
        let buttonSpacing = (modal.size.width / modal.xScale) * 0.18

        addButton(name: .retryButton,
                  icon: "restart_logo",
                  position: CGPoint(x: -buttonSpacing, y: buttonY),
                  in: modal)

        addButton(name: .quitButton,
                  icon: "exit_logo",
                  position: CGPoint(x: buttonSpacing, y: buttonY),
                  in: modal)
    }

    private func addButton(name: NodeName, icon: String, position: CGPoint, in modal: SKNode) {
        let buttonBase = SKNode()
        buttonBase.name = name.rawValue
        buttonBase.position = position
        buttonBase.zPosition = 2
        
        let bgTexture = SKTexture(imageNamed: "square_pause_buttons")
        bgTexture.filteringMode = .nearest
        let bgSprite = SKSpriteNode(texture: bgTexture)
        bgSprite.zPosition = 1
        buttonBase.addChild(bgSprite)
        
        let iconTexture = SKTexture(imageNamed: icon)
        iconTexture.filteringMode = .nearest
        let iconSprite = SKSpriteNode(texture: iconTexture)
        iconSprite.zPosition = 2
        buttonBase.addChild(iconSprite)
        
        modal.addChild(buttonBase)
    }

    // MARK: - Input Handling
    override func mouseDown(with event: NSEvent) {
        let location = event.location(in: self)
        let nodesAtPoint = nodes(at: location)
        
        if containsNode(named: .retryButton, in: nodesAtPoint) {
            retryGame()
        } else if containsNode(named: .quitButton, in: nodesAtPoint) {
            quitToMenu()
        }
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 49 { // Spacebar for quick restart
            retryGame()
        }
    }

    private func containsNode(named name: NodeName, in nodes: [SKNode]) -> Bool {
        nodes.contains { node in
            node.name == name.rawValue || node.parent?.name == name.rawValue
        }
    }

    // MARK: - Navigation
    private func retryGame() {
        guard let view = view else { return }
        let scene = GameLoopScene(size: size)
        scene.scaleMode = scaleMode
        view.presentScene(scene, transition: SKTransition.crossFade(withDuration: 0.3))
    }

    private func quitToMenu() {
        guard let view = view else { return }
        AudioManager.shared.stopGameBgm() // Ensure BGM stops if they go back to menu
        let scene = MenuScene(size: size)
        scene.scaleMode = scaleMode
        view.presentScene(scene, transition: SKTransition.crossFade(withDuration: 0.3))
    }
}
