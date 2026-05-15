//
//  StatsComponent.swift
//  Ploong
//
//  Created by Matthew Fernando Anggrian on 12/05/26.
//

import GameplayKit

final class StatsComponent: GKComponent {
    var power: CGFloat
    var optimalPower: CGFloat
    var coinsCollected: Int
    
    init(initialPower: CGFloat = 10, coinsCollected: Int = 0) {
        self.power = initialPower
        self.optimalPower = initialPower
        self.coinsCollected = coinsCollected
        super.init()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
