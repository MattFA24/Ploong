//
//  LayoutComponent.swift
//  Ploong
//
//  Created by Matthew Fernando Anggrian on 11/05/26.
//

import SpriteKit
import GameplayKit

final class LayoutComponent: GKComponent {
    typealias LayoutHandler = (SKNode, CGSize) -> Void

    private let handler: LayoutHandler

    init(handler: @escaping LayoutHandler) {
        self.handler = handler
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyLayout(sceneSize: CGSize) {
        guard let render = entity?.component(ofType: RenderComponent.self) else { return }
        handler(render.node, sceneSize)
    }
}
