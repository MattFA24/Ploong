//
//  RenderComponent.swift
//  Ploong
//
//  Created by Matthew Fernando Anggrian on 11/05/26.
//  

import SpriteKit
import GameplayKit

final class RenderComponent: GKComponent {
    let node: SKNode

    init(node: SKNode) {
        self.node = node
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
