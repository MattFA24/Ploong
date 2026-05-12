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
    
    init(initialPower: CGFloat = 10) {
        self.power = initialPower
        self.optimalPower = initialPower
        super.init()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
