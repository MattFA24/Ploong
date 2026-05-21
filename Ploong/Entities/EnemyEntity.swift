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
            
            let enemyTier = EnemyAnimation.tier(for: hp)
            let enemySize = enemyTier.size

            let render = RenderComponent(textureName: enemyTier.textureName, size: enemySize, zPosition: 6)
            let enemyFootOffset = abs(position.y - GameConstants.topLaneY) < abs(position.y - GameConstants.bottomLaneY)
                ? GameConstants.topEnemyFootOffset
                : GameConstants.bottomEnemyFootOffset
            let footBaselineY = position.y - enemyFootOffset
            render.node.anchorPoint = CGPoint(x: 0.5, y: 0)
            render.node.position = CGPoint(x: position.x, y: footBaselineY)
            render.node.entity = self
            render.node.texture?.filteringMode = .nearest
            render.node.run(EnemyAnimation.idleAction(for: enemyTier), withKey: "enemyIdleAnimation")
            
            // --- NEW FORMATTING LOGIC ---
            let hpText: String
            if hp >= 1_000 {
                hpText = String(format: "%.1fk", hp / 1_000).replacingOccurrences(of: ".0k", with: "k")
            } else {
                hpText = String(format: "%.0f", hp)
            }
            
            // HP Label
            let hpLbl = SKLabelNode(fontNamed: GameConstants.fontName)
            hpLbl.name = "hpText"
            hpLbl.text = hpText
            hpLbl.fontSize = 13
            hpLbl.fontColor = .white
            hpLbl.zPosition = 1
            hpLbl.position = CGPoint(x: 0, y: enemySize.height + 15)
            render.node.addChild(hpLbl)
            
            // HP Bar
            let barBg = SKSpriteNode(color: .black, size: CGSize(width: 40, height: 6))
            barBg.position = CGPoint(x: 0, y: enemySize.height + 5)
            let bar = SKSpriteNode(color: .green, size: CGSize(width: 38, height: 4))
            bar.name = "hpBar"
            barBg.addChild(bar)
            render.node.addChild(barBg)
            
            // 2. Physics
            let pb = SKPhysicsBody(rectangleOf: enemySize, center: CGPoint(x: 0, y: enemySize.height / 2))
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
