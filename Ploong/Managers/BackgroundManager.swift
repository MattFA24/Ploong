import SpriteKit

// MARK: - ECS Components
struct BackgroundComponent {
    let textureName: String
    let scrollSpeed: CGFloat
    let zPosition: CGFloat
    let overlap: CGFloat = 2.0
}

final class BackgroundManager {
    static let shared = BackgroundManager()
    
    private var backgroundNodes: [SKSpriteNode] = []
    private var ornamentContainer: SKNode?
    
    // MARK: - Tweakable Foam Settings (Ornament 1)
    private let foamHeightMultiplier: CGFloat = 0.3
    private let foamYOffset: CGFloat = 0.0
    // Increased overlap to ensure nodes "glue" together better
    private let foamOverlap: CGFloat = 1
    
    // MARK: - Tweakable Character Settings (Ornament 2)
    private let ornament2ScaleOverride: CGFloat = 1.0
    private let ornament2XOffset: CGFloat = 50.0
    private let ornament2YOffset: CGFloat = 0.0
    
    // MARK: - Background Tile Settings
    private let backgroundOverlap: CGFloat = 2.0

    private init() {}

    func setupBackground(in scene: SKScene) {
        // Stop any current actions and clear arrays to prevent memory leaks or logic ghosting
        backgroundNodes.forEach { $0.removeAllActions(); $0.removeFromParent() }
        backgroundNodes.removeAll()
        ornamentContainer?.removeAllActions()
        ornamentContainer?.removeFromParent()
        
        // 1. Blue Tiles Background
        let tileComp = BackgroundComponent(
            textureName: "main_menu_bg",
            scrollSpeed: 18.0,
            zPosition: -10
        )
        createScrollingLayer(in: scene, with: tileComp, addToContainer: false, overlapOverride: backgroundOverlap)
        
        // 2. Ornament Container
        let container = SKNode()
        container.name = "ornamentContainer"
        container.zPosition = -5
        scene.addChild(container)
        self.ornamentContainer = container
        
        // 3. Ornament 2: Characters (Behind foam)
        let staticArt = SKSpriteNode(imageNamed: "menu_ornament_2")
        let staticScale = scene.size.width / staticArt.size.width
        staticArt.setScale(staticScale * ornament2ScaleOverride)
        staticArt.anchorPoint = CGPoint(x: 0.5, y: 0)
        staticArt.position = CGPoint(x: (scene.size.width * 0.5) + ornament2XOffset, y: ornament2YOffset)
        staticArt.zPosition = 1
        container.addChild(staticArt)
        
        // 4. Ornament 1: Foam (In front of characters)
        let foamComp = BackgroundComponent(
            textureName: "menu_ornament_1",
            scrollSpeed: 8.0,
            zPosition: 5
        )
        createScrollingLayer(in: scene, with: foamComp, addToContainer: true, overlapOverride: foamOverlap)
        
        applyBrightness(loadBrightness())
    }
    
    private func createScrollingLayer(in scene: SKScene, with component: BackgroundComponent, addToContainer: Bool, overlapOverride: CGFloat) {
        let texture = SKTexture(imageNamed: component.textureName)
        let textureSize = texture.size()
        guard textureSize.width > 0 else { return }

        var finalSize: CGSize
        if component.textureName == "menu_ornament_1" {
            let targetHeight = scene.size.height * foamHeightMultiplier
            let aspectRatio = textureSize.width / textureSize.height
            let targetWidth = targetHeight * aspectRatio
            // Ensure width covers the screen plus our glue overlap
            let finalWidth = max(targetWidth, scene.size.width) + overlapOverride
            finalSize = CGSize(width: finalWidth, height: targetHeight)
        } else {
            let scale = max(scene.size.width / textureSize.width, scene.size.height / textureSize.height)
            finalSize = CGSize(width: (textureSize.width * scale) + overlapOverride, height: textureSize.height * scale)
        }
        
        // LOOP MATH: The movement distance must be exactly the width of the node minus the overlap.
        // This makes the reset point invisible because node 3 will be exactly where node 1 was.
        let scrollDistance = finalSize.width - overlapOverride
        let duration = TimeInterval(scrollDistance / component.scrollSpeed)
        
        // Calculate the starting offset based on system time to keep things synced
        let elapsed = CGFloat(ProcessInfo.processInfo.systemUptime)
        let totalOffset = (elapsed * component.scrollSpeed).truncatingRemainder(dividingBy: scrollDistance)

        // Using 3 NODES for a perfect "handshake" loop.
        // This prevents the "blank space" gap entirely.
        for i in 0...2 {
            let node = SKSpriteNode(texture: texture, size: finalSize)
            node.anchorPoint = CGPoint(x: 0, y: 0) // Bottom-left anchoring
            node.zPosition = component.zPosition
            
            // Positioning node 'i' exactly one scrollDistance apart
            let startX = totalOffset - (CGFloat(i) * scrollDistance)
            let startY = (component.textureName == "menu_ornament_1") ? foamYOffset : 0
            node.position = CGPoint(x: startX, y: startY)
            
            // Move right by one scrollDistance, then snap back
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
    
    func setOrnamentsVisible(_ visible: Bool, animated: Bool = true) {
        guard let container = ornamentContainer else { return }
        let targetY: CGFloat = visible ? 0 : -600
        container.removeAllActions()
        if animated {
            let move = SKAction.moveTo(y: targetY, duration: 0.45)
            move.timingMode = .easeOut
            container.run(move)
        } else {
            container.position.y = targetY
        }
    }
    
    func applyBrightness(_ value: CGFloat) {
        let brightness = max(0, min(1, value))
        let blendFactor = 1 - brightness
        for node in backgroundNodes {
            node.color = .black
            node.colorBlendFactor = blendFactor
        }
        // Characters and Foam stay at full brightness
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
