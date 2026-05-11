//
//  RenderSystem.swift
//  Ploong
//
//  Created by Matthew Fernando Anggrian on 11/05/26.
//

import GameplayKit
import SpriteKit

final class RenderSystem {
    private let componentSystem = GKComponentSystem(componentClass: RenderComponent.self)

    func addEntity(_ entity: GKEntity) {
        componentSystem.addComponent(foundIn: entity)
    }

    func removeEntity(_ entity: GKEntity) {
        if let component = entity.component(ofType: RenderComponent.self) {
            componentSystem.removeComponent(component)
        }
    }

    func addToScene(_ scene: SKScene) {
        for case let render as RenderComponent in componentSystem.components {
            render.addToScene(scene)
        }
    }
}
