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
        
        // --- GATE VISUAL TWEAKABLES ---
        let gateWidth: CGFloat = 90.0
        let verticalPadding: CGFloat = 16.0
        // -------------------------------
        
        let adjustedHeight = GameConstants.gateHeight - verticalPadding
        
        // 1. Prepare the custom pixel art texture
        let gateTexture = SKTexture(imageNamed: "main_multi_bg")
        gateTexture.filteringMode = .nearest
        
        // 2. Initialize your RenderComponent with the safe padded size bounds
        let render = RenderComponent(color: .clear, size: CGSize(width: gateWidth, height: adjustedHeight))
        
        // 3. Apply the texture cleanly onto the node canvas frame
        if let spriteNode = render.node as? SKSpriteNode {
            spriteNode.texture = gateTexture
            spriteNode.color = .white
        }
        
        render.node.position = position
        render.node.zPosition = 5
        render.node.name = "gate"
        render.node.entity = self
        
        // 4. Mathematics text layout
        let lbl = SKLabelNode(fontNamed: "AvenirNext-Bold")
        lbl.text = "\(gateData.text)\(Int(gateData.value))"
        lbl.fontSize = 26
        lbl.fontColor = .white
        lbl.verticalAlignmentMode = .center
        
        // FIX: Explicitly force the text layer to sit in front of the gate texture
        lbl.zPosition = 1
        
        render.node.addChild(lbl)
        
        // 5. Physics bounding matches the new wider sprite volume perfectly
        let pb = SKPhysicsBody(rectangleOf: CGSize(width: gateWidth * 0.8, height: adjustedHeight))
        pb.isDynamic = false
        pb.categoryBitMask = PhysicsCategory.gate
        pb.contactTestBitMask = PhysicsCategory.player
        render.node.physicsBody = pb
        
        addComponent(render)
        addComponent(gateData)
    }
    
    required init?(coder: NSCoder) { super.init(coder: coder) }
}
