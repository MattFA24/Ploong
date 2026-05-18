//
//  MovementSystem.swift
//  Ploong
//
//  Created by Matthew Fernando Anggrian on 11/05/26.
//

import GameplayKit
import SpriteKit

final class MovementSystem {
    private let componentSystem = GKComponentSystem(componentClass: InputComponent.self)

    func addEntity(_ entity: GKEntity) {
        componentSystem.addComponent(foundIn: entity)
    }

    func removeEntity(_ entity: GKEntity) {
        if let component = entity.component(ofType: InputComponent.self) {
            componentSystem.removeComponent(component)
        }
    }

    func update(deltaTime: TimeInterval) {
        let dt = CGFloat(deltaTime)

        for case let input as InputComponent in componentSystem.components {
            guard let render = input.entity?.component(ofType: RenderComponent.self) else {
                continue
            }

            let velocity = CGVector(dx: input.movement.dx * input.speed,
                                    dy: input.movement.dy * input.speed)

            if let body = render.node.physicsBody {
                body.velocity = velocity
            } else {
                render.node.position.x += velocity.dx * dt
                render.node.position.y += velocity.dy * dt
            }
        }
    }
}
