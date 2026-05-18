//
//  Coin.swift
//  Ploong
//
//  Created by Jevon Ivander Kangsudarmanto on 18/05/26.
//

import SpriteKit

enum CoinAnimation {
    static let frameNames = ["coin_1", "coin_2", "coin_3", "coin_4"]

    static let transparentBlackShader = SKShader(source: """
        void main() {
            vec4 color = texture2D(u_texture, v_tex_coord);
            if (color.r < 0.04 && color.g < 0.04 && color.b < 0.04) {
                color.a = 0.0;
            }
            gl_FragColor = color;
        }
        """)

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
