//
//  ShootingSystem.swift
//  Ploong
//
//  Created by Matthew Fernando Anggrian on 12/05/26.
//

import SpriteKit
import GameplayKit

final class ShootingSystem {
    private let componentSystem = GKComponentSystem(componentClass: StatsComponent.self)
    private var timeSinceLastShot: TimeInterval = 0
    
    
    // Callback to pass the entity back to the scene
    var onEntitySpawned: ((GKEntity) -> Void)?
    
    func addComponent(_ component: StatsComponent) {
        componentSystem.addComponent(component)
    }
    
    func update(deltaTime seconds: TimeInterval) {
        timeSinceLastShot += seconds
        
        for case let component as StatsComponent in componentSystem.components {
            guard let entity = component.entity,
                  let render = entity.component(ofType: RenderComponent.self) else { continue }
            
            let powerRatio = Double(component.power / GameConstants.powerCap)
            let fireInterval = max(0.12, 0.25 - powerRatio * 0.13)
            
            if timeSinceLastShot >= fireInterval {
                timeSinceLastShot = 0
                
                let bulletPos = CGPoint(x: render.node.position.x + render.node.frame.width / 2 + 8, y: render.node.position.y)
                let bullet = BulletEntity(position: bulletPos, damage: component.power)
                
                // Notify the scene to render and retain the bullet
                onEntitySpawned?(bullet)
                
                // Fetch scene width dynamically so the bullet despawns right after leaving the screen
                let screenWidth: CGFloat = render.node.scene?.size.width ?? 900
                let travelDist = screenWidth - bulletPos.x + 1200
                
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
