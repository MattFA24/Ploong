import GameplayKit

final class ShootingSystem: GKComponentSystem<StatsComponent> {
    private var timeSinceLastShot: TimeInterval = 0
    
    init() {
        super.init(componentClass: StatsComponent.self)
    }
    
    func update(deltaTime seconds: TimeInterval, renderSystem: RenderSystem) {
        timeSinceLastShot += seconds
        
        for component in components {
            guard let entity = component.entity as? GameEntity,
                  let render = entity.component(ofType: RenderComponent.self) else { continue }
            
            // Calculate fire rate based on power
            let powerRatio = Double(component.power / GameConstants.powerCap)
            let fireInterval = max(0.12, 0.25 - powerRatio * 0.13)
            
            if timeSinceLastShot >= fireInterval {
                timeSinceLastShot = 0
                
                // Spawn bullet
                let bulletPos = CGPoint(x: render.node.position.x + render.node.frame.width / 2 + 8, y: render.node.position.y)
                let bullet = BulletEntity(position: bulletPos, damage: component.power)
                
                renderSystem.addEntity(bullet)
                
                // Move bullet
                let travelDist = 2000.0 // Fly off screen
                let duration = travelDist / GameConstants.bulletSpeed
                let bulletRender = bullet.component(ofType: RenderComponent.self)?.node
                bulletRender?.run(.sequence([
                    .moveBy(x: travelDist, y: 0, duration: duration),
                    .removeFromParent()
                ]))
            }
        }
    }
}