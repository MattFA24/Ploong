//
//  PausedState.swift
//  Ploong
//
//  Created by Matthew Fernando Anggrian on 11/05/26.
//

import GameplayKit

final class PausedState: GKState {
    private unowned let scene: GameLoopScene

    init(scene: GameLoopScene) {
        self.scene = scene
        super.init()
    }

    override func didEnter(from previousState: GKState?) {
        scene.enterPaused()
    }
}
