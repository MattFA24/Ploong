//
//  SpawnerSystem.swift
//  Ploong
//
//  Created by Matthew Fernando Anggrian on 12/05/26.
//

import SpriteKit
import GameplayKit

final class SpawnerSystem {
    // BUG 2 FIX: was 4.0, caused wave to fire on frame 1
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

        let lane0Y = size.height / 2 - GameConstants.laneGap / 2
        let lane1Y = size.height / 2 + GameConstants.laneGap / 2
        let gateStartX = size.width + 60

        let gate0Entity = GateEntity(
            position: CGPoint(x: gateStartX, y: lane0Y),
            gateData: GateComponent(type: gate0.type, value: gate0.value, text: gate0.text, waveID: waveID, lane: 0)
        )
        let gate1Entity = GateEntity(
            position: CGPoint(x: gateStartX, y: lane1Y),
            gateData: GateComponent(type: gate1.type, value: gate1.value, text: gate1.text, waveID: waveID, lane: 1)
        )

        onEntitySpawned?(gate0Entity)
        onEntitySpawned?(gate1Entity)

        // Gate scrolls from its spawn point to off the left edge.
        // moveBy is RELATIVE, so distance = gateStartX + some offscreen buffer
        let gateTravelDist = gateStartX + 200   // ends at x = (gateStartX) - (gateStartX+200) = -200 ✓
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

        // KEY FIX: no DispatchQueue. Enemy start X is calculated so that by the time
        // the enemy scrolls into view, the gate has already passed the player.
        //
        // Time for gate to pass player = (gateStartX - playerX) / speed
        //                              = (size.width + 60 - 140) / 220
        // Add 0.5s buffer.
        // In that total time, enemies travel: time * speed pixels from their spawn.
        // So enemies must START that many pixels further right than the screen edge.
        //
        // enemyHeadStart = ((size.width + 60 - GameConstants.playerX) / GameConstants.objectSpeed + 0.5)
        //                  * GameConstants.objectSpeed
        let gateToPlayerTime = (size.width + 60 - GameConstants.playerX) / GameConstants.objectSpeed
        let bufferTime: CGFloat = 0.5
        let enemyHeadStart = (gateToPlayerTime + bufferTime) * GameConstants.objectSpeed

        // Enemies spawn this far off the right edge
        let baseEnemyStartX = size.width + enemyHeadStart

        if isDoubleLane {
            spawnLine(laneY: lane0Y, baseHP: baseEnemyHP, count: count,
                      progress: difficultyProgress, startX: baseEnemyStartX)
            // Second lane 1.5s later = 1.5 * 220 = 330px further right
            spawnLine(laneY: lane1Y, baseHP: baseEnemyHP, count: count,
                      progress: difficultyProgress, startX: baseEnemyStartX + 330)
        } else {
            let randomLaneY = Bool.random() ? lane0Y : lane1Y
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

            // moveBy is RELATIVE. Enemy is at xPos, needs to reach x = -200.
            // So it must move (xPos + 200) pixels to the left.
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
