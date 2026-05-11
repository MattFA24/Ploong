//
//  RenderComponent.swift
//  Ploong
//
//  Created by Matthew Fernando Anggrian on 11/05/26.
//

import SpriteKit
import GameplayKit

final class RenderComponent: GKComponent {
    let node: SKSpriteNode

    init(color: SKColor, size: CGSize) {
        self.node = SKSpriteNode(color: color, size: size)
        super.init()
    }

    required init?(coder: NSCoder) {
        self.node = SKSpriteNode(color: .white, size: CGSize(width: 1, height: 1))
        super.init(coder: coder)
    }

    func addToScene(_ scene: SKScene) {
        if node.parent == nil {
            scene.addChild(node)
        }
    }
}
