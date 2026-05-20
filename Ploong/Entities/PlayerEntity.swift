//
//  PlayerEntity.swift
//  Ploong
//
//  Created by Matthew Fernando Anggrian on 11/05/26.
//

import SpriteKit
import GameplayKit

final class PlayerEntity: GameEntity {
    enum Layout {
        static let hitboxSize = CGSize(width: 50, height: 70)
        static let sourceTextureSize = CGSize(width: 288, height: 225)
        static let visualHeight: CGFloat = 160
        static let visualSize = CGSize(
            width: sourceTextureSize.width * (visualHeight / sourceTextureSize.height),
            height: visualHeight
        )
        static let visualHalfHeight = visualSize.height * 0.5
        
        static let hitboxCenter = CGPoint(
            x: 0,
            y: ((-visualSize.height + hitboxSize.height) * 0.5) + 40
        )
        
        static let bulletSpawnOffset = CGPoint(
            x: visualSize.width * 0.3,
            y: -visualSize.height * 0.01 + 5
        )
    }
    init(position: CGPoint) {
        super.init()
        
        // 1. Setup Render Node
        let render = RenderComponent(textureName: "joy_1", size: Layout.visualSize)
        render.node.position = position
        render.node.zPosition = 10
        render.node.texture?.filteringMode = .nearest
        render.node.run(JoyAnimation.idleAction(), withKey: "joyIdleAnimation")
        render.node.entity = self

        addPowerLabel(to: render.node)
        
        // 2. Setup Physics Body
        let pb = SKPhysicsBody(rectangleOf: Layout.hitboxSize, center: Layout.hitboxCenter)
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

    private func addPowerLabel(to node: SKNode) {
        let powerLbl = SKLabelNode(fontNamed: "AvenirNext-Bold")
        powerLbl.name = "powerText"
        powerLbl.text = "10"
        powerLbl.fontSize = 18
        powerLbl.fontColor = .red
        powerLbl.zPosition = 2
        powerLbl.position = CGPoint(x: +Layout.visualSize.width * 0.3, y: Layout.visualHalfHeight + 15)
        node.addChild(powerLbl)
    }
}
