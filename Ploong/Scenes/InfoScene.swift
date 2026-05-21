import SpriteKit

final class InfoScene: SKScene {
    private var didSetupLayout = false
    
    override func sceneDidLoad() {
        super.sceneDidLoad()
        backgroundColor = .clear
    }
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        if !didSetupLayout {
            didSetupLayout = true
            buildLayout()
        }
        
        BackgroundManager.shared.setupBackground(in: self)
        BackgroundManager.shared.setOrnamentsVisible(false, animated: false)
    }
    
    private func buildLayout() {
        // MARK: - Modal
        
        let modalTexture = SKTexture(imageNamed: "modal_window")
        modalTexture.filteringMode = .nearest
        
        let modal = SKSpriteNode(texture: modalTexture)
        modal.position = CGPoint(x: size.width * 0.5,
                                 y: size.height * 0.5)
        modal.zPosition = 1
        
        let modalScale = (size.width * 0.85) / modal.size.width
        modal.setScale(modalScale)
        
        addChild(modal)
        
        let modalContentWidth = modal.size.width / modal.xScale
        let modalContentHeight = modal.size.height / modal.yScale
        
        // MARK: - Close Button
        
        let closeTexture = SKTexture(imageNamed: "close_button")
        closeTexture.filteringMode = .nearest
        
        let closeButton = SKSpriteNode(texture: closeTexture)
        closeButton.name = "closeButton"
        closeButton.position = CGPoint(
            x: -modalContentWidth * 0.445,
            y: modalContentHeight * 0.405
        )
        closeButton.zPosition = 2
        
        modal.addChild(closeButton)
        
        // MARK: - Title
        
        let titleLabel = SKLabelNode(fontNamed: GameConstants.fontName)
        titleLabel.text = "Attribution"
        titleLabel.fontSize = 38
        titleLabel.fontColor = SKColor(
            red: 0.02,
            green: 0.12,
            blue: 0.15,
            alpha: 1
        )
        titleLabel.position = CGPoint(
            x: 0,
            y: modalContentHeight * 0.30
        )
        titleLabel.horizontalAlignmentMode = .center
        titleLabel.verticalAlignmentMode = .center
        titleLabel.zPosition = 2
        
        modal.addChild(titleLabel)
        
        // MARK: - Left Column
        
        let leftX = -modalContentWidth * 0.27
        var leftY = modalContentHeight * 0.12
        
        let leftColumn: [(String, CGFloat, String, CGFloat)] = [
            ("Font Credits", 24, GameConstants.fontName, 34),
            
            ("Grape Soda by jeti", 20, GameConstants.fontName, 22),
            ("Licensed under CC BY 4.0", 15, GameConstants.fontName, 20),
            ("https://creativecommons.org/licenses/by/4.0/", 11, GameConstants.fontName, 18),
            ("https://fontenddev.com/fonts/grape-soda/", 11, GameConstants.fontName, 38),
            
            ("EAS VHS by rurr", 20, GameConstants.fontName, 22),
            ("https://rurr.itch.io/eas-vhs", 11, GameConstants.fontName, 0)
        ]
        
        for line in leftColumn {
            let label = SKLabelNode(fontNamed: line.2)
            label.text = line.0
            label.fontSize = line.1
            
            // Warna teks utama hitam
            if line.1 >= 15 {
                label.fontColor = .black
            } else {
                // Warna link abu kebiruan
                label.fontColor = SKColor(
                    red: 0.32,
                    green: 0.42,
                    blue: 0.45,
                    alpha: 1
                )
            }
            
            label.horizontalAlignmentMode = .left
            label.verticalAlignmentMode = .top
            
            label.position = CGPoint(x: leftX, y: leftY)
            label.zPosition = 2
            
            modal.addChild(label)
            
            leftY -= line.3
        }
        
        // MARK: - Right Column
        
        let rightX = modalContentWidth * 0.03
        var rightY = modalContentHeight * 0.12
        
        let rightColumn: [(String, CGFloat, String, CGFloat)] = [
            ("Music Credits", 24, GameConstants.fontName, 34),
            
            ("\"Pixel Paradise\" by kissan4", 20, GameConstants.fontName, 22),
            ("https://pixabay.com/music/video-games-pixel-paradise-358340/", 11, GameConstants.fontName, 42),
            
            ("\"8 Bit Win\" by HeatleyBros", 20, GameConstants.fontName, 22),
            ("https://youtu.be/wsrQogUxOIA", 11, GameConstants.fontName, 0)
        ]
        
        for line in rightColumn {
            let label = SKLabelNode(fontNamed: line.2)
            label.text = line.0
            label.fontSize = line.1
            
            if line.1 >= 15 {
                label.fontColor = .black
            } else {
                label.fontColor = SKColor(
                    red: 0.32,
                    green: 0.42,
                    blue: 0.45,
                    alpha: 1
                )
            }
            
            label.horizontalAlignmentMode = .left
            label.verticalAlignmentMode = .top
            
            label.position = CGPoint(x: rightX, y: rightY)
            label.zPosition = 2
            
            modal.addChild(label)
            
            rightY -= line.3
        }
    }
    
    // MARK: - Input Handling
    
    override func mouseDown(with event: NSEvent) {
        let location = event.location(in: self)
        let touchedNodes = nodes(at: location)
        
        if touchedNodes.contains(where: { $0.name == "closeButton" }) {
            presentMenu()
            return
        }
    }
    
    private func presentMenu() {
        guard let view = view else { return }
        
        let scene = MenuScene(size: size)
        scene.scaleMode = scaleMode
        
        view.presentScene(scene)
    }
}
