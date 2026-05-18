//
//  HealthComponent.swift
//  Ploong
//
//  Created by Matthew Fernando Anggrian on 12/05/26.
//

import GameplayKit

final class HealthComponent: GKComponent {
    var currentHP: CGFloat
    let maxHP: CGFloat
    
    init(hp: CGFloat) {
        self.currentHP = hp
        self.maxHP = hp
        super.init()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
