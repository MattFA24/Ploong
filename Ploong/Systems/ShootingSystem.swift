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
                
                let bulletOriginX = render.node.position.x + render.node.frame.width / 2 + 8
                let bulletPos = CGPoint(x: bulletOriginX, y: render.node.position.y)
                let bullet = BulletEntity(position: bulletPos, damage: component.power)
                
                onEntitySpawned?(bullet)
                
                let screenWidth: CGFloat = render.node.scene?.size.width ?? 900
                
                // BUG 1 FIX: Only travel to the right edge of the screen.
                // Original GameScene: travelDist = size.width - bullet.position.x - 30
                // Your version was adding 1200 extra pixels, sending bullets into
                // off-screen territory where poops are still arriving — causing phantom hits.
                let travelDist = screenWidth - bulletOriginX - 30
                let duration = Double(travelDist / GameConstants.bulletSpeed)
                
                bullet.component(ofType: RenderComponent.self)?.node.run(.sequence([
                    .moveBy(x: travelDist, y: 0, duration: duration),
                    .removeFromParent()
                ]))
            }
        }
    }
}
