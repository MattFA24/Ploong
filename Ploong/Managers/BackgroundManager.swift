//
//  BackgroundManager.swift
//  Ploong
//
//  Created by Matthew Fernando Anggrian on 11/05/26.
//

import SpriteKit

// MARK: - ECS Components
struct BackgroundComponent {
    let textureName: String
    let scrollSpeed: CGFloat
    let zPosition: CGFloat
    let overlap: CGFloat = 2.0
}

// MARK: - Background System (Manager)
final class BackgroundManager {
    static let shared = BackgroundManager()
    
    private var backgroundNodes: [SKSpriteNode] = []
    private var ornamentContainer: SKNode?
    
    // MARK: - Tweakable Menu Foam Settings (Ornament 1)
    private let foamHeightMultiplier: CGFloat = 0.3
    private let foamYOffset: CGFloat = 0.0
    private let foamOverlap: CGFloat = 10.0
    
    // MARK: - Tweakable Character Settings (Ornament 2)
    private let ornament2ScaleOverride: CGFloat = 1.0
    private let ornament2XOffset: CGFloat = 50.0
    private let ornament2YOffset: CGFloat = 0.0
    
    // MARK: - Background Tile Settings
    private let backgroundOverlap: CGFloat = 2.0

    private init() {
        // 🌟 PERBAIKAN: Mendaftarkan nilai default (100% terang) untuk pertama kali game dibuka
        UserDefaults.standard.register(defaults: [
            "backgroundBrightness": 1.0
        ])
    }

    /// Sets up the entire visual stack: Tiled Background -> Foam Parallax -> Static Art
    func setupBackground(in scene: SKScene) {
        backgroundNodes.forEach { $0.removeAllActions(); $0.removeFromParent() }
        backgroundNodes.removeAll()
        ornamentContainer?.removeAllActions()
        ornamentContainer?.removeFromParent()
        
        let isGameplay = scene is GameLoopScene
        
        // 1. Primary Tiled Background (Scrolls Left-to-Right in Main Menu)
        let tileComp = BackgroundComponent(
            textureName: isGameplay ? "game_bg" : "main_menu_bg",
            scrollSpeed: isGameplay ? 0.0 : 18.0,
            zPosition: -10
        )
        createScrollingLayer(in: scene, with: tileComp, addToContainer: false, overlapOverride: backgroundOverlap)
        
        // 2. Create the Ornament Container for "Pop" animations
        let container = SKNode()
        container.name = "ornamentContainer"
        container.zPosition = isGameplay ? 15 : -5
        scene.addChild(container)
        self.ornamentContainer = container
        
        // 3. Ornament 2: Characters/Hose (Only built on the Main Menu scene)
        if !isGameplay {
            let staticTexture = SKTexture(imageNamed: "menu_ornament_2")
            staticTexture.filteringMode = .nearest
            
            let staticArt = SKSpriteNode(texture: staticTexture)
            let baseScale = scene.size.width / staticArt.size.width
            staticArt.setScale(baseScale * ornament2ScaleOverride)
            staticArt.anchorPoint = CGPoint(x: 0.5, y: 0)
            staticArt.position = CGPoint(x: (scene.size.width * 0.5) + ornament2XOffset, y: ornament2YOffset)
            staticArt.zPosition = 1
            container.addChild(staticArt)
        }
        
        // 4. Ornament 1: Foam Parallax Layer (Configured to switch directions based on state)
        let activeScrollSpeed: CGFloat = isGameplay ? 45.0 : 8.0
        let activeFoamAsset = isGameplay ? "foam_ornament" : "menu_ornament_1"
        
        let foamComp = BackgroundComponent(
            textureName: activeFoamAsset,
            scrollSpeed: activeScrollSpeed,
            zPosition: 5
        )
        
        // 🌟 Terapkan setting kecerahan yang tersimpan saat scene dimuat
        createScrollingLayer(
            in: scene,
            with: foamComp,
            addToContainer: true,
            overlapOverride: foamOverlap
        )
        
        applyBrightness(loadBrightness())
    }
    
    private func createScrollingLayer(in scene: SKScene, with component: BackgroundComponent, addToContainer: Bool, overlapOverride: CGFloat) {
        // --- GAMEPLAY FOAM TWEAKABLES ---
        let gameFoamHeightMultiplier: CGFloat = 0.20
        let gameFoamYOffset: CGFloat = 0.0
        // --------------------------------
        
        let texture = SKTexture(imageNamed: component.textureName)
        texture.filteringMode = .nearest
        
        let textureSize = texture.size()
        guard textureSize.width > 0 else { return }

        var finalSize: CGSize
        var finalYOffset: CGFloat = 0.0
        
        // Check which asset type is loading to apply independent size & position logic
        if component.textureName == "foam_ornament" {
            let targetHeight = scene.size.height * gameFoamHeightMultiplier
            let aspectRatio = textureSize.width / textureSize.height
            let targetWidth = targetHeight * aspectRatio
            let finalWidth = max(targetWidth, scene.size.width) + overlapOverride
            finalSize = CGSize(width: finalWidth, height: targetHeight)
            finalYOffset = gameFoamYOffset
            
        } else if component.textureName == "menu_ornament_1" {
            let targetHeight = scene.size.height * foamHeightMultiplier
            let aspectRatio = textureSize.width / textureSize.height
            let targetWidth = targetHeight * aspectRatio
            let finalWidth = max(targetWidth, scene.size.width) + overlapOverride
            finalSize = CGSize(width: finalWidth, height: targetHeight)
            finalYOffset = foamYOffset
            
        } else {
            let scale = max(scene.size.width / textureSize.width, scene.size.height / textureSize.height)
            finalSize = CGSize(width: (textureSize.width * scale) + overlapOverride, height: textureSize.height * scale)
            finalYOffset = 0.0
        }
        
        let scrollDistance = finalSize.width - overlapOverride
        let duration = TimeInterval(scrollDistance / component.scrollSpeed)
        
        let elapsed = CGFloat(ProcessInfo.processInfo.systemUptime)
        let totalOffset = component.scrollSpeed > 0 ? (elapsed * component.scrollSpeed).truncatingRemainder(dividingBy: scrollDistance) : 0.0

        // Determine if this specific layer should scroll from Right-to-Left (e.g., gameplay foam)
        let isRightToLeft = (component.textureName == "foam_ornament")

        for i in 0...2 {
            let node = SKSpriteNode(texture: texture, size: finalSize)
            node.anchorPoint = CGPoint(x: 0, y: 0)
            node.zPosition = component.zPosition
            
            // Apply alternative coordinate layouts based on direction needs
            if isRightToLeft {
                // Spawn sequential nodes to the right of the screen viewport
                let startX = -totalOffset + (CGFloat(i) * scrollDistance)
                node.position = CGPoint(x: startX, y: finalYOffset)
                
                if component.scrollSpeed > 0 {
                    // Shift leftward by a negative factor, then instantly reset back to the right loop boundary
                    let move = SKAction.moveBy(x: -scrollDistance, y: 0, duration: duration)
                    let reset = SKAction.moveBy(x: scrollDistance, y: 0, duration: 0)
                    node.run(SKAction.repeatForever(SKAction.sequence([move, reset])))
                }
            } else {
                // Standard Left-to-Right scrolling math
                let startX = totalOffset - (CGFloat(i) * scrollDistance)
                node.position = CGPoint(x: startX, y: finalYOffset)
                
                if component.scrollSpeed > 0 {
                    let move = SKAction.moveBy(x: scrollDistance, y: 0, duration: duration)
                    let reset = SKAction.moveBy(x: -scrollDistance, y: 0, duration: 0)
                    node.run(SKAction.repeatForever(SKAction.sequence([move, reset])))
                }
            }
            
            if addToContainer {
                ornamentContainer?.addChild(node)
            } else {
                scene.addChild(node)
                backgroundNodes.append(node) // 🌟 MENYIMPAN NODE KE ARRAY
            }
        }
    }
    
    // MARK: - Animation Logic
    func setOrnamentsVisible(_ visible: Bool, animated: Bool = true) {
        guard let container = ornamentContainer else { return }
        
        let targetY: CGFloat = visible ? 0 : -650
        container.removeAllActions()
        
        if animated {
            let move = SKAction.moveTo(y: targetY, duration: 0.45)
            move.timingMode = .easeOut
            container.run(move)
        } else {
            container.position.y = targetY
        }
    }
    
    // MARK: - Brightness Logic
    func applyBrightness(_ value: CGFloat) {
        let brightness = max(0.0, min(1.0, value))
        let blendFactor = 1.0 - brightness
        
        // Dim the tiled background nodes (Bisa bekerja real-time karena node tersimpan di array!)
        for node in backgroundNodes {
            node.color = .black
            node.colorBlendFactor = blendFactor
        }
        
        ornamentContainer?.children.compactMap { $0 as? SKSpriteNode }.forEach {
            $0.colorBlendFactor = 0
            $0.color = .white
        }
    }
    
    // 🌟 PERBAIKAN: Fungsi Load dan Save diperbarui agar bersih dan responsif
    func loadBrightness() -> CGFloat {
        return CGFloat(UserDefaults.standard.float(forKey: "backgroundBrightness"))
    }
    
    func saveBrightness(_ value: CGFloat) {
        let clampedValue = max(0.0, min(1.0, value))
        UserDefaults.standard.set(clampedValue, forKey: "backgroundBrightness")
        
        // Terapkan langsung secara real-time
        applyBrightness(clampedValue)
    }
    
    // MARK: - Pause Logic
    func setPaused(_ paused: Bool) {
        // Pauses the tiled background layers
        for node in backgroundNodes {
            node.isPaused = paused
        }
        // Pauses the foam/ornament animations
        ornamentContainer?.isPaused = paused
    }
}
