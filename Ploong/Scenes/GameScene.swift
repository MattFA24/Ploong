//
//  GameScene.swift
//  Ploong
//
//  Created by Matthew Fernando Anggrian on 11/05/26.
//

import SpriteKit
import GameplayKit

final class GameScene: SKScene {
    private var entities: [GKEntity] = []
    private let movementSystem = MovementSystem()
    private var playerInput: InputComponent?
    private var pressedKeys = Set<UInt16>()
    private var lastUpdateTime: TimeInterval = 0

    override func sceneDidLoad() {
        super.sceneDidLoad()
        backgroundColor = .black
        physicsWorld.gravity = .zero

        spawnPlayer()
    }

    private func spawnPlayer() {
        let position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        let player = PlayerEntity(position: position)
        entities.append(player)
        movementSystem.addEntity(player)

        if let render = player.component(ofType: RenderComponent.self) {
            render.addToScene(self)
        }

        playerInput = player.component(ofType: InputComponent.self)
    }

    override func keyDown(with event: NSEvent) {
        if event.isARepeat {
            return
        }

        pressedKeys.insert(event.keyCode)
        updateInputMovement()
    }

    override func keyUp(with event: NSEvent) {
        pressedKeys.remove(event.keyCode)
        updateInputMovement()
    }

    private func updateInputMovement() {
        var dx: CGFloat = 0
        var dy: CGFloat = 0

        if pressedKeys.contains(123) || pressedKeys.contains(0) {
            dx -= 1
        }

        if pressedKeys.contains(124) || pressedKeys.contains(2) {
            dx += 1
        }

        if pressedKeys.contains(126) || pressedKeys.contains(13) {
            dy += 1
        }

        if pressedKeys.contains(125) || pressedKeys.contains(1) {
            dy -= 1
        }

        let length = sqrt(dx * dx + dy * dy)
        let movement: CGVector

        if length > 0 {
            movement = CGVector(dx: dx / length, dy: dy / length)
        } else {
            movement = .zero
        }

        playerInput?.movement = movement
    }

    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }

        let dt = currentTime - lastUpdateTime
        movementSystem.update(deltaTime: dt)
        lastUpdateTime = currentTime
    }
}
