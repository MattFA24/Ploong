//
//  GameLoopScene.swift
//  Ploong
//
//  Created by Matthew Fernando Anggrian on 11/05/26.
//

import SpriteKit

final class GameLoopScene: SKScene {
    override func sceneDidLoad() {
        super.sceneDidLoad()
        backgroundColor = .white
        AudioManager.shared.playGameBgm()
    }
}
