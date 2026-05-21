//
//  CharacterAnimation.swift
//  Ploong
//
//  Created by Matthew Fernando Anggrian on 20/05/26.
//

import SpriteKit

struct CharacterAnimation {
    static func getAnimation(for characterName: String) -> SKAction {
        // Ensure the name is lowercased to match your asset names (e.g., "joy", "farrell")
        let name = characterName.lowercased()
        
        let textureNames = [
            "\(name)_1",
            "\(name)_2",
            "\(name)_3"
        ]
        
        var textures: [SKTexture] = []
        for textureName in textureNames {
            textures.append(SKTexture(imageNamed: textureName))
        }
        
     
        return SKAction.repeatForever(SKAction.animate(with: textures, timePerFrame: 0.15))
    }
}
