//
//  SpawnerSystem.swift
//  Ploong
//
//  Created by Matthew Fernando Anggrian on 12/05/26.
//

import SpriteKit
import GameplayKit

final class SpawnerSystem {
    private var timeSinceLastSpawn: TimeInterval = 0
    private var waveCount = 0
    private var timeSurvived: TimeInterval = 0

    var optimalPower: CGFloat = 10
    var currentPlayerPower: CGFloat = 10
    var onEntitySpawned: ((GKEntity) -> Void)?

    func update(deltaTime seconds: TimeInterval, sceneSize: CGSize) {
        timeSurvived += seconds
        timeSinceLastSpawn += seconds

        if timeSinceLastSpawn >= GameConstants.spawnInterval {
            timeSinceLastSpawn = 0
            spawnWave(size: sceneSize)
        }
    }

    private func spawnWave(size: CGSize) {
        let waveID = waveCount
        waveCount += 1
        let isNeg = (waveID % 2 == 1)

        let gate0 = makeGate(isTop: false, negative: isNeg)
        let gate1 = makeGate(isTop: true,  negative: isNeg)

        // 1. Declare gateStartX BEFORE we use it for the gates
        let gateStartX = size.width + 60

        // 2. Use GameConstants for the exact calculated gate Y positions
        let gate0Entity = GateEntity(
            position: CGPoint(x: gateStartX, y: GameConstants.gateBottomY),
            gateData: GateComponent(type: gate0.type, value: gate0.value, text: gate0.text, waveID: waveID, lane: 0)
        )
        let gate1Entity = GateEntity(
            position: CGPoint(x: gateStartX, y: GameConstants.gateTopY),
            gateData: GateComponent(type: gate1.type, value: gate1.value, text: gate1.text, waveID: waveID, lane: 1)
        )

        onEntitySpawned?(gate0Entity)
        onEntitySpawned?(gate1Entity)

        // Gate scrolls from its spawn point to off the left edge.
        let gateTravelDist = gateStartX + 200
        scrollOff(node: gate0Entity.component(ofType: RenderComponent.self)!.node, distanceX: gateTravelDist)
        scrollOff(node: gate1Entity.component(ofType: RenderComponent.self)!.node, distanceX: gateTravelDist)

        // Update optimal power tracking
        let g0 = min(applyGate(gate0, to: optimalPower), GameConstants.powerCap)
        let g1 = min(applyGate(gate1, to: optimalPower), GameConstants.powerCap)
        optimalPower = max(g0, g1)

        let minutesSurvived = CGFloat(timeSurvived) / 60.0
        let difficultyProgress = min(1.0, minutesSurvived / 10.0)
        let margin = 0.80 - (difficultyProgress * 0.75)
        let endlessBuff = max(1.0, 1.0 + max(0, minutesSurvived - 5.0) * 0.02)

        let minHitsToKill = 3.0 + Double(difficultyProgress) * 5.0
        let powerRatio = Double(currentPlayerPower / GameConstants.powerCap)
        let fireInterval = max(0.12, 0.25 - powerRatio * 0.13)
        let minHP = currentPlayerPower * CGFloat(fireInterval) * CGFloat(minHitsToKill)

        let rawBaseHP = optimalPower * (1.0 - margin) * endlessBuff
        let baseEnemyHP = max(rawBaseHP, minHP)
        let count = poopCount()

        let doubleLaneChance = min(1.0, minutesSurvived / 3.0)
        let isDoubleLane = CGFloat.random(in: 0...1) < doubleLaneChance

        // NEW FIX: Simply spawn the enemies 350px behind the gate
        // This ensures Wave 1's enemies are completely gone before Wave 2's gate arrives!
        let baseEnemyStartX = gateStartX + 350

        // 3. Use GameConstants for the exact calculated enemy Y positions
        if isDoubleLane {
            let laneDelayDistance: CGFloat = 330
            let pattern = Int.random(in: 0...2)
            let bottomStartX: CGFloat
            let topStartX: CGFloat

            switch pattern {
            case 0:
                bottomStartX = baseEnemyStartX
                topStartX = baseEnemyStartX + laneDelayDistance
            case 1:
                bottomStartX = baseEnemyStartX + laneDelayDistance
                topStartX = baseEnemyStartX
            default:
                bottomStartX = baseEnemyStartX
                topStartX = baseEnemyStartX
            }

            spawnLine(laneY: GameConstants.bottomLaneY, baseHP: baseEnemyHP, count: count,
                      progress: difficultyProgress, startX: bottomStartX)
            spawnLine(laneY: GameConstants.topLaneY, baseHP: baseEnemyHP, count: count,
                      progress: difficultyProgress, startX: topStartX)
        } else {
            let randomLaneY = Bool.random() ? GameConstants.bottomLaneY : GameConstants.topLaneY
            spawnLine(laneY: randomLaneY, baseHP: baseEnemyHP, count: count,
                      progress: difficultyProgress, startX: baseEnemyStartX)
        }
    }

    private func spawnLine(laneY: CGFloat, baseHP: CGFloat, count: Int, progress: CGFloat, startX: CGFloat) {
        let minMod = 0.10 + (progress * 0.75)
        let maxMod = 1.50 - (progress * 0.45)
        let spacing: CGFloat = count > 3 ? 100 : 80

        for i in 0..<count {
            let modifier = CGFloat.random(in: minMod...maxMod)
            let finalHP = snapToTier(baseHP * modifier)

            let xPos = startX + CGFloat(i) * spacing
            let enemy = EnemyEntity(position: CGPoint(x: xPos, y: laneY), hp: finalHP)
            onEntitySpawned?(enemy)

            // Move by relative distance leftwards offscreen
            let travelDist = xPos + 200
            scrollOff(node: enemy.component(ofType: RenderComponent.self)!.node, distanceX: travelDist)
        }
    }

    private func scrollOff(node: SKNode, distanceX: CGFloat) {
        node.run(.sequence([
            .moveBy(x: -distanceX, y: 0, duration: Double(distanceX / GameConstants.objectSpeed)),
            .removeFromParent()
        ]))
    }
    
    // MARK: - Extracted Math Logic
    private func poopCount() -> Int {
        let fractionalCount = 1.0 + (CGFloat(timeSurvived) / 90.0)
        let baseCount = Int(fractionalCount)
        let extraChance = fractionalCount - CGFloat(baseCount)
        let isExtra = CGFloat.random(in: 0...1) < extraChance ? 1 : 0
        return min(baseCount + isExtra, 5)
    }
    
    private func snapToTier(_ v: CGFloat) -> CGFloat {
        if v >= 1_000 { return max(1_000, round(v / 500) * 500) }
        if v >= 100   { return max(100,   round(v / 50)  * 50)  }
        return max(1, round(v / 10) * 10 > 0 ? round(v / 10) * 10 : 1)
    }
    
    private func applyGate(_ gate: GateComponent, to power: CGFloat) -> CGFloat {
        let p: CGFloat
        switch gate.type {
        case .add:      p = power + gate.value
        case .multiply: p = power * gate.value
        case .subtract: p = power - gate.value
        case .divide:   p = power / gate.value
        }
        return max(p, 1)
    }
    
    private func makeGate(isTop: Bool, negative: Bool) -> GateComponent {
        let minutesSurvived = CGFloat(timeSurvived) / 60.0
        
        if negative {
            if Bool.random() {
                let ratio: CGFloat
                if currentPlayerPower > GameConstants.powerCap * 0.8      { ratio = 0.40 }
                else if currentPlayerPower > GameConstants.powerCap * 0.5 { ratio = 0.30 }
                else                                                      { ratio = 0.20 }
                let subValue = snapToTier(currentPlayerPower * ratio)
                return GateComponent(type: .subtract, value: subValue, text: "-", waveID: 0, lane: 0)
            } else {
                var divisor: CGFloat = 2
                if currentPlayerPower > 1_000 && Bool.random() { divisor = 3 }
                if currentPlayerPower > 3_000 && Bool.random() { divisor = 5 }
                return GateComponent(type: .divide, value: divisor, text: "/", waveID: 0, lane: 0)
            }
        } else {
            if isTop {
                var pool: [CGFloat] = [2]
                if minutesSurvived >= 1.0 && optimalPower < 2_000 { pool.append(3) }
                if minutesSurvived >= 2.0 && optimalPower < 500   { pool.append(5) }
                
                let safe = pool.filter { optimalPower * $0 <= GameConstants.powerCap }
                if safe.isEmpty {
                    return GateComponent(type: .add, value: 200, text: "+", waveID: 0, lane: 0)
                }
                return GateComponent(type: .multiply, value: safe.randomElement()!, text: "×", waveID: 0, lane: 0)
            } else {
                let addValue: CGFloat
                if minutesSurvived < 0.5      { addValue = [50, 100].randomElement()! }
                else if minutesSurvived < 1.0 { addValue = [100, 200].randomElement()! }
                else if minutesSurvived < 2.0 { addValue = [200, 300].randomElement()! }
                else if optimalPower > 3_000  { addValue = [100, 500].randomElement()! }
                else                          { addValue = [500, 1_000].randomElement()! }
                return GateComponent(type: .add, value: addValue, text: "+", waveID: 0, lane: 0)
            }
        }
    }
}
