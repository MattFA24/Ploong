//
//  PlayerEntity.swift
//  Ploong
//
//  Created by Matthew Fernando Anggrian on 11/05/26.
//  

import SpriteKit
import GameplayKit

final class PlayerEntity: GameEntity {
    init(position: CGPoint) {
        super.init()

        // 1. Setup Render Node
        let render = RenderComponent(color: .init(red: 0.95, green: 0.50, blue: 0.50, alpha: 1), size: CGSize(width: 50, height: 70))
        render.node.position = position
        render.node.zPosition = 10
        
        // 2. Setup Physics Body
        let pb = SKPhysicsBody(rectangleOf: render.node.size)
        pb.isDynamic = true
        pb.categoryBitMask = PhysicsCategory.player
        pb.contactTestBitMask = PhysicsCategory.gate | PhysicsCategory.enemy
        pb.collisionBitMask = 0
        render.node.physicsBody = pb
        
        addComponent(render)

        // 3. Add Game Logic Components
        addComponent(InputComponent(speed: 420))
        addComponent(StatsComponent(initialPower: 10))
        addComponent(PhysicsComponent())
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
