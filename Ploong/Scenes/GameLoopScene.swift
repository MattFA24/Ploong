//
//  GameLoopScene.swift
//  Ploong
//
//  Created by Matthew Fernando Anggrian on 11/05/26.
//

import SpriteKit
import GameplayKit

final class GameLoopScene: SKScene {
    private enum NodeName: String {
        case pauseOverlay
        case pauseDimmer
        case pauseModal
        case pauseResume
        case pauseRetry
        case pauseQuit
        case countdownLabel
    }

    private lazy var stateMachine = GKStateMachine(states: [
        PlayingState(scene: self),
        PausedState(scene: self),
        CountdownState(scene: self)
    ])

    private weak var pauseOverlay: SKNode?
    private weak var pauseModal: SKSpriteNode?
    private weak var countdownLabel: SKLabelNode?
    
    private weak var coinCounterLabel: SKLabelNode?
    private weak var scoreLabel: SKLabelNode?
    private var sessionTime: TimeInterval = 0
    private var currentScore: Int = 0

    private weak var pauseOverlay: SKNode?
    private weak var pauseModal: SKSpriteNode?
    private weak var countdownLabel: SKLabelNode?
    
    // Split into distinct title/value labels for pixel-perfect vertical alignment
    private weak var scoreValueLabel: SKLabelNode?
    private weak var coinValueLabel: SKLabelNode?
    
    private var sessionTime: TimeInterval = 0
    private var currentScore: Int = 0

    private let renderSystem = RenderSystem()
    private var entities: [GKEntity] = []
    
    private let movementSystem = MovementSystem()
    private let shootingSystem = ShootingSystem()
    private let spawnerSystem = SpawnerSystem()
    private let collisionManager = CollisionManager()
    private var safeZoneSystem: SafeZoneSystem! // ADDED
    
    private var player: PlayerEntity!
    private var lastUpdateTime: TimeInterval = 0

    override func sceneDidLoad() {
        super.sceneDidLoad()
        backgroundColor = .white
        AudioManager.shared.playGameBgm()
        
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = collisionManager
        collisionManager.scene = self
        
        // Setup Safe Zone System
        safeZoneSystem = SafeZoneSystem(safeZoneX: 50, stateMachine: stateMachine, scene: self)
        safeZoneSystem.onSafeZoneBreached = { [weak self] in
            self?.transitionToGameOver()
        }
        
        // Transition to GameOverScene on hit
        collisionManager.onPlayerHitEnemy = { [weak self] in
            self?.transitionToGameOver()
        }
        
        collisionManager.onCoinsChanged = { [weak self] count in
            self?.updateCoinCounter(count)
        }
        
        // Tell the systems what to do when they spawn an entity
        let spawnHandler: (GKEntity) -> Void = { [weak self] entity in
            guard let self = self else { return }
            self.entities.append(entity)
            self.renderSystem.addEntity(entity)
            
            // Register entity with appropriate systems
            if let render = entity.component(ofType: RenderComponent.self) {
                render.addToScene(self)
                self.safeZoneSystem.addComponent(render)
            }
        }
        
        shootingSystem.onEntitySpawned = spawnHandler
        spawnerSystem.onEntitySpawned = spawnHandler
        
        setupWorld()
        buildGameHUD()
        buildCoinCounterLabel()
        buildScoreLabel()
        buildPauseOverlay()
        stateMachine.enter(PlayingState.self)
    }

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        setupGestureControl()
    }

    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime == 0 { lastUpdateTime = currentTime }
        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        if stateMachine.currentState is PlayingState {
            sessionTime += deltaTime
            let newScore = Int(sessionTime * 10)
            if newScore != currentScore {
                currentScore = newScore
                updateScoreDisplay(currentScore)
            }
            
            movementSystem.update(deltaTime: deltaTime)
            shootingSystem.update(deltaTime: deltaTime)
            
            if let stats = player.component(ofType: StatsComponent.self) {
                spawnerSystem.currentPlayerPower = stats.power
            }
            spawnerSystem.update(deltaTime: deltaTime, sceneSize: size)
            
            let _ = entities.removeAll { entity in
                if let render = entity.component(ofType: RenderComponent.self) {
                    return render.node.parent == nil
                }
                return false
            }
        }
    }

    // MARK: - Pixel Art HUD Builder
    private func buildGameHUD() {
        // --- HUD LAYOUT TWEAKABLES: Adjust grid alignment right here ---
        let scoreBoxScale: CGFloat = 0.70
        let scoreBoxPosition = CGPoint(x: 150, y: size.height - 70)
        
        let hudFontSize: CGFloat = 16.0
        let titleColumnX: CGFloat = scoreBoxPosition.x - 75  // Safe left edge for labels
        let valueColumnX: CGFloat = scoreBoxPosition.x + 75  // Safe right edge for numbers
        
        let rowScoreY: CGFloat = scoreBoxPosition.y + 10     // Top row height
        let rowCoinY: CGFloat = scoreBoxPosition.y - 12      // Bottom row height
        
        let pauseHintScale: CGFloat = 0.85
        let pauseHintPosition = CGPoint(x: size.width - 170, y: size.height - 60)
        // -------------------------------------------------------------
        
        // 1. Top Left Highscore Frame
        let scoreBgTex = SKTexture(imageNamed: "main_score_bg")
        scoreBgTex.filteringMode = .nearest
        let scoreBg = SKSpriteNode(texture: scoreBgTex)
        scoreBg.position = scoreBoxPosition
        scoreBg.setScale(scoreBoxScale)
        scoreBg.zPosition = 85
        addChild(scoreBg)
        
        // --- ROW 1: SCORE ---
        let scoreTitle = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreTitle.text = "score"
        scoreTitle.fontSize = hudFontSize
        scoreTitle.fontColor = .black
        scoreTitle.horizontalAlignmentMode = .left
        scoreTitle.verticalAlignmentMode = .center
        scoreTitle.position = CGPoint(x: titleColumnX, y: rowScoreY)
        scoreTitle.zPosition = 90
        addChild(scoreTitle)
        
        let scoreVal = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreVal.fontSize = hudFontSize
        scoreVal.fontColor = .black
        scoreVal.horizontalAlignmentMode = .right  // Right-aligned to lock placement
        scoreVal.verticalAlignmentMode = .center
        scoreVal.position = CGPoint(x: valueColumnX, y: rowScoreY)
        scoreVal.zPosition = 90
        addChild(scoreVal)
        self.scoreValueLabel = scoreVal
        
        // --- ROW 2: COIN ---
        let coinTitle = SKLabelNode(fontNamed: "AvenirNext-Bold")
        coinTitle.text = "coin"
        coinTitle.fontSize = hudFontSize
        coinTitle.fontColor = .black
        coinTitle.horizontalAlignmentMode = .left   // Perfectly flush underneath "score"
        coinTitle.verticalAlignmentMode = .center
        coinTitle.position = CGPoint(x: titleColumnX, y: rowCoinY)
        coinTitle.zPosition = 90
        addChild(coinTitle)
        
        let coinVal = SKLabelNode(fontNamed: "AvenirNext-Bold")
        coinVal.fontSize = hudFontSize
        coinVal.fontColor = .black
        coinVal.horizontalAlignmentMode = .right   // Perfectly flush underneath the score digits
        coinVal.verticalAlignmentMode = .center
        coinVal.position = CGPoint(x: valueColumnX, y: rowCoinY)
        coinVal.zPosition = 90
        addChild(coinVal)
        self.coinValueLabel = coinVal
        
        // Update values explicitly
        updateScoreDisplay(0)
        updateCoinCounter(player.component(ofType: StatsComponent.self)?.coinsCollected ?? 0)

        // 2. Top Right Pause Hint Frame Layout
        let hintBgTex = SKTexture(imageNamed: "pause_hint_bg")
        hintBgTex.filteringMode = .nearest
        let hintBg = SKSpriteNode(texture: hintBgTex)
        hintBg.position = pauseHintPosition
        hintBg.setScale(pauseHintScale)
        hintBg.zPosition = 85
        addChild(hintBg)
        
        let hintTextTex = SKTexture(imageNamed: "pause_hint_text")
        hintTextTex.filteringMode = .nearest
        let hintTextSprite = SKSpriteNode(texture: hintTextTex)
        hintTextSprite.position = pauseHintPosition
        hintTextSprite.setScale(pauseHintScale)
        hintTextSprite.zPosition = 90
        addChild(hintTextSprite)
    }

    private func updateScoreDisplay(_ score: Int) {
        scoreValueLabel?.text = "\(score)"
            }
            
            movementSystem.update(deltaTime: deltaTime)
            shootingSystem.update(deltaTime: deltaTime)
            safeZoneSystem.update(deltaTime: deltaTime) // ADDED
            
            if let stats = player.component(ofType: StatsComponent.self) {
                spawnerSystem.currentPlayerPower = stats.power
            }
            spawnerSystem.update(deltaTime: deltaTime, sceneSize: size)
            
            entities.removeAll { entity in
                if let render = entity.component(ofType: RenderComponent.self) {
                    if render.node.parent == nil {
                        self.safeZoneSystem.removeComponent(render)
                        return true
                    }
                    return false
                }
                return false
            }
        }
    }

    // MARK: - Game Over Transition
    private func transitionToGameOver() {
        physicsWorld.speed = 0 // Freeze the game world
        checkAndSaveHighScore() // Save score before transitioning
        
        guard let view = self.view else { return }
        
        #if canImport(AppKit) && canImport(AVFoundation) && canImport(Vision)
        HandGestureManager.shared.resetGestureChangeTracking()
        #endif
        
        // Present the new GameOverScene
        let gameOverScene = GameOverScene(size: self.size, score: self.currentScore)
        gameOverScene.scaleMode = self.scaleMode
        view.presentScene(gameOverScene, transition: SKTransition.crossFade(withDuration: 0.5))
    }

    // MARK: - Labels & Saving
    private func buildScoreLabel() {
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.name = "scoreLabel"
        label.fontSize = 24
        label.fontColor = .black
        label.horizontalAlignmentMode = .left
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: 24, y: size.height - 28)
        label.zPosition = 90
        addChild(label)
        scoreLabel = label
        
        updateScoreDisplay(0)
    }

    private func updateScoreDisplay(_ score: Int) {
        scoreLabel?.text = "Score: \(score)"
    }

    private func buildCoinCounterLabel() {
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.name = "coinCounterLabel"
        label.fontSize = 24
        label.fontColor = .black
        label.horizontalAlignmentMode = .left
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: 24, y: size.height - 58)
        label.zPosition = 90
        addChild(label)
        coinCounterLabel = label
        
        updateCoinCounter(player.component(ofType: StatsComponent.self)?.coinsCollected ?? 0)
    }
    
    private func checkAndSaveHighScore() {
        let currentHighScore = UserDefaults.standard.integer(forKey: "HighScore")
        if currentScore > currentHighScore {
            UserDefaults.standard.set(currentScore, forKey: "HighScore")
        }
    }

    private func updateCoinCounter(_ count: Int) {
        coinValueLabel?.text = "\(count)"
    }
    
    // MARK: - World Setup
    private func setupWorld() {
        let background = SpriteEntity(textureName: "game_bg", size: size, position: CGPoint(x: size.width * 0.5, y: size.height * 0.5), zPosition: -10)
        let platformSize = scaledSize(for: "mid_platform", width: size.width)
        let platform = SpriteEntity(textureName: "mid_platform", size: platformSize, position: CGPoint(x: size.width * 0.5, y: size.height * 0.5), zPosition: 5)
        
        let roofSize = scaledSize(for: "tiles_main", width: size.width)
        let topRoof = SpriteEntity(textureName: "tiles_main", size: roofSize, position: CGPoint(x: size.width * 0.5, y: size.height - roofSize.height * 0.5), zPosition: 6)
        let bottomRoof = SpriteEntity(textureName: "tiles_main", size: roofSize, position: CGPoint(x: size.width * 0.5, y: roofSize.height * 0.5), zPosition: 6)

        let characterHalfHeight = PlayerEntity.Layout.visualHalfHeight
        let visibleFloorHeight: CGFloat = 115

        GameConstants.bottomLaneY = visibleFloorHeight + characterHalfHeight
        GameConstants.topLaneY = (size.height / 2) + (platformSize.height / 2) + characterHalfHeight

        let gapHeight = ((size.height / 2) - (platformSize.height / 2)) - visibleFloorHeight
        GameConstants.gateHeight = gapHeight
        GameConstants.gateBottomY = visibleFloorHeight + (gapHeight / 2)
        GameConstants.gateTopY = (size.height / 2) + (platformSize.height / 2) + (gapHeight / 2)

        addBaseSensor()

        player = PlayerEntity(position: CGPoint(x: GameConstants.playerX, y: GameConstants.bottomLaneY))
        
        if let stats = player.component(ofType: StatsComponent.self) {
            shootingSystem.addComponent(stats)
        }

        entities = [background, platform, bottomRoof, player]
        for entity in entities {
            renderSystem.addEntity(entity)
        }
        renderSystem.addToScene(self)
    }
    
    private func addBaseSensor() {
        let enemyHeight: CGFloat = 70
        let laneSpan = abs(GameConstants.topLaneY - GameConstants.bottomLaneY) + enemyHeight
        let baseNode = SKNode()
        baseNode.name = "base"
        baseNode.position = CGPoint(
            x: GameConstants.playerX,
            y: (GameConstants.topLaneY + GameConstants.bottomLaneY) * 0.5
        )

        let body = SKPhysicsBody(rectangleOf: CGSize(width: 24, height: laneSpan))
        body.isDynamic = false
        body.categoryBitMask = PhysicsCategory.base
        body.contactTestBitMask = PhysicsCategory.enemy
        body.collisionBitMask = 0
        baseNode.physicsBody = body
        addChild(baseNode)
    }
    
    private func setupGestureControl() {
        #if canImport(AppKit) && canImport(AVFoundation) && canImport(Vision)
        HandGestureManager.shared.startDetection()
        HandGestureManager.shared.resetGestureChangeTracking()
        let applyGesture: (HandGesture) -> Void = { [weak self] gesture in
            guard let self, self.stateMachine.currentState is PlayingState else {
                return
            }

            switch gesture {
            case .fist:
                self.movePlayerToLane(y: GameConstants.bottomLaneY)
            case .point:
                self.movePlayerToLane(y: GameConstants.topLaneY)
            case .unrecognized, .unknown:
                break
            }
        }

        HandGestureManager.shared.onGestureChanged = applyGesture
        applyGesture(HandGestureManager.shared.currentGesture)
        #endif
    }

    private func movePlayerToLane(y laneY: CGFloat) {
        guard let renderNode = player.component(ofType: RenderComponent.self)?.node else {
            return
        }

        renderNode.removeAction(forKey: "laneSwitch")
        renderNode.run(.moveTo(y: laneY, duration: 0.15), withKey: "laneSwitch")
    }

    private func scaledSize(for textureName: String, width: CGFloat) -> CGSize {
        let texture = SKTexture(imageNamed: textureName)
        let textureSize = texture.size()
        guard textureSize.width > 0, textureSize.height > 0 else {
            return CGSize(width: width, height: 1)
        }

        let scale = width / textureSize.width
        return CGSize(width: width, height: textureSize.height * scale)
    }

    override func keyUp(with event: NSEvent) {}

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 49 {
            handleSpacebar()
        }
        
        if stateMachine.currentState is PlayingState {
            if event.keyCode == 126 {
                movePlayerToLane(y: GameConstants.topLaneY)
            }
            if event.keyCode == 125 {
                movePlayerToLane(y: GameConstants.bottomLaneY)
            }
        }
    }

    override func mouseDown(with event: NSEvent) {
        let location = event.location(in: self)
        handlePauseOverlaySelection(at: location)
    }

    private func handleSpacebar() {
        if stateMachine.currentState is PlayingState {
            stateMachine.enter(PausedState.self)
        } else if stateMachine.currentState is PausedState {
            stateMachine.enter(CountdownState.self)
        }
    }

    func enterPlaying() {
        physicsWorld.speed = 1
        hidePauseOverlay()
    }

    func enterPaused() {
        physicsWorld.speed = 0
        showPauseOverlay(showModal: true)
    }

    func enterCountdown() {
        physicsWorld.speed = 0
        startCountdown()
    }

    // MARK: - Pause UI
    private func buildPauseOverlay() {
        let overlay = SKNode()
        overlay.name = NodeName.pauseOverlay.rawValue
        overlay.zPosition = 100
        overlay.isHidden = true
        addChild(overlay)
        pauseOverlay = overlay

        let dimmer = SKShapeNode(rectOf: size)
        dimmer.name = NodeName.pauseDimmer.rawValue
        dimmer.fillColor = NSColor(white: 0, alpha: 0.35)
        dimmer.strokeColor = .clear
        dimmer.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        overlay.addChild(dimmer)

        let modalTexture = SKTexture(imageNamed: "pause_modal")
        modalTexture.filteringMode = .nearest
        let modal = SKSpriteNode(texture: modalTexture)
        modal.name = NodeName.pauseModal.rawValue
        modal.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        modal.zPosition = 1
        
        let modalScale = (size.width * 0.75) / modal.size.width
        modal.setScale(modalScale)
        
        overlay.addChild(modal)
        pauseModal = modal

        let titleTexture = SKTexture(imageNamed: "paused_text")
        titleTexture.filteringMode = .nearest
        let title = SKSpriteNode(texture: titleTexture)
        title.position = CGPoint(x: 0, y: modal.size.height * 0.28 / modal.yScale)
        title.zPosition = 2
        modal.addChild(title)

        let buttonY = -modal.size.height * 0.08 / modal.yScale
        let buttonSpacing = (modal.size.width / modal.xScale) * 0.28

        addPauseButton(name: .pauseRetry,
                       icon: "restart_logo",
                       title: "",
                       position: CGPoint(x: -buttonSpacing, y: buttonY),
                       in: modal)

        addPauseButton(name: .pauseResume,
                       icon: "play_logo",
                       title: "",
                       position: CGPoint(x: 0, y: buttonY),
                       in: modal)

        addPauseButton(name: .pauseQuit,
                       icon: "exit_logo",
                       title: "",
                       position: CGPoint(x: buttonSpacing, y: buttonY),
                       in: modal)
    }

    private func addPauseButton(name: NodeName, icon: String, title: String, position: CGPoint, in modal: SKNode) {
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

    private func showPauseOverlay(showModal: Bool) {
        pauseOverlay?.isHidden = false
        pauseModal?.isHidden = !showModal
        countdownLabel?.isHidden = true
    }

    private func hidePauseOverlay() {
        pauseOverlay?.isHidden = true
    }

    private func startCountdown() {
        showPauseOverlay(showModal: false)

        let label: SKLabelNode
        if let existing = countdownLabel {
            label = existing
        } else {
            let newLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
            newLabel.name = NodeName.countdownLabel.rawValue
            newLabel.fontSize = 64
            newLabel.fontColor = .black
            newLabel.verticalAlignmentMode = .center
            newLabel.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
            pauseOverlay?.addChild(newLabel)
            countdownLabel = newLabel
            label = newLabel
        }

        label.isHidden = false
        label.removeAllActions()

        let sequence = SKAction.sequence([
            SKAction.run { label.text = "3" },
            SKAction.wait(forDuration: 0.6),
            SKAction.run { label.text = "2" },
            SKAction.wait(forDuration: 0.6),
            SKAction.run { label.text = "1" },
            SKAction.wait(forDuration: 0.6),
            SKAction.run { label.text = "GO" },
            SKAction.wait(forDuration: 0.4),
            SKAction.run { [weak self] in
                label.isHidden = true
                self?.stateMachine.enter(PlayingState.self)
            }
        ])

        label.run(sequence)
    }

    private func handlePauseOverlaySelection(at location: CGPoint) {
        guard pauseOverlay?.isHidden == false else { return }

        let nodesAtPoint = nodes(at: location)
        
        if containsNode(named: .pauseResume, in: nodesAtPoint) {
            stateMachine.enter(CountdownState.self)
            return
        }

        if containsNode(named: .pauseRetry, in: nodesAtPoint) {
            retryGame()
            return
        }

        if containsNode(named: .pauseQuit, in: nodesAtPoint) {
            quitToMenu()
        }
    }

    private func containsNode(named name: NodeName, in nodes: [SKNode]) -> Bool {
        nodes.contains { node in
            node.name == name.rawValue || node.parent?.name == name.rawValue
        }
    }

    private func retryGame() {
        checkAndSaveHighScore()
        guard let view = view else { return }

        #if canImport(AppKit) && canImport(AVFoundation) && canImport(Vision)
        HandGestureManager.shared.resetGestureChangeTracking()
        #endif

        let scene = GameLoopScene(size: size)
        scene.scaleMode = scaleMode
        view.presentScene(scene)
    }

    private func quitToMenu() {
        checkAndSaveHighScore()
        guard let view = view else {
            return
        }

        AudioManager.shared.stopGameBgm()

        let scene = MenuScene(size: size)
        scene.scaleMode = scaleMode
        view.presentScene(scene)
    }
}
