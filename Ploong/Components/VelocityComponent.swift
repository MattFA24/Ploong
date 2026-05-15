//
//  VelocityComponent.swift
//  Ploong
//

import CoreGraphics
import GameplayKit

final class VelocityComponent: GKComponent {
    let velocity: CGVector

    init(velocity: CGVector) {
        self.velocity = velocity
        super.init()
    }

    required init?(coder: NSCoder) {
        self.velocity = CGVector(dx: coder.decodeDouble(forKey: "dx"),
                                 dy: coder.decodeDouble(forKey: "dy"))
        super.init(coder: coder)
    }
}
