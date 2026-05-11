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

    override func sceneDidLoad() {
        super.sceneDidLoad()
        backgroundColor = .white
        AudioManager.shared.playGameBgm()
        setupWorld()
        buildPauseOverlay()
        stateMachine.enter(PlayingState.self)
    }

    private func setupWorld() {
        let background = SpriteEntity(
            textureName: "game_bg",
            size: size,
            position: CGPoint(x: size.width * 0.5, y: size.height * 0.5),
            zPosition: -10
        )

        let platformSize = scaledSize(for: "mid_platform", width: size.width)
        let platform = SpriteEntity(
            textureName: "mid_platform",
            size: platformSize,
            position: CGPoint(x: size.width * 0.5, y: size.height * 0.5),
            zPosition: 5
        )

        let roofSize = scaledSize(for: "tiles_roof", width: size.width)
        let topRoof = SpriteEntity(
            textureName: "tiles_roof",
            size: roofSize,
            position: CGPoint(x: size.width * 0.5, y: size.height - roofSize.height * 0.5),
            zPosition: 6
        )

        let bottomRoof = SpriteEntity(
            textureName: "tiles_roof",
            size: roofSize,
            position: CGPoint(x: size.width * 0.5, y: roofSize.height * 0.5),
            zPosition: 6
        )

        entities = [background, platform, topRoof, bottomRoof]
        for entity in entities {
            renderSystem.addEntity(entity)
        }
        renderSystem.addToScene(self)
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

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 49 {
            handleSpacebar()
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
