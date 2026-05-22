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
                
        let titleTexture = SKTexture(imageNamed: "Attribution")
        titleTexture.filteringMode = .nearest // Menjaga pixel art tetap tajam
        
        let titleSprite = SKSpriteNode(texture: titleTexture)
        titleSprite.position = CGPoint(
            x: 0,
            y: modalContentHeight * 0.35 // Posisi Y tetap sama seperti sebelumnya
        )
        titleSprite.zPosition = 2
        
        titleSprite.setScale(0.8)
        
        modal.addChild(titleSprite)
        
        
        // MARK: - Data Kolom (Font, Music, SFX)
        
        let startY = modalContentHeight * 0.25
        
        // Kolom 1: Kiri (Font)
        let fontColumn: [(String, CGFloat, String, CGFloat)] = [
            ("Font Credits", 28, GameConstants.fontName, 60),
            
            ("Grape Soda by jeti", 22, GameConstants.fontName, 26),
            ("Licensed under CC BY 4.0", 16, GameConstants.fontName, 22),
            ("https://creativecommons.org/licenses/by/4.0/", 13, GameConstants.fontName, 20),
            ("https://fontenddev.com/fonts/grape-soda/", 13, GameConstants.fontName, 45),
            
            ("EAS VHS by rurr", 22, GameConstants.fontName, 26),
            ("https://rurr.itch.io/eas-vhs", 13, GameConstants.fontName, 0)
        ]
        
        // Kolom 2: Tengah (Music)
        let musicColumn: [(String, CGFloat, String, CGFloat)] = [
            ("Music Credits", 28, GameConstants.fontName, 60),
            
            ("\"Pixel Paradise\" by kissan4", 22, GameConstants.fontName, 26),
            ("https://pixabay.com/music/video-games-pixel-paradise-358340/", 13, GameConstants.fontName, 50),
            
            ("\"8 Bit Win\" by HeatleyBros", 22, GameConstants.fontName, 26),
            ("https://youtu.be/wsrQogUxOIA", 13, GameConstants.fontName, 0)
        ]
        
        // Kolom 3: Kanan (SFX)
        let sfxColumn: [(String, CGFloat, String, CGFloat)] = [
            ("SFX Credits", 28, GameConstants.fontName, 60),
            
            ("\"Coin Recieved\" by RibhavAgrawal", 22, GameConstants.fontName, 24),
            ("https://pixabay.com/sound-effects/film-special-effects-coin-recieved-230517/", 13, GameConstants.fontName, 45),
            
            ("\"Power Up\" by PoorArtistt", 22, GameConstants.fontName, 24),
            ("https://pixabay.com/sound-effects/film-special-effects-videogame-power-up-sound-effect-01-no-copyright-352863/", 13, GameConstants.fontName, 45),
            
            ("\"Power Off\" by DRAGON-STUDIO", 22, GameConstants.fontName, 24),
            ("https://pixabay.com/sound-effects/film-special-effects-power-off-386180/", 13, GameConstants.fontName, 45),
            
            ("\"Cartoon Jump\" by DRAGON-STUDIO", 22, GameConstants.fontName, 24),
            ("https://pixabay.com/sound-effects/film-special-effects-cartoon-jump-463196/", 13, GameConstants.fontName, 45),
            
            ("\"Cartoon Splat\" by Universfield", 22, GameConstants.fontName, 24),
            ("https://pixabay.com/sound-effects/film-special-effects-cartoon-splat-310479/", 13, GameConstants.fontName, 45),
            
            ("\"Diarrhea\" by Sound Effects Official", 22, GameConstants.fontName, 24),
            ("https://youtube.com/shorts/u18qxMF3ZOw?si=j1T9Wy6507Iv-hyq", 13, GameConstants.fontName, 0)
        ]
        
        // 🌟 PERBAIKAN: Menentukan batas lebar maksimum pembungkus (width) untuk masing-masing kolom
        let columns = [
            (x: -modalContentWidth * 0.45, width: modalContentWidth * 0.30, data: fontColumn),
            (x: -modalContentWidth * 0.12, width: modalContentWidth * 0.25, data: musicColumn),
            (x: modalContentWidth * 0.15, width: modalContentWidth * 0.31, data: sfxColumn)
        ]
        
        // MARK: - Label Generator
        
        // MARK: - Label Generator
        for col in columns {
            var currentY = startY
            
            for line in col.data {
                let label = SKLabelNode(fontNamed: line.2)
                label.text = line.0
                label.fontSize = line.1
                
                // 🌟 PERUBAHAN: Beri nama khusus jika ini adalah link
                if line.1 < 15 {
                    label.name = "url_\(line.0)" // Contoh: "url_https://..."
                    label.fontColor = SKColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1) // Warna biru link
                } else {
                    label.fontColor = .black
                }
                
                label.numberOfLines = 0
                label.preferredMaxLayoutWidth = col.width
                label.horizontalAlignmentMode = .left
                label.verticalAlignmentMode = .top
                label.position = CGPoint(x: col.x, y: currentY)
                label.zPosition = 2
                
                modal.addChild(label)
                
                let dynamicSpacing = max(line.3, label.frame.height + 6)
                currentY -= dynamicSpacing
            }
        }
    }
    
    // MARK: - Input Handling

    override func mouseDown(with event: NSEvent) {
        let location = event.location(in: self)
        let touchedNodes = nodes(at: location)
        
        // 1. Deteksi Tombol Close
        if touchedNodes.contains(where: { $0.name == "closeButton" }) {
            presentMenu()
            return
        }
        
        // 2. 🌟 Deteksi Klik pada Link
        if let linkNode = touchedNodes.first(where: { $0.name?.hasPrefix("url_") == true }) {
            if let urlString = linkNode.name?.replacingOccurrences(of: "url_", with: ""),
               let url = URL(string: urlString) {
                // Membuka link di browser default (Safari/Chrome)
                NSWorkspace.shared.open(url)
            }
        }
    }
    
    private func presentMenu() {
        guard let view = view else { return }
        
        let scene = MenuScene(size: size)
        scene.scaleMode = scaleMode
        
        view.presentScene(scene)
    }
}
