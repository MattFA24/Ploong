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

        private let renderSystem = RenderSystem()
        private var entities: [GKEntity] = []
        
        private let movementSystem = MovementSystem()
        private let shootingSystem = ShootingSystem()
        private let spawnerSystem = SpawnerSystem()
        private let collisionManager = CollisionManager()
        
        private var player: PlayerEntity!
        private var lastUpdateTime: TimeInterval = 0

        override func sceneDidLoad() {
            super.sceneDidLoad()
            backgroundColor = .white
            AudioManager.shared.playGameBgm()
            
            physicsWorld.gravity = .zero
            physicsWorld.contactDelegate = collisionManager
            collisionManager.scene = self
            
            collisionManager.onPlayerHitEnemy = { [weak self] in
                            self?.checkAndSaveHighScore() // Save score before pausing/dying
                            self?.stateMachine.enter(PausedState.self)
                        }
            collisionManager.onCoinsChanged = { [weak self] count in
                self?.updateCoinCounter(count)
            }
            
            // 1. Tell the systems what to do when they spawn an entity!
            let spawnHandler: (GKEntity) -> Void = { [weak self] entity in
                guard let self = self else { return }
                self.entities.append(entity) // Retain entity in memory
                self.renderSystem.addEntity(entity)
                if let render = entity.component(ofType: RenderComponent.self) {
                    render.addToScene(self) // Add explicitly to Scene
                }
            }
            
            shootingSystem.onEntitySpawned = spawnHandler
            spawnerSystem.onEntitySpawned = spawnHandler
            
            setupWorld()
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
                
                // Keep the spawner aware of current player power so it scales enemies correctly!
                if let stats = player.component(ofType: StatsComponent.self) {
                    spawnerSystem.currentPlayerPower = stats.power
                }
                spawnerSystem.update(deltaTime: deltaTime, sceneSize: size)
                
                // 2. Clean up destroyed entities to prevent memory leaks!
                entities.removeAll { entity in
                    if let render = entity.component(ofType: RenderComponent.self) {
                        return render.node.parent == nil // Removes if node was destroyed
                    }
                    return false
                }
            }
        }

    private func buildScoreLabel() {
            let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
            label.name = "scoreLabel"
            label.fontSize = 24 // Matched the font size with the coin label
            label.fontColor = .black
            label.horizontalAlignmentMode = .left // Align to the left
            label.verticalAlignmentMode = .center
            
            // Placed in the top left corner
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
            
            // Placed exactly 30 pixels below the Score label
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
        coinCounterLabel?.text = "Coin: \(count)"
    }
    
    private func setupWorld() {
            let background = SpriteEntity(textureName: "game_bg", size: size, position: CGPoint(x: size.width * 0.5, y: size.height * 0.5), zPosition: -10)
            let platformSize = scaledSize(for: "mid_platform", width: size.width)
            let platform = SpriteEntity(textureName: "mid_platform", size: platformSize, position: CGPoint(x: size.width * 0.5, y: size.height * 0.5), zPosition: 5)
            
            let roofSize = scaledSize(for: "tiles_roof", width: size.width)
            let topRoof = SpriteEntity(textureName: "tiles_roof", size: roofSize, position: CGPoint(x: size.width * 0.5, y: size.height - roofSize.height * 0.5), zPosition: 6)
            let bottomRoof = SpriteEntity(textureName: "tiles_roof", size: roofSize, position: CGPoint(x: size.width * 0.5, y: roofSize.height * 0.5), zPosition: 6)

            // --- PIXEL PERFECT MATH CALCULATIONS ---
            let characterHalfHeight = PlayerEntity.Layout.visualHalfHeight
            
            // Fix: Explicitly define the visible height of the bottom tiles (approx 115px)
            // If the character is still slightly floating or sinking, just tweak this number!
            let visibleFloorHeight: CGFloat = 115

            // Bottom Lane Y
            GameConstants.bottomLaneY = visibleFloorHeight + characterHalfHeight
            
            // Top Lane Y
            GameConstants.topLaneY = (size.height / 2) + (platformSize.height / 2) + characterHalfHeight

            // Gate sizing
            let gapHeight = ((size.height / 2) - (platformSize.height / 2)) - visibleFloorHeight
            GameConstants.gateHeight = gapHeight
            GameConstants.gateBottomY = visibleFloorHeight + (gapHeight / 2)
            GameConstants.gateTopY = (size.height / 2) + (platformSize.height / 2) + (gapHeight / 2)
            // ---------------------------------------

            addBaseSensor()

            player = PlayerEntity(position: CGPoint(x: GameConstants.playerX, y: GameConstants.bottomLaneY))
            
            if let stats = player.component(ofType: StatsComponent.self) {
                shootingSystem.addComponent(stats)
            }

            entities = [background, platform, topRoof, bottomRoof, player]
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

    // MARK: - Input Handling
    override func keyDown(with event: NSEvent) {
                if event.keyCode == 49 { // Spacebar
                    handleSpacebar()
                }
                
                // Lane switching logic for Up/Down arrows
                if stateMachine.currentState is PlayingState {
                    if event.keyCode == 126 { // Up Arrow
                        movePlayerToLane(y: GameConstants.topLaneY)
                    }
                    if event.keyCode == 125 { // Down Arrow
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

    // MARK: - State Methods
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

    // MARK: - UI Building
    // MARK: - Updated Property Declarations
    // Make sure to find these variables at the top of your class and update their types to SKSpriteNode:
    // private var pauseModal: SKSpriteNode?
    // private var pauseOverlay: SKNode?

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

        // 1. Pixel Art Pause Modal
        let modalTexture = SKTexture(imageNamed: "pause_modal")
        modalTexture.filteringMode = .nearest
        let modal = SKSpriteNode(texture: modalTexture)
        modal.name = NodeName.pauseModal.rawValue
        modal.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        modal.zPosition = 1
        
        // Maintain a safe scale relative to the screen size
        let modalScale = (size.width * 0.75) / modal.size.width
        modal.setScale(modalScale)
        
        overlay.addChild(modal)
        pauseModal = modal

        // 2. Pixel Art Title Image
        let titleTexture = SKTexture(imageNamed: "paused_text")
        titleTexture.filteringMode = .nearest
        let title = SKSpriteNode(texture: titleTexture)
        title.position = CGPoint(x: 0, y: modal.size.height * 0.28 / modal.yScale)
        title.zPosition = 2
        modal.addChild(title)

        // 3. Layout Adjustments for Buttons
        let buttonY = -modal.size.height * 0.08 / modal.yScale
        let buttonSpacing = (modal.size.width / modal.xScale) * 0.28

        // Left Button: Retry
        addPauseButton(name: .pauseRetry,
                       icon: "restart_logo",
                       title: "",
                       position: CGPoint(x: -buttonSpacing, y: buttonY),
                       in: modal)

        // Center Button: Resume
        addPauseButton(name: .pauseResume,
                       icon: "play_logo",
                       title: "",
                       position: CGPoint(x: 0, y: buttonY),
                       in: modal)

        // Right Button: Quit
        addPauseButton(name: .pauseQuit,
                       icon: "exit_logo",
                       title: "",
                       position: CGPoint(x: buttonSpacing, y: buttonY),
                       in: modal)
    }

    private func addPauseButton(name: NodeName, icon: String, title: String, position: CGPoint, in modal: SKNode) {
        // Button container frame to register input cleanly
        let buttonBase = SKNode()
        buttonBase.name = name.rawValue
        buttonBase.position = position
        buttonBase.zPosition = 2
        
        // 1. Square Background Frame
        let bgTexture = SKTexture(imageNamed: "square_pause_buttons")
        bgTexture.filteringMode = .nearest
        let bgSprite = SKSpriteNode(texture: bgTexture)
        bgSprite.zPosition = 1
        buttonBase.addChild(bgSprite)
        
        // 2. Center Icon Layer
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

    // MARK: - UI Event Handling
    private func handlePauseOverlaySelection(at location: CGPoint) {
        guard pauseOverlay?.isHidden == false else {
            return
        }

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
        guard let view = view else {
            return
        }

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

