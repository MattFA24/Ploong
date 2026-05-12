//
//  BulletEntity.swift
//  Ploong
//
//  Created by Matthew Fernando Anggrian on 12/05/26.
//

import SpriteKit
import GameplayKit

final class BulletEntity: GameEntity {
    init(position: CGPoint, damage: CGFloat) {
        super.init()
        
        // 1. Render (Fixed: using color and size)
        let render = RenderComponent(color: .init(red: 0.6, green: 0.3, blue: 0.0, alpha: 1), size: CGSize(width: 14, height: 14))
        render.node.position = position
        render.node.zPosition = 8
        render.node.entity = self // CRUCIAL: Links the node to this ECS Entity
        
        // 2. Physics
        let pb = SKPhysicsBody(circleOfRadius: 7)
        pb.isDynamic = true
        pb.categoryBitMask = PhysicsCategory.bullet
        pb.contactTestBitMask = PhysicsCategory.enemy
        pb.collisionBitMask = 0
        render.node.physicsBody = pb
        
        addComponent(render)
        addComponent(PhysicsComponent())
        addComponent(DamageComponent(amount: damage)) // Inject damage data
    }
    
    required init?(coder: NSCoder) { super.init(coder: coder) }
}
