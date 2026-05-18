//
//  Enemy.swift
//  Ploong
//

import SpriteKit

enum EnemyAnimation {
    enum Tier: Int {
        case enemy1 = 1
        case enemy2
        case enemy3
        case enemy4

        var frameNames: [String] {
            (1...4).map { "enemy\(rawValue)_\($0)" }
        }

        var textureName: String {
            "enemy\(rawValue)_1"
        }

        var size: CGSize {
            switch self {
            case .enemy1:
                return CGSize(width: 62*1.2, height: 54*1.2)
            case .enemy2:
                return CGSize(width: 70*1.4, height: 66*1.4)
            case .enemy3:
                return CGSize(width: 83*1.6, height: 78*1.6)
            case .enemy4:
                return CGSize(width: 114*1.8, height: 88*1.8)
            }
        }
    }

    static func tier(for hp: CGFloat) -> Tier {
        switch hp {
        case ..<500:
            return .enemy1
        case ..<1_500:
            return .enemy2
        case ..<2_500:
            return .enemy3
        default:
            return .enemy4
        }
    }

    static func idleAction(for tier: Tier, timePerFrame: TimeInterval = 0.2) -> SKAction {
        let textures = tier.frameNames.map { frameName in
            let texture = SKTexture(imageNamed: frameName)
            texture.filteringMode = .nearest
            return texture
        }

        let animation = SKAction.animate(with: textures, timePerFrame: timePerFrame)
        return SKAction.repeatForever(animation)
    }
}
