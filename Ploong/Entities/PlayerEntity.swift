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
        
        // CRUCIAL FIX: Link the node back to this entity so CollisionManager can find StatsComponent
        render.node.entity = self
        
        // 1.5 Setup Power Text Label
        let powerLbl = SKLabelNode(fontNamed: "AvenirNext-Bold")
        powerLbl.name = "powerText"
        powerLbl.text = "10"
        powerLbl.fontSize = 15
        powerLbl.fontColor = .red
        powerLbl.zPosition = 1 // Make sure it sits above the player square
        powerLbl.position = CGPoint(x: 0, y: render.node.size.height / 2 + 10)
        render.node.addChild(powerLbl)
        
        // 2. Setup Physics Body
        let pb = SKPhysicsBody(rectangleOf: render.node.size)
        pb.isDynamic = true
        pb.categoryBitMask = PhysicsCategory.player
        pb.contactTestBitMask = PhysicsCategory.gate | PhysicsCategory.enemy | PhysicsCategory.coin
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
