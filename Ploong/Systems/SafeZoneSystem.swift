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
    static let safeZoneTileScale: CGFloat = 0.7

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

        let safeZoneTexture = SKTexture(imageNamed: "safe_zone_dark")
        safeZoneTexture.filteringMode = .nearest

        let tileSize = safeZoneTexture.size()
        guard tileSize.width > 0, tileSize.height > 0 else { return }
        let scaledTileHeight = tileSize.height * Self.safeZoneTileScale

        let safeZoneNode = SKNode()
        safeZoneNode.position = .zero
        safeZoneNode.zPosition = -8
        safeZoneNode.name = "SafeZoneIndicator"

        let tileCount = Int(ceil(scene.size.height / scaledTileHeight)) + 1
        for index in 0..<tileCount {
            let tile = SKSpriteNode(texture: safeZoneTexture)
            tile.anchorPoint = CGPoint(x: 0, y: 0)
            tile.setScale(Self.safeZoneTileScale)
            tile.position = CGPoint(x: 0, y: CGFloat(index) * scaledTileHeight)
            tile.zPosition = 0
            safeZoneNode.addChild(tile)
        }

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
