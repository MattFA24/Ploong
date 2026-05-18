import GameplayKit
import SpriteKit

// This system tracks entities (like the Poop enemy) to check if they cross the safe zone line.
class SafeZoneSystem: GKComponentSystem<RenderComponent> {
    weak var stateMachine: GKStateMachine?
    weak var scene: SKScene?
    var safeZoneX: CGFloat
    
    init(safeZoneX: CGFloat, stateMachine: GKStateMachine?, scene: SKScene?) {
        self.safeZoneX = safeZoneX
        self.stateMachine = stateMachine
        self.scene = scene
        super.init(componentClass: RenderComponent.self)
        
        drawSafeZoneIndicator()
    }
    
    // Draws the transparent vertical area on the far left side
    private func drawSafeZoneIndicator() {
        guard let scene = scene else { return }
        
        // Creates a transparent vertical box to act as the visual boundary
        let safeZoneNode = SKSpriteNode(color: SKColor.green.withAlphaComponent(0.15),
                                        size: CGSize(width: 40, height: scene.size.height))
        
        safeZoneNode.position = CGPoint(x: safeZoneX, y: scene.size.height / 2)
        safeZoneNode.zPosition = 50 // Place it behind the front UI, but above the background map
        safeZoneNode.name = "SafeZoneIndicator"
        
        // Add dashed line or border effect if desired
        let edgeLine = SKShapeNode(rectOf: safeZoneNode.size)
        edgeLine.strokeColor = .green
        edgeLine.lineWidth = 1
        edgeLine.alpha = 0.5
        safeZoneNode.addChild(edgeLine)
        
        scene.addChild(safeZoneNode)
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)
        
        // Stop checking if the game has already ended
        if stateMachine?.currentState is GameOverState {
            return
        }
        
        for component in components {
            // Check if this RenderComponent belongs to an EnemyEntity (the poop monster)
            if let _ = component.entity as? EnemyEntity {
                let node = component.node
                
                // Trigger condition: Does the Poop's X position cross the Safe Zone X?
                // Depending on your anchor points, you might want to use: node.frame.minX <= safeZoneX
                if node.position.x <= safeZoneX {
                    
                    // The poop breached the safe zone! Trigger Game Over instantly.
                    stateMachine?.enter(GameOverState.self)
                    
                    // Optional: remove the enemy or play a splat sound
                    node.removeFromParent()
                    
                    // Break out so we don't trigger Game Over multiple times in one frame
                    break
                }
            }
        }
    }
}
