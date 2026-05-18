//
//  GateComponent.swift
//  Ploong
//
//  Created by Matthew Fernando Anggrian on 12/05/26.
//

import GameplayKit

enum GateType { case add, multiply, subtract, divide }

final class GateComponent: GKComponent {
    let type: GateType
    let value: CGFloat
    let text: String
    let waveID: Int
    let lane: Int
    
    init(type: GateType, value: CGFloat, text: String, waveID: Int, lane: Int) {
        self.type = type
        self.value = value
        self.text = text
        self.waveID = waveID
        self.lane = lane
        super.init()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
