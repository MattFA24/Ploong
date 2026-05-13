//
//  EnemyEntity.swift
//  Ploong
//
//  Created by Matthew Fernando Anggrian on 12/05/26.
//

import SpriteKit
import GameplayKit

final class EnemyEntity: GameEntity {
    init(position: CGPoint, hp: CGFloat) {
        super.init()
        
        // 1. Render: Brown square
        let render = RenderComponent(color: .brown, size: CGSize(width: 50, height: 70))
        render.node.position = position
        render.node.zPosition = 6
        render.node.entity = self
        
        // HP Label (MOVED TO TOP)
        let hpLbl = SKLabelNode(fontNamed: "AvenirNext-Bold")
        hpLbl.name = "hpText"
        hpLbl.text = hp >= 1_000 ? String(format: "%gk", hp / 1_000) : String(format: "%.0f", hp)
        hpLbl.fontSize = 13
        hpLbl.fontColor = .white
        hpLbl.zPosition = 1
        hpLbl.position = CGPoint(x: 0, y: 55) // Placed above the health bar
        render.node.addChild(hpLbl)
        
        // HP Bar
        let barBg = SKSpriteNode(color: .black, size: CGSize(width: 40, height: 6))
        barBg.position = CGPoint(x: 0, y: 43) // Sits right on top of the square
        
        let bar = SKSpriteNode(color: .green, size: CGSize(width: 38, height: 4))
        bar.name = "hpBar"
        barBg.addChild(bar)
        render.node.addChild(barBg)
        
        // 2. Physics: Rectangle matching the visual size
        let pb = SKPhysicsBody(rectangleOf: render.node.size)
        pb.isDynamic = true
        pb.categoryBitMask = PhysicsCategory.enemy
        pb.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.bullet | PhysicsCategory.base
        pb.collisionBitMask = 0
        render.node.physicsBody = pb
        
        addComponent(render)
        addComponent(PhysicsComponent())
        addComponent(HealthComponent(hp: hp))
    }
    
    required init?(coder: NSCoder) { super.init(coder: coder) }
}
