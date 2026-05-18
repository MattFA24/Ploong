//
//  DamageComponent.swift
//  Ploong
//
//  Created by Matthew Fernando Anggrian on 12/05/26.
//


import GameplayKit

final class DamageComponent: GKComponent {
    let amount: CGFloat
    
    init(amount: CGFloat) {
        self.amount = amount
        super.init()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}