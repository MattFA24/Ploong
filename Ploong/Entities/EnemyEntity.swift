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
        
        // 1. Render (Fixed: using clear color and size so it compiles)
        let render = RenderComponent(color: .clear, size: CGSize(width: 40, height: 40))
        render.node.position = position
        render.node.zPosition = 6
        render.node.entity = self // CRUCIAL: Links the node to this ECS Entity
        
        // Enemy visual (Poop emoji)
        let poop = SKLabelNode(text: "💩")
        poop.fontSize = 36
        poop.verticalAlignmentMode = .center
        render.node.addChild(poop)
        
        // HP Label & Bar
        
        let hpLbl = SKLabelNode(fontNamed: "AvenirNext-Bold")
        hpLbl.name = "hpText"
        hpLbl.text = hp >= 1_000 ? String(format: "%gk", hp / 1_000) : String(format: "%.0f", hp)
        hpLbl.fontSize = 13
        hpLbl.fontColor = .black // <-- Try black or white if darkGray is blending in
        hpLbl.zPosition = 1 // <-- Add this to guarantee it renders on top
        hpLbl.position = CGPoint(x: 0, y: -28)
        render.node.addChild(hpLbl)
        let barBg = SKSpriteNode(color: .black, size: CGSize(width: 40, height: 6))
        barBg.position = CGPoint(x: 0, y: 25)
        let bar = SKSpriteNode(color: .green, size: CGSize(width: 38, height: 4))
        bar.name = "hpBar"
        barBg.addChild(bar)
        render.node.addChild(barBg)
        
        // 2. Physics
        let pb = SKPhysicsBody(circleOfRadius: 20)
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
