//
//  InputComponent.swift
//  Ploong
//
//  Created by Matthew Fernando Anggrian on 11/05/26.
//  

import GameplayKit
import CoreGraphics

final class InputComponent: GKComponent {
    var movement: CGVector = .zero
    var speed: CGFloat

    init(speed: CGFloat = 420) {
        self.speed = speed
        super.init()
    }

    required init?(coder: NSCoder) {
        self.speed = 420
        super.init(coder: coder)
    }
}
