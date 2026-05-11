//
//  PlayerEntity.swift
//  Ploong
//
//  Created by Matthew Fernando Anggrian on 11/05/26.
//  

import SpriteKit
import GameplayKit

final class PlayerEntity: GameEntity {
    init(position: CGPoint) {
        super.init()

        let render = RenderComponent(color: .white, size: CGSize(width: 80, height: 80))
        render.node.position = position
        addComponent(render)

        addComponent(InputComponent())
        addComponent(PhysicsComponent())
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
