//
//  SpriteEntity.swift
//  Ploong
//
//  Created by Matthew Fernando Anggrian on 11/05/26.
//

import SpriteKit
import GameplayKit

final class SpriteEntity: GameEntity {
    init(textureName: String, size: CGSize, position: CGPoint, zPosition: CGFloat) {
        super.init()

        let render = RenderComponent(textureName: textureName, size: size, zPosition: zPosition)
        render.node.position = position
        addComponent(render)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
