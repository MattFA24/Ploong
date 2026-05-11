//
//  GameEntity.swift
//  Ploong
//
//  Created by Matthew Fernando Anggrian on 11/05/26.
//  

import SpriteKit
import GameplayKit

final class GameEntity: GKEntity {
    init(node: SKNode) {
        super.init()
        addComponent(RenderComponent(node: node))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
