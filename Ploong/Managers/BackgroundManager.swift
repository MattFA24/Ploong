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
    
    // MARK: - Tweakable Foam Settings (Ornament 1)
    private let foamHeightMultiplier: CGFloat = 0.3
    private let foamYOffset: CGFloat = 0.0
    private let foamOverlap: CGFloat = 10.0
    
    // MARK: - Tweakable Character Settings (Ornament 2)
    private let ornament2ScaleOverride: CGFloat = 1.0
    private let ornament2XOffset: CGFloat = 50.0
    private let ornament2YOffset: CGFloat = 0.0
    
    // MARK: - Background Tile Settings
    private let backgroundOverlap: CGFloat = 2.0

    private init() {}

    /// Sets up the entire visual stack: Tiled Background -> Foam Parallax -> Static Art
    func setupBackground(in scene: SKScene) {
        // Clear previous state to prevent node stacking and memory leaks
        backgroundNodes.forEach { $0.removeAllActions(); $0.removeFromParent() }
        backgroundNodes.removeAll()
        ornamentContainer?.removeAllActions()
        ornamentContainer?.removeFromParent()
        
        // 1. Primary Tiled Background (Affected by brightness)
        let tileComp = BackgroundComponent(
            textureName: "main_menu_bg",
            scrollSpeed: 18.0,
            zPosition: -10
        )
        createScrollingLayer(in: scene, with: tileComp, addToContainer: false, overlapOverride: backgroundOverlap)
        
        // 2. Create the Ornament Container for "Pop" animations
        let container = SKNode()
        container.name = "ornamentContainer"
        container.zPosition = -5
        scene.addChild(container)
        self.ornamentContainer = container
        
        // 3. Ornament 2: Characters/Hose (Behind foam, Nearest Neighbor filtering)
        let staticTexture = SKTexture(imageNamed: "menu_ornament_2")
        staticTexture.filteringMode = .nearest
        
        let staticArt = SKSpriteNode(texture: staticTexture)
        let baseScale = scene.size.width / staticArt.size.width
        staticArt.setScale(baseScale * ornament2ScaleOverride)
        staticArt.anchorPoint = CGPoint(x: 0.5, y: 0)
        staticArt.position = CGPoint(x: (scene.size.width * 0.5) + ornament2XOffset, y: ornament2YOffset)
        staticArt.zPosition = 1
        container.addChild(staticArt)
        
        // 4. Ornament 1: Foam (In front of characters, Nearest Neighbor filtering)
        let foamComp = BackgroundComponent(
            textureName: "menu_ornament_1",
            scrollSpeed: 8.0,
            zPosition: 5
        )
        createScrollingLayer(in: scene, with: foamComp, addToContainer: true, overlapOverride: foamOverlap)
        
        // Restore current brightness setting
        applyBrightness(loadBrightness())
    }
    
    private func createScrollingLayer(in scene: SKScene, with component: BackgroundComponent, addToContainer: Bool, overlapOverride: CGFloat) {
        let texture = SKTexture(imageNamed: component.textureName)
        // CRITICAL: Nearest Neighbor prevents pixel art blurriness
        texture.filteringMode = .nearest
        
        let textureSize = texture.size()
        guard textureSize.width > 0 else { return }

        var finalSize: CGSize
        if component.textureName == "menu_ornament_1" {
            // Scale based on height while preserving Aspect Ratio
            let targetHeight = scene.size.height * foamHeightMultiplier
            let aspectRatio = textureSize.width / textureSize.height
            let targetWidth = targetHeight * aspectRatio
            let finalWidth = max(targetWidth, scene.size.width) + overlapOverride
            finalSize = CGSize(width: finalWidth, height: targetHeight)
        } else {
            // Scale background tiles to fill the screen
            let scale = max(scene.size.width / textureSize.width, scene.size.height / textureSize.height)
            finalSize = CGSize(width: (textureSize.width * scale) + overlapOverride, height: textureSize.height * scale)
        }
        
        // The scroll distance is the width of one node minus the overlap "glue"
        let scrollDistance = finalSize.width - overlapOverride
        let duration = TimeInterval(scrollDistance / component.scrollSpeed)
        
        // Sync using system uptime to maintain continuity across scenes
        let elapsed = CGFloat(ProcessInfo.processInfo.systemUptime)
        let totalOffset = (elapsed * component.scrollSpeed).truncatingRemainder(dividingBy: scrollDistance)

        // Using 3 NODES for a perfect "handshake" loop to prevent blank space gaps
        for i in 0...2 {
            let node = SKSpriteNode(texture: texture, size: finalSize)
            node.anchorPoint = CGPoint(x: 0, y: 0) // Bottom-left anchoring for predictable math
            node.zPosition = component.zPosition
            
            // Positioning node 'i' exactly one scrollDistance apart
            let startX = totalOffset - (CGFloat(i) * scrollDistance)
            let startY = (component.textureName == "menu_ornament_1") ? foamYOffset : 0
            node.position = CGPoint(x: startX, y: startY)
            
            // Handshake animation: move right by one distance, then snap back
            let move = SKAction.moveBy(x: scrollDistance, y: 0, duration: duration)
            let reset = SKAction.moveBy(x: -scrollDistance, y: 0, duration: 0)
            node.run(SKAction.repeatForever(SKAction.sequence([move, reset])))
            
            if addToContainer {
                ornamentContainer?.addChild(node)
            } else {
                scene.addChild(node)
                backgroundNodes.append(node)
            }
        }
    }
    
    // MARK: - Animation Logic
    
    /// Animates the foam and characters up or down
    func setOrnamentsVisible(_ visible: Bool, animated: Bool = true) {
        guard let container = ornamentContainer else { return }
        
        let targetY: CGFloat = visible ? 0 : -650 // Pushed below the screen to hide
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
    
    /// Only dims the background tiles. Ornaments and UI remain at full brightness.
    func applyBrightness(_ value: CGFloat) {
        let brightness = max(0, min(1, value))
        let blendFactor = 1 - brightness
        
        // Dim the tiled background nodes
        for node in backgroundNodes {
            node.color = .black
            node.colorBlendFactor = blendFactor
        }
        
        // Reset/Maintain ornaments at full brightness
        ornamentContainer?.children.compactMap { $0 as? SKSpriteNode }.forEach {
            $0.colorBlendFactor = 0
            $0.color = .white
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
