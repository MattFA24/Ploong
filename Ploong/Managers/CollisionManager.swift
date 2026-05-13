//
//  CollisionManager.swift
//  Ploong
//
//  Created by Matthew Fernando Anggrian on 11/05/26.
//

import SpriteKit
import GameplayKit

final class CollisionManager: NSObject, SKPhysicsContactDelegate {
    weak var scene: SKScene?
    var onPlayerHitEnemy: (() -> Void)?
    
    func didBegin(_ contact: SKPhysicsContact) {
        let masks = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        let nA = contact.bodyA.node
        let nB = contact.bodyB.node
        
        // ==========================================
        // 1. PLAYER HITS A MATH GATE
        // ==========================================
        if masks == (PhysicsCategory.player | PhysicsCategory.gate) {
            let gateNode = contact.bodyA.categoryBitMask == PhysicsCategory.gate ? nA : nB
            let playerNode = contact.bodyA.categoryBitMask == PhysicsCategory.player ? nA : nB
            
            guard let gateNode = gateNode, let playerNode = playerNode else { return }
            
            // Extract the ECS Components attached to these nodes
            guard let gateEntity = gateNode.entity as? GKEntity,
                  let gateComp = gateEntity.component(ofType: GateComponent.self),
                  let playerEntity = playerNode.entity as? GKEntity,
                  let statsComp = playerEntity.component(ofType: StatsComponent.self) else { return }
            
            // Remove the gate we touched
            gateNode.removeFromParent()
            
            // Remove the sibling gate (the one in the other lane from the same wave)
            scene?.enumerateChildNodes(withName: "gate") { node, _ in
                if let siblingEntity = node.entity as? GKEntity,
                   let siblingComp = siblingEntity.component(ofType: GateComponent.self),
                   siblingComp.waveID == gateComp.waveID {
                    node.removeFromParent()
                }
            }
            
            // Apply Math to Player Power
            let oldPower = statsComp.power
            let newPower = min(applyGate(gateComp, to: oldPower), GameConstants.powerCap)
            statsComp.power = newPower
            
            // UPDATE THE TEXT LABEL ON THE PLAYER
            if let powerText = playerNode.childNode(withName: "powerText") as? SKLabelNode {
                powerText.text = tierLabel(newPower)
            }
            
            // Visual Feedback: Flash Red (Bad Gate) or Green (Good Gate)
            let isBadGate = newPower < oldPower
            if isBadGate {
                playerNode.run(.sequence([
                    .colorize(with: .red, colorBlendFactor: 0.8, duration: 0.07),
                    .colorize(with: .white, colorBlendFactor: 0.0, duration: 0.15)
                ]))
            } else {
                playerNode.run(.sequence([
                    .colorize(with: .green, colorBlendFactor: 0.8, duration: 0.07),
                    .colorize(with: .white, colorBlendFactor: 0.0, duration: 0.12)
                ]))
            }
        }
        
        // ==========================================
        // 2. BULLET HITS AN ENEMY
        // ==========================================
        if masks == (PhysicsCategory.bullet | PhysicsCategory.enemy) {
            let bulletNode = contact.bodyA.categoryBitMask == PhysicsCategory.bullet ? nA : nB
            let enemyNode = contact.bodyA.categoryBitMask == PhysicsCategory.enemy ? nA : nB
            
            guard let bulletNode = bulletNode, let enemyNode = enemyNode else { return }
            
            // Extract ECS Components
            guard let bulletEntity = bulletNode.entity as? GKEntity,
                  let damageComp = bulletEntity.component(ofType: DamageComponent.self),
                  let enemyEntity = enemyNode.entity as? GKEntity,
                  let hpComp = enemyEntity.component(ofType: HealthComponent.self) else { return }
            
            // Apply Damage
            bulletNode.removeFromParent()
            hpComp.currentHP -= damageComp.amount
            
            // Check if Enemy Died
            if hpComp.currentHP <= 0 {
                enemyNode.removeFromParent()
            } else {
                // Update HP Label
                if let hpText = enemyNode.childNode(withName: "hpText") as? SKLabelNode {
                    hpText.text = tierLabel(max(hpComp.currentHP, 0))
                }
                // Update Health Bar Width and Color
                if let bar = enemyNode.childNode(withName: "//hpBar") as? SKSpriteNode {
                    let pct = max(hpComp.currentHP / hpComp.maxHP, 0)
                    bar.size.width = 38 * pct
                    bar.color = pct > 0.5 ? .green : pct > 0.25 ? .yellow : .red
                }
            }
        }
        
        // ==========================================
        // 3. ENEMY REACHES PLAYER OR BASE (GAME OVER)
        // ==========================================
        if masks == (PhysicsCategory.player | PhysicsCategory.enemy) || masks == (PhysicsCategory.base | PhysicsCategory.enemy) {
            onPlayerHitEnemy?()
        }
    }
    
    // MARK: - Math Helpers
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
    
    private func tierLabel(_ hp: CGFloat) -> String {
        if hp >= 1_000 { return String(format: "%gk", hp / 1_000) }
        return String(format: "%.0f", hp)
    }
}
