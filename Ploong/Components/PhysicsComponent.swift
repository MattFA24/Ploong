//
//  PhysicsComponent.swift
//  Ploong
//
//  Created by Matthew Fernando Anggrian on 11/05/26.
//  

import SpriteKit
import GameplayKit

final class PhysicsComponent: GKComponent {
    override func didAddToEntity() {
        guard let render = entity?.component(ofType: RenderComponent.self) else {
            return
        }

        // Apply these settings to the body that was ALREADY created in the Entity
        if let body = render.node.physicsBody {
            body.allowsRotation = false
            body.friction = 0
            body.linearDamping = 0
        }
    }
}
