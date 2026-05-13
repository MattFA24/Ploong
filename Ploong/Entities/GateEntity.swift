//
//  GateEntity.swift
//  Ploong
//
//  Created by Matthew Fernando Anggrian on 12/05/26.
//

import SpriteKit
import GameplayKit

final class GateEntity: GameEntity {
    init(position: CGPoint, gateData: GateComponent) {
        super.init()
        
        let w: CGFloat = 60
        // Update the height to use our new Gate height constant
        let render = RenderComponent(color: SKColor.gray.withAlphaComponent(0.3), size: CGSize(width: w, height: GameConstants.gateHeight))
        render.node.position = position
        render.node.zPosition = 5
        render.node.name = "gate"
        
        render.node.entity = self
        
        let lbl = SKLabelNode(fontNamed: "AvenirNext-Bold")
        lbl.text = "\(gateData.text)\(Int(gateData.value))"
        lbl.fontSize = 26
        lbl.fontColor = (gateData.type == .multiply || gateData.type == .add) ? SKColor(red: 0.0, green: 0.45, blue: 0.1, alpha: 1) : SKColor(red: 0.7, green: 0.1, blue: 0.1, alpha: 1)
        lbl.verticalAlignmentMode = .center
        render.node.addChild(lbl)
        
        // Update physics body height
        let pb = SKPhysicsBody(rectangleOf: CGSize(width: w * 0.8, height: GameConstants.gateHeight))
        pb.isDynamic = false
        pb.categoryBitMask = PhysicsCategory.gate
        pb.contactTestBitMask = PhysicsCategory.player
        render.node.physicsBody = pb
        
        addComponent(render)
        addComponent(gateData)
    }
    
    required init?(coder: NSCoder) { super.init(coder: coder) }
}
