//
//  CoinEntity.swift
//  Ploong
//

import SpriteKit
import GameplayKit

final class CoinEntity: GameEntity {
    init(position: CGPoint, value: Int = 1) {
        super.init()

        let render = RenderComponent(textureName: "coin_1", size: CGSize(width: 40, height: 40), zPosition: 7)
        render.node.position = position
        render.node.name = "coin"
        render.node.entity = self
        render.node.texture?.filteringMode = .nearest
        render.node.shader = CoinAnimation.transparentBlackShader
        render.node.run(CoinAnimation.idleAction(), withKey: "coinIdleAnimation")

        let physicsBody = SKPhysicsBody(circleOfRadius: 18)
        physicsBody.isDynamic = false
        physicsBody.categoryBitMask = PhysicsCategory.coin
        physicsBody.contactTestBitMask = PhysicsCategory.player
        physicsBody.collisionBitMask = PhysicsCategory.none
        render.node.physicsBody = physicsBody

        addComponent(render)
        addComponent(PhysicsComponent())
        addComponent(VelocityComponent(velocity: CGVector(dx: -GameConstants.objectSpeed, dy: 0)))
        addComponent(CoinComponent(value: value))
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
