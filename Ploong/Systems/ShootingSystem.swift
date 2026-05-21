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
                guard currentLaneY(for: render.node.position.y) != nil else {
                    continue
                }

                timeSinceLastShot = 0
                
                var bulletOffset = PlayerEntity.Layout.bulletSpawnOffset
                
                let equippedCharacter = CharacterManager.shared.getEquippedCharacter().lowercased()
                switch equippedCharacter {
                case "jevon":
                    bulletOffset.y -= 20
                case "farrell":
                    bulletOffset.y -= 15
                default:
                    break
                }
                
                let bulletOriginX = render.node.position.x + bulletOffset.x
                let bulletPos = CGPoint(x: bulletOriginX, y: render.node.position.y + bulletOffset.y)
                let bullet = BulletEntity(position: bulletPos, damage: component.power)
                
                onEntitySpawned?(bullet)
                
                let screenWidth: CGFloat = render.node.scene?.size.width ?? 900
                
                let travelDist = screenWidth - bulletOriginX - 30
                let duration = Double(travelDist / GameConstants.bulletSpeed)
                
                bullet.component(ofType: RenderComponent.self)?.node.run(.sequence([
                    .moveBy(x: travelDist, y: 0, duration: duration),
                    .removeFromParent()
                ]))
            }
        }
    }


    private func currentLaneY(for playerY: CGFloat) -> CGFloat? {
        let equippedCharacter = CharacterManager.shared.getEquippedCharacter().lowercased()
        var customYOffset: CGFloat = 0
        
        switch equippedCharacter {
        case "jevon": customYOffset = 30
        case "farrell": customYOffset = 25
        default: customYOffset = 0
        }
        
        let idealBottomY = GameConstants.bottomLaneY + GameConstants.bottomPlayerFootOffset + customYOffset
        let idealTopY = GameConstants.topLaneY + GameConstants.topPlayerFootOffset + customYOffset

        let laneTolerance: CGFloat = 5.0


        if abs(playerY - idealBottomY) <= laneTolerance {
            return GameConstants.bottomLaneY
        }

        if abs(playerY - idealTopY) <= laneTolerance {
            return GameConstants.topLaneY
        }

        return nil
    }
}
