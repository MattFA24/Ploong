//
//  SafeZoneSystem.swift
//  Ploong
//
//  Created by Matthew Fernando Anggrian on 12/05/26.
//

import GameplayKit
import SpriteKit

// This system tracks entities (like the Poop enemy) to check if they cross the safe zone line.
class SafeZoneSystem: GKComponentSystem<RenderComponent> {
    weak var stateMachine: GKStateMachine?
    weak var scene: SKScene?
    var safeZoneX: CGFloat
    
    // Add a callback closure to notify the scene when the game is over
    var onSafeZoneBreached: (() -> Void)?
    
    init(safeZoneX: CGFloat, stateMachine: GKStateMachine?, scene: SKScene?) {
        self.safeZoneX = safeZoneX
        self.stateMachine = stateMachine
        self.scene = scene
        super.init(componentClass: RenderComponent.self)
        
        drawSafeZoneIndicator()
    }
    
    // Draws the pixel art vertical area on the far left side
    private func drawSafeZoneIndicator() {
        guard let scene = scene else { return }
        
        // --- SAFE ZONE VISUAL TWEAKABLES ---
        let zoneWidth: CGFloat = 88.0                       // Change width of the visual bar
        let zoneHeight: CGFloat = scene.size.height + 40      // Change height (default uses full screen height)
        let customXPosition: CGFloat = 40                // Adjust horizontal positioning relative to the left edge
        let customYPosition: CGFloat = 0.0 + 1                // Adjust vertical positioning relative to the bottom edge
        // ------------------------------------
        
        // 1. Prepare your custom safe area pixel art background asset
        let safeZoneTexture = SKTexture(imageNamed: "safe_zone_dark")
        safeZoneTexture.filteringMode = .nearest // Enforces crisp pixel art scaling
        
        // 2. Initialize the sprite node using your new tweakable width and height properties
        let safeZoneNode = SKSpriteNode(texture: safeZoneTexture, size: CGSize(width: zoneWidth, height: zoneHeight))
        
        // 3. Setup bottom-left anchoring to draw cleanly from your custom offsets
        safeZoneNode.anchorPoint = CGPoint(x: 0, y: 0)
        safeZoneNode.position = CGPoint(x: customXPosition, y: customYPosition)
        
        // 4. Set depth value behind character lanes, platforms, and bubbles
        safeZoneNode.zPosition = -8
        safeZoneNode.name = "SafeZoneIndicator"
        
        scene.addChild(safeZoneNode)
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)
        
        // Only check for breaches if the game is actively playing
        guard stateMachine?.currentState is PlayingState else {
            return
        }
        
        for component in components {
            // Check if this RenderComponent belongs to an EnemyEntity (the poop monster)
            if let _ = component.entity as? EnemyEntity {
                let node = component.node
                
                // Trigger condition: Does the Poop's X position cross the Safe Zone X line?
                if node.position.x <= safeZoneX {
                    
                    // Trigger Game Over via the callback!
                    onSafeZoneBreached?()
                    
                    // Remove the enemy node from parent tree
                    node.removeFromParent()
                    
                    // Break out so we don't trigger Game Over multiple times in one frame
                    break
                }
            }
        }
    }
}
