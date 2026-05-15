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

        if timeSinceLastSpawn >= currentSpawnInterval() {
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

        let difficultyProgress = difficultyProgress()
        let margin = 0.65 - (difficultyProgress * 0.45)
        let endlessBuff = max(1.0, 1.0 + max(0, CGFloat(timeSurvived) - 180.0) / 60.0 * 0.04)

        let minHitsToKill = CGFloat.random(in: targetHitRange())
        let powerBasedHP = currentPlayerPower * minHitsToKill
        let optimalBasedHP = optimalPower * (1.0 - margin) * endlessBuff
        let baseEnemyHP = max(optimalBasedHP, powerBasedHP)
        let count = poopCount()

        let isDoubleLane = CGFloat.random(in: 0...1) < doubleLaneChance()

        let spacing = enemySpacing(for: count)
        let lineWidth = CGFloat(max(count - 1, 0)) * spacing
        let baseEnemyStartX = safeEnemyStartX(afterGateAt: gateStartX, lineWidth: lineWidth)
        let safeDelayedLaneDistance = max(0, GameConstants.objectSpeed * CGFloat(currentSpawnInterval()) - lineWidth - 260)

        // 3. Use GameConstants for the exact calculated enemy Y positions
        if isDoubleLane {
            let laneDelayDistance = min(330, safeDelayedLaneDistance)
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
        let minMod = 0.85 + (progress * 0.15)
        let maxMod = 1.20 + (progress * 0.25)
        let spacing = enemySpacing(for: count)

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
    private enum DifficultyStage {
        case early
        case mid
        case late

        var hitRange: ClosedRange<CGFloat> {
            switch self {
            case .early: return 2...3
            case .mid: return 4...6
            case .late: return 6...9
            }
        }
    }

    private func warmUpProgress() -> CGFloat {
        min(1.0, CGFloat(timeSurvived) / 30.0)
    }

    private func targetHitRange() -> ClosedRange<CGFloat> {
        if timeSurvived < 30 {
            let progress = warmUpProgress()
            return (1.5 + progress * 0.5)...(2.2 + progress * 0.8)
        }

        if timeSurvived < 150 {
            let progress = CGFloat((timeSurvived - 30) / 120.0)
            return (2.0 + progress * 0.5)...(3.0 + progress * 0.5)
        }

        if timeSurvived < 300 {
            let progress = CGFloat((timeSurvived - 150) / 150.0)
            return (2.5 + progress * 1.0)...(3.5 + progress * 1.25)
        }

        let progress = min(1.0, CGFloat((timeSurvived - 300) / 180.0))
        return (3.5 + progress * 1.0)...(4.75 + progress * 1.25)
    }

    private func doubleLaneChance() -> CGFloat {
        if timeSurvived < 30 {
            let progress = warmUpProgress()
            return 0.12 + (progress * 0.13)
        }

        if timeSurvived < 150 {
            let progress = CGFloat((timeSurvived - 30) / 120.0)
            return 0.25 + (progress * 0.15)
        }

        if timeSurvived < 300 {
            let progress = CGFloat((timeSurvived - 150) / 150.0)
            return 0.40 + (progress * 0.20)
        }

        let progress = min(1.0, CGFloat((timeSurvived - 300) / 180.0))
        return 0.60 + (progress * 0.20)
    }

    private func stage() -> DifficultyStage {
        if timeSurvived < 150 { return .early }
        if timeSurvived < 360 { return .mid }
        return .late
    }

    private func difficultyProgress() -> CGFloat {
        min(1.0, CGFloat(timeSurvived) / 360.0)
    }

    private func currentSpawnInterval() -> TimeInterval {
        if timeSurvived < 30 {
            let progress = TimeInterval(warmUpProgress())
            return 3.6 - (0.4 * progress)
        }

        if timeSurvived < 180 {
            let progress = TimeInterval((timeSurvived - 30) / 150.0)
            return 3.2 - (0.2 * progress)
        }

        let progress = min(1.0, TimeInterval((timeSurvived - 180) / 180.0))
        return 3.1 - (0.1 * progress)
    }

    private func poopCount() -> Int {
        let fractionalCount = 2.0 + (CGFloat(timeSurvived) / 120.0)
        let baseCount = Int(fractionalCount)
        let extraChance = fractionalCount - CGFloat(baseCount)
        let isExtra = CGFloat.random(in: 0...1) < extraChance ? 1 : 0
        return min(baseCount + isExtra, 5)
    }

    private func enemySpacing(for count: Int) -> CGFloat {
        count > 3 ? 100 : 90
    }

    private func safeEnemyStartX(afterGateAt gateStartX: CGFloat, lineWidth: CGFloat) -> CGFloat {
        let gateHalfWidth: CGFloat = 30
        let enemyHalfWidth: CGFloat = 25
        let currentGateMargin: CGFloat = 70
        let nextGateMargin: CGFloat = 75
        let travelBeforeNextGate = GameConstants.objectSpeed * CGFloat(currentSpawnInterval())
        let earliestReadableStartX = gateStartX + gateHalfWidth + enemyHalfWidth + currentGateMargin
        let latestStartXToClearNextGate = gateStartX + travelBeforeNextGate - lineWidth - gateHalfWidth - enemyHalfWidth - nextGateMargin
        return max(earliestReadableStartX, latestStartXToClearNextGate)
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
        let currentStage = stage()
        let progress = difficultyProgress()
        
        if negative {
            if Bool.random() {
                let ratio: CGFloat
                if timeSurvived < 30 {
                    ratio = currentPlayerPower > 500 ? 0.15 : 0.10
                } else {
                    switch currentStage {
                    case .early:
                        ratio = currentPlayerPower > 500 ? 0.25 : 0.20
                    case .mid:
                        ratio = currentPlayerPower > 2_000 ? 0.35 : 0.30
                    case .late:
                        ratio = currentPlayerPower > GameConstants.powerCap * 0.8 ? 0.45 : 0.40
                    }
                }
                let subValue = snapToTier(max(10, currentPlayerPower * ratio))
                return GateComponent(type: .subtract, value: subValue, text: "-", waveID: 0, lane: 0)
            } else {
                var divisorPool: [CGFloat] = [2]
                if timeSurvived >= 150 && (currentPlayerPower >= 800 || progress >= 0.35) { divisorPool.append(3) }
                if timeSurvived >= 240 && (currentPlayerPower >= 2_500 || progress >= 0.75) { divisorPool.append(5) }
                return GateComponent(type: .divide, value: divisorPool.randomElement()!, text: "/", waveID: 0, lane: 0)
            }
        } else {
            if isTop {
                var pool: [CGFloat] = [2, 2]
                if timeSurvived >= 45 && optimalPower < 2_000 { pool.append(3) }
                if timeSurvived >= 210 && optimalPower < 700 && CGFloat.random(in: 0...1) < 0.25 { pool.append(5) }
                
                let safe = pool.filter { optimalPower * $0 <= GameConstants.powerCap }
                if safe.isEmpty {
                    return GateComponent(type: .add, value: 200, text: "+", waveID: 0, lane: 0)
                }
                return GateComponent(type: .multiply, value: safe.randomElement()!, text: "×", waveID: 0, lane: 0)
            } else {
                let addValue: CGFloat
                switch currentStage {
                case .early:
                    addValue = [50, 100, 150].randomElement()!
                case .mid:
                    addValue = optimalPower > 2_500 ? [100, 200, 300].randomElement()! : [200, 300, 500].randomElement()!
                case .late:
                    addValue = optimalPower > 3_500 ? [100, 300, 500].randomElement()! : [500, 750, 1_000].randomElement()!
                }
                return GateComponent(type: .add, value: addValue, text: "+", waveID: 0, lane: 0)
            }
        }
    }
}
