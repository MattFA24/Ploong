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
        
        // Triggers the foam and characters to pop UP when entering the menu
        BackgroundManager.shared.setOrnamentsVisible(true)
    }

    private func buildLayout() {
        // Setup the endless tiled background (affected by brightness)
        // and the ornament container (foam + characters @ full brightness)
        BackgroundManager.shared.setupBackground(in: self)
        
        AudioManager.shared.playMenuBgm()

        // 1. Logo
        let title = SKSpriteNode(imageNamed: "menu_logo")
        title.position = CGPoint(x: size.width * 0.5, y: size.height * 0.80)
        title.zPosition = 10
        scaleSprite(title, maxWidth: size.width * 0.7, maxHeight: size.height * 0.2)
        addChild(title)

        // 2. Highscore
        let highscore = SKLabelNode(fontNamed: "AvenirNext-Bold")
        highscore.text = "High score : 100.000"
        highscore.fontSize = 22
        highscore.fontColor = .black
        highscore.verticalAlignmentMode = .center
        highscore.position = CGPoint(x: size.width * 0.5, y: size.height * 0.68)
        highscore.zPosition = 10
        addChild(highscore)

        // 3. Play Button (The most prominent UI element)
        let playButton = SKSpriteNode(imageNamed: "play_button")
        playButton.name = "play_button"
        playButton.position = CGPoint(x: size.width * 0.5, y: size.height * 0.50)
        playButton.zPosition = 10
        scaleSprite(playButton, maxWidth: size.width * 0.55, maxHeight: size.height * 0.18)
        addChild(playButton)

        // 4. Secondary Buttons
        let smallBtnWidth = size.width * 0.45
        let smallBtnHeight = size.height * 0.08

        let settingsButton = SKSpriteNode(imageNamed: "settings_button")
        settingsButton.name = "settings_button"
        settingsButton.position = CGPoint(x: size.width * 0.5, y: size.height * 0.35)
        settingsButton.zPosition = 10
        scaleSprite(settingsButton, maxWidth: smallBtnWidth, maxHeight: smallBtnHeight)
        addChild(settingsButton)

        let characterButton = SKSpriteNode(imageNamed: "characters_button")
        characterButton.name = "characters_button"
        characterButton.position = CGPoint(x: size.width * 0.5, y: size.height * 0.25)
        characterButton.zPosition = 10
        scaleSprite(characterButton, maxWidth: smallBtnWidth, maxHeight: smallBtnHeight)
        addChild(characterButton)
        
        // 5. Info Button
        let infoButton = SKSpriteNode(imageNamed: "info_button")
        infoButton.name = "info_button"
        infoButton.position = CGPoint(x: size.width * 0.92, y: size.height * 0.92)
        infoButton.zPosition = 10
        scaleSprite(infoButton, maxWidth: 45, maxHeight: 45)
        addChild(infoButton)
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
        // Pop down ornaments before the scene transition
        BackgroundManager.shared.setOrnamentsVisible(false)
        
        let wait = SKAction.wait(forDuration: 0.25)
        let transition = SKAction.run { [weak self] in
            guard let self = self else { return }
            switch action {
            case .play:
                self.presentCalibration()
            case .character:
                self.presentCharacters()
            case .settings:
                self.presentSettings()
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
