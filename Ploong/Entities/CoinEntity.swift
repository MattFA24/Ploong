//
//  CoinEntity.swift
//  Ploong
//

import SpriteKit
import GameplayKit

final class CoinEntity: GameEntity {
    init(position: CGPoint, value: Int = 1) {
        super.init()

        let render = RenderComponent(color: .clear, size: CGSize(width: 40, height: 40))
        render.node.position = position
        render.node.zPosition = 7
        render.node.name = "coin"
        render.node.entity = self

        let coinCircle = SKShapeNode(circleOfRadius: 18)
        coinCircle.fillColor = .yellow
        coinCircle.strokeColor = SKColor(red: 0.95, green: 0.62, blue: 0.0, alpha: 1)
        coinCircle.lineWidth = 3
        coinCircle.zPosition = 1
        render.node.addChild(coinCircle)

        let shine = SKShapeNode(circleOfRadius: 5)
        shine.fillColor = SKColor.white.withAlphaComponent(0.65)
        shine.strokeColor = .clear
        shine.position = CGPoint(x: -6, y: 7)
        shine.zPosition = 2
        render.node.addChild(shine)

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
