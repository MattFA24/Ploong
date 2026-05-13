//
//  GameConstants.swift
//  Ploong
//
//  Created by Matthew Fernando Anggrian on 12/05/26.
//

import Foundation
import CoreGraphics

enum GameConstants {
    static let playerX: CGFloat = 140
    static var bottomLaneY: CGFloat = 180
    static var topLaneY: CGFloat = 460
    static var gateHeight: CGFloat = 260
    static var gateBottomY: CGFloat = 280
    static var gateTopY: CGFloat = 540
    
    static let objectSpeed: CGFloat = 220
    static let spawnInterval: TimeInterval = 4.0
    static let bulletSpeed: CGFloat = 350
    static let powerCap: CGFloat = 5_000
}

struct PhysicsCategory {
    static let none: UInt32   = 0
    static let player: UInt32 = 0x1
    static let gate: UInt32   = 0x2
    static let enemy: UInt32  = 0x4
    static let bullet: UInt32 = 0x8
    static let base: UInt32   = 0x10
}
