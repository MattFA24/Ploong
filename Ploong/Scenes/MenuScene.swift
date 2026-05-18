//
//  MenuScene.swift
//  Ploong
//
//  Created by Matthew Fernando Anggrian on 11/05/26.
//

import SpriteKit

final class MenuScene: SKScene {
    fileprivate enum MenuAction: String {
        case play
        case character
        case settings
    }

    private var didSetupLayout = false

    override func sceneDidLoad() {
        super.sceneDidLoad()
        backgroundColor = .white
    }

    override func didMove(to view: SKView) {
        super.didMove(to: view)

        if !didSetupLayout {
            didSetupLayout = true
            buildLayout()
        }
        
        // Ensure ornaments pop UP when entering the menu
        BackgroundManager.shared.setOrnamentsVisible(true)
    }

    private func buildLayout() {
        // Setup the endless tiled background and the ornament container
        BackgroundManager.shared.setupBackground(in: self)
        
        AudioManager.shared.playMenuBgm()

        // 1. Logo Position (Increased from 0.65/0.22 to 0.75/0.28)
        let titleTexture = SKTexture(imageNamed: "menu_logo")
        titleTexture.filteringMode = .nearest
        let title = SKSpriteNode(texture: titleTexture)
        title.position = CGPoint(x: size.width * 0.5, y: size.height * 0.78)
        title.zPosition = 10
        scaleSprite(title, maxWidth: size.width * 0.75, maxHeight: size.height * 0.28)
        addChild(title)

        let highscore = SKLabelNode(fontNamed: "AvenirNext-Medium")
        let savedHighScore = UserDefaults.standard.integer(forKey: "HighScore")
        highscore.text = "HIGHSCORE: \(savedHighScore)"
        highscore.fontSize = 26
        highscore.fontColor = .black
        highscore.verticalAlignmentMode = .center
        highscore.position = CGPoint(x: size.width * 0.5, y: size.height * 0.62)
        highscore.zPosition = 10
        addChild(highscore)

        // 3. Play Button (Increased from 0.45/0.18 to 0.55/0.22)
        let playTexture = SKTexture(imageNamed: "play_button")
        playTexture.filteringMode = .nearest
        let playButton = SKSpriteNode(texture: playTexture)
        playButton.name = "play_button"
        playButton.position = CGPoint(x: size.width * 0.5, y: size.height * 0.45)
        playButton.zPosition = 10
        scaleSprite(playButton, maxWidth: size.width * 0.55, maxHeight: size.height * 0.22)
        addChild(playButton)

        // 4. Characters Button (Increased from 0.42/0.08 to 0.50/0.10)
        let charTexture = SKTexture(imageNamed: "characters_button")
        charTexture.filteringMode = .nearest
        let characterButton = SKSpriteNode(texture: charTexture)
        characterButton.name = "characters_button"
        characterButton.position = CGPoint(x: size.width * 0.5, y: size.height * 0.28)
        characterButton.zPosition = 10
        scaleSprite(characterButton, maxWidth: size.width * 0.50, maxHeight: size.height * 0.098)
        addChild(characterButton)

        // 5. Info Button (Increased from 45 to 55)
        let infoTexture = SKTexture(imageNamed: "info_button")
        infoTexture.filteringMode = .nearest
        let infoButton = SKSpriteNode(texture: infoTexture)
        infoButton.name = "info_button"
        infoButton.position = CGPoint(x: size.width * 0.08, y: size.height * 0.92)
        infoButton.zPosition = 10
        scaleSprite(infoButton, maxWidth: 55, maxHeight: 55)
        addChild(infoButton)
        
        // 6. Settings Button (Increased from 45 to 55)
        let settingsTexture = SKTexture(imageNamed: "settings_button")
        settingsTexture.filteringMode = .nearest
        let settingsButton = SKSpriteNode(texture: settingsTexture)
        settingsButton.name = "settings_button"
        settingsButton.position = CGPoint(x: size.width * 0.92, y: size.height * 0.92)
        settingsButton.zPosition = 10
        scaleSprite(settingsButton, maxWidth: 55, maxHeight: 55)
        addChild(settingsButton)
    }

    private func scaleSprite(_ sprite: SKSpriteNode, maxWidth: CGFloat, maxHeight: CGFloat) {
        guard sprite.size.width > 0, sprite.size.height > 0 else { return }
        let scale = min(maxWidth / sprite.size.width, maxHeight / sprite.size.height)
        sprite.setScale(scale)
    }

    override func mouseDown(with event: NSEvent) {
        let location = event.location(in: self)
        handleSelection(at: location)
    }

    private func handleSelection(at location: CGPoint) {
        let nodesAtPoint = nodes(at: location)

        if nodesAtPoint.contains(where: { $0.name == "play_button" }) {
            route(.play)
        } else if nodesAtPoint.contains(where: { $0.name == "characters_button" }) {
            route(.character)
        } else if nodesAtPoint.contains(where: { $0.name == "settings_button" }) {
            route(.settings)
        }
    }

    private func route(_ action: MenuAction) {
        BackgroundManager.shared.setOrnamentsVisible(false)
        
        let wait = SKAction.wait(forDuration: 0.25)
        let transition = SKAction.run { [weak self] in
            guard let self = self else { return }
            switch action {
            case .play: self.presentCalibration()
            case .character: self.presentCharacters()
            case .settings: self.presentSettings()
            }
        }
        self.run(SKAction.sequence([wait, transition]))
    }

    private func presentCalibration() {
        guard let view = view else { return }
        AudioManager.shared.stopMenuBgm()
        let scene = CalibrationScene(size: size)
        scene.scaleMode = scaleMode
        view.presentScene(scene)
    }

    private func presentCharacters() {
        guard let view = view else { return }
        let scene = CharactersScene(size: size)
        scene.scaleMode = scaleMode
        view.presentScene(scene)
    }

    private func presentSettings() {
        guard let view = view else { return }
        let scene = SettingsScene(size: size)
        scene.scaleMode = scaleMode
        view.presentScene(scene)
    }
}
