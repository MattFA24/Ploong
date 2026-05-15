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
        private weak var pauseModal: SKShapeNode?
        private weak var countdownLabel: SKLabelNode?

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
                self?.stateMachine.enter(PausedState.self)
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
    
    private func setupWorld() {
            let background = SpriteEntity(textureName: "game_bg", size: size, position: CGPoint(x: size.width * 0.5, y: size.height * 0.5), zPosition: -10)
            let platformSize = scaledSize(for: "mid_platform", width: size.width)
            let platform = SpriteEntity(textureName: "mid_platform", size: platformSize, position: CGPoint(x: size.width * 0.5, y: size.height * 0.5), zPosition: 5)
            
            let roofSize = scaledSize(for: "tiles_roof", width: size.width)
            let topRoof = SpriteEntity(textureName: "tiles_roof", size: roofSize, position: CGPoint(x: size.width * 0.5, y: size.height - roofSize.height * 0.5), zPosition: 6)
            let bottomRoof = SpriteEntity(textureName: "tiles_roof", size: roofSize, position: CGPoint(x: size.width * 0.5, y: roofSize.height * 0.5), zPosition: 6)

            // --- PIXEL PERFECT MATH CALCULATIONS ---
            let characterHalfHeight: CGFloat = 35
            
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

        let modalSize = CGSize(width: size.width * 0.7, height: size.height * 0.5)
        let modal = SKShapeNode(rectOf: modalSize, cornerRadius: 24)
        modal.name = NodeName.pauseModal.rawValue
        modal.fillColor = NSColor(white: 0.88, alpha: 1)
        modal.strokeColor = .clear
        modal.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        modal.zPosition = 1
        overlay.addChild(modal)
        pauseModal = modal

        let title = SKLabelNode(fontNamed: "AvenirNext-Bold")
        title.text = "PAUSE"
        title.fontSize = 34
        title.fontColor = .black
        title.verticalAlignmentMode = .center
        title.position = CGPoint(x: 0, y: modalSize.height * 0.28)
        modal.addChild(title)

        let buttonY = -modalSize.height * 0.05
        let buttonSpacing = modalSize.width * 0.3

        addPauseButton(name: .pauseQuit,
                       icon: "X",
                       title: "Quit",
                       position: CGPoint(x: -buttonSpacing, y: buttonY),
                       in: modal)

        addPauseButton(name: .pauseResume,
                       icon: ">",
                       title: "Resume",
                       position: CGPoint(x: 0, y: buttonY),
                       in: modal)

        addPauseButton(name: .pauseRetry,
                       icon: "R",
                       title: "Retry",
                       position: CGPoint(x: buttonSpacing, y: buttonY),
                       in: modal)
    }

    private func addPauseButton(name: NodeName,
                                icon: String,
                                title: String,
                                position: CGPoint,
                                in modal: SKNode) {
        let button = SKShapeNode(rectOf: CGSize(width: 140, height: 120), cornerRadius: 16)
        button.name = name.rawValue
        button.fillColor = NSColor(white: 0.95, alpha: 1)
        button.strokeColor = .clear
        button.position = position
        button.zPosition = 2
        modal.addChild(button)

        let iconLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        iconLabel.text = icon
        iconLabel.fontSize = 48
        iconLabel.fontColor = .black
        iconLabel.verticalAlignmentMode = .center
        iconLabel.position = CGPoint(x: 0, y: 18)
        button.addChild(iconLabel)

        let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        titleLabel.text = title
        titleLabel.fontSize = 20
        titleLabel.fontColor = .black
        titleLabel.verticalAlignmentMode = .center
        titleLabel.position = CGPoint(x: 0, y: -34)
        button.addChild(titleLabel)
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
        guard let view = view else {
            return
        }

        AudioManager.shared.stopGameBgm()

        let scene = MenuScene(size: size)
        scene.scaleMode = scaleMode
        view.presentScene(scene)
    }
}
