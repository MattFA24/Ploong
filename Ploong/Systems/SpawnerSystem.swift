//
//  SpawnerSystem.swift
//  Ploong
//
//  Created by Matthew Fernando Anggrian on 12/05/26.
//


import GameplayKit

final class SpawnerSystem {
    private var timeSinceLastSpawn: TimeInterval = 0
    private var waveCount = 0
    var timeSurvived: TimeInterval = 0
    var optimalPower: CGFloat = 10
    
    func update(deltaTime seconds: TimeInterval, renderSystem: RenderSystem, sceneSize: CGSize) {
        timeSurvived += seconds
        timeSinceLastSpawn += seconds
        
        // 4.0 is GameConstants.spawnInterval
        if timeSinceLastSpawn >= 4.0 {
            timeSinceLastSpawn = 0
            spawnWave(renderSystem: renderSystem, size: sceneSize)
        }
    }
    
    private func spawnWave(renderSystem: RenderSystem, size: CGSize) {
        let waveID = waveCount
        waveCount += 1
        
        // For brevity, I'm mocking your basic gate spawn here.
        // You can copy your exact `makeGate` math logic here from the monolithic file!
        let gateDataTop = GateComponent(type: .add, value: 50, text: "+", waveID: waveID, lane: 1)
        let gateTop = GateEntity(position: CGPoint(x: size.width + 60, y: size.height/2 + GameConstants.laneGap/2), gateData: gateDataTop)
        
        renderSystem.addEntity(gateTop)
        scrollOff(node: gateTop.component(ofType: RenderComponent.self)!.node, width: size.width)
        
        // Spawn Enemy logic goes here (same as monolithic file, just wrap in EnemyEntity and pass to renderSystem.addEntity)
    }
    
    private func scrollOff(node: SKNode, width: CGFloat) {
        let dist = width + 700
        node.run(.sequence([
            .moveBy(x: -dist, y: 0, duration: Double(dist / GameConstants.objectSpeed)),
            .removeFromParent()
        ]))
    }
}