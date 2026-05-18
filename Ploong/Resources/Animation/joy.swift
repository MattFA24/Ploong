//
//  joy.swift
//  Ploong
//
//  Created by Joycelyn Emmanuella Passandaran on 15/05/26.
//

import SpriteKit

enum JoyAnimation {
    static let frameNames = ["joy_1", "joy_2", "joy_3", "joy_2"]

    static func idleAction(timePerFrame: TimeInterval = 0.2) -> SKAction {
        let textures = frameNames.map { frameName in
            let texture = SKTexture(imageNamed: frameName)
            texture.filteringMode = .nearest
            return texture
        }

        let animation = SKAction.animate(with: textures, timePerFrame: timePerFrame)
        return SKAction.repeatForever(animation)
    }
}
