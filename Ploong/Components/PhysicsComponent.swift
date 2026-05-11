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

        let body = SKPhysicsBody(rectangleOf: render.node.size)
        body.allowsRotation = false
        body.friction = 0
        body.linearDamping = 0
        render.node.physicsBody = body
    }
}
