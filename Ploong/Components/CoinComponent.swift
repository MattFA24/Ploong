//
//  CoinComponent.swift
//  Ploong
//

import GameplayKit

final class CoinComponent: GKComponent {
    let value: Int

    init(value: Int = 1) {
        self.value = value
        super.init()
    }

    required init?(coder: NSCoder) {
        self.value = coder.decodeInteger(forKey: "value")
        super.init(coder: coder)
    }
}
