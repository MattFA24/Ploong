//
//  BackgroundManager.swift
//  Ploong
//
//  Created by Farrell Sudjatmiko on 13/05/26.
//

import SpriteKit

// MARK: - Components
/// Defines the data needed for a scrolling background layer
struct BackgroundComponent {
    let textureName: String
    let scrollSpeed: CGFloat
    let zPosition: CGFloat
    let overlap: CGFloat = 2.0 // Fixed 2-pixel overlap to prevent gaps
}

// MARK: - Background Manager (System)
final class BackgroundManager {
    static let shared = BackgroundManager()
    
    private var backgroundNodes: [SKSpriteNode] = []
    private var currentBrightness: CGFloat = 0.5
    
    private init() {}

    /// Main entry point to setup the background in any SKScene
    func setupBackground(in scene: SKScene, textureName: String = "main_menu_bg") {
        // Clear existing nodes if switching scenes
        backgroundNodes.removeAll()
        
        let component = BackgroundComponent(
            textureName: textureName,
            scrollSpeed: 18.0,
            zPosition: -10
        )
        
        createScrollingLayer(in: scene, with: component)
        applyBrightness(loadBrightness())
    }
    
    private func createScrollingLayer(in scene: SKScene, with component: BackgroundComponent) {
        let texture = SKTexture(imageNamed: component.textureName)
        let textureSize = texture.size()
        
        guard textureSize.width > 0, textureSize.height > 0 else { return }

        // Calculate scale to fill screen
        let scale = max(scene.size.width / textureSize.width, scene.size.height / textureSize.height)
        let scaledSize = CGSize(width: textureSize.width * scale, height: textureSize.height * scale)
        
        // Add overlap to the width to prevent the 1px flickering gap
        let finalSize = CGSize(width: scaledSize.width + component.overlap, height: scaledSize.height)
        
        let duration = TimeInterval(scaledSize.width / component.scrollSpeed)
        
        // Sync start time across instances using systemUptime
        let elapsed = CGFloat(ProcessInfo.processInfo.systemUptime)
        let offset = (elapsed * component.scrollSpeed).truncatingRemainder(dividingBy: scaledSize.width)

        for i in 0...1 {
            let node = SKSpriteNode(texture: texture, size: finalSize)
            node.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            node.zPosition = component.zPosition
            
            let centerX = scene.size.width * 0.5
            let centerY = scene.size.height * 0.5
            
            // Position nodes relative to each other with overlap
            let startX = centerX + offset - (CGFloat(i) * scaledSize.width)
            node.position = CGPoint(x: startX, y: centerY)
            
            // Seamless Loop Animation
            let move = SKAction.moveBy(x: scaledSize.width, y: 0, duration: duration)
            let reset = SKAction.moveBy(x: -scaledSize.width, y: 0, duration: 0)
            let sequence = SKAction.sequence([move, reset])
            node.run(SKAction.repeatForever(sequence))
            
            scene.addChild(node)
            backgroundNodes.append(node)
        }
    }
    
    // MARK: - Brightness Control
    func applyBrightness(_ value: CGFloat) {
        currentBrightness = max(0, min(1, value))
        let blendFactor = 1 - currentBrightness
        
        for node in backgroundNodes {
            node.color = .black
            node.colorBlendFactor = blendFactor
        }
    }
    
    func loadBrightness() -> CGFloat {
        let stored = UserDefaults.standard.object(forKey: "backgroundBrightness") as? NSNumber
        return CGFloat(stored?.doubleValue ?? 0.5)
    }
    
    func saveBrightness(_ value: CGFloat) {
        UserDefaults.standard.set(value, forKey: "backgroundBrightness")
        applyBrightness(value)
    }
}
