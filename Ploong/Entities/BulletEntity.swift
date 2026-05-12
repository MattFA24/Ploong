import SpriteKit
import GameplayKit

final class BulletEntity: GameEntity {
    init(position: CGPoint, damage: CGFloat) {
        super.init()
        
        // 1. Render
        let render = RenderComponent(circleOfRadius: 7, color: .init(red: 0.6, green: 0.3, blue: 0.0, alpha: 1))
        render.node.position = position
        render.node.zPosition = 8
        
        // 2. Physics
        let pb = SKPhysicsBody(circleOfRadius: 7)
        pb.isDynamic = true
        pb.categoryBitMask = PhysicsCategory.bullet
        pb.contactTestBitMask = PhysicsCategory.enemy
        pb.collisionBitMask = 0
        render.node.physicsBody = pb
        
        addComponent(render)
        addComponent(PhysicsComponent())
        addComponent(DamageComponent(amount: damage)) // Inject damage data
    }
    required init?(coder: NSCoder) { super.init(coder: coder) }
}