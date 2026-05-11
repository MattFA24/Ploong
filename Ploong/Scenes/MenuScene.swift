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
    private var backgroundNodes: [SKSpriteNode] = []

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
    }

    private func buildLayout() {
        addScrollingBackground()
        applyBackgroundBrightness(loadBackgroundBrightness())
        AudioManager.shared.playMenuBgm()

        let title = SKSpriteNode(imageNamed: "menu_logo")
        title.position = CGPoint(x: size.width * 0.5, y: size.height * 0.78)
        title.zPosition = 1
        if title.size.width > 0, title.size.height > 0 {
            let maxWidth = size.width * 0.6
            let maxHeight = size.height * 0.18
            let scale = min(maxWidth / title.size.width, maxHeight / title.size.height)
            title.setScale(scale)
        }
        addChild(title)

        let highscore = SKLabelNode(fontNamed: "AvenirNext-Medium")
        highscore.text = "HIGHSCORE: XXX"
        highscore.fontSize = 26
        highscore.fontColor = .black
        highscore.verticalAlignmentMode = .center
        highscore.position = CGPoint(x: size.width * 0.5, y: size.height * 0.68)
        addChild(highscore)

        let buttonMaxWidth = size.width * 0.36
        let buttonMaxHeight = size.height * 0.09

        let playButton = SKSpriteNode(imageNamed: "play_button")
        playButton.name = "play_button"
        playButton.position = CGPoint(x: size.width * 0.5, y: size.height * 0.50)
        playButton.zPosition = 1
        scaleSprite(playButton, maxWidth: size.width * 0.70, maxHeight: size.height * 0.2)
        addChild(playButton)

        let characterButton = SKSpriteNode(imageNamed: "characters_button")
        characterButton.name = "characters_button"
        characterButton.position = CGPoint(x: size.width * 0.5, y: size.height * 0.34)
        characterButton.zPosition = 1
        scaleSprite(characterButton, maxWidth: buttonMaxWidth, maxHeight: buttonMaxHeight)
        addChild(characterButton)

        let settingsButton = SKSpriteNode(imageNamed: "settings_button")
        settingsButton.name = "settings_button"
        settingsButton.position = CGPoint(x: size.width * 0.5, y: size.height * 0.24)
        settingsButton.zPosition = 1
        scaleSprite(settingsButton, maxWidth: buttonMaxWidth, maxHeight: buttonMaxHeight)
        addChild(settingsButton)
    }

    private func scaleSprite(_ sprite: SKSpriteNode, maxWidth: CGFloat, maxHeight: CGFloat) {
        guard sprite.size.width > 0, sprite.size.height > 0 else {
            return
        }

        let scale = min(maxWidth / sprite.size.width, maxHeight / sprite.size.height)
        sprite.setScale(scale)
    }

    private func addScrollingBackground() {
        let texture = SKTexture(imageNamed: "main_menu_bg")
        let textureSize = texture.size()
        guard textureSize.width > 0, textureSize.height > 0 else {
            return
        }

        let speed: CGFloat = 18
        let scale = max(size.width / textureSize.width, size.height / textureSize.height)
        let scaledSize = CGSize(width: textureSize.width * scale, height: textureSize.height * scale)
        let duration = TimeInterval(scaledSize.width / speed)

        let elapsed = CGFloat(ProcessInfo.processInfo.systemUptime)
        let offset = (elapsed * speed).truncatingRemainder(dividingBy: scaledSize.width)

        let bg1 = SKSpriteNode(texture: texture, size: scaledSize)
        let bg2 = SKSpriteNode(texture: texture, size: scaledSize)

        let centerX = size.width * 0.5
        let centerY = size.height * 0.5
        bg1.position = CGPoint(x: centerX + offset, y: centerY)
        bg2.position = CGPoint(x: bg1.position.x - scaledSize.width, y: centerY)

        bg1.zPosition = -2
        bg2.zPosition = -2

        let move = SKAction.moveBy(x: scaledSize.width, y: 0, duration: duration)
        let reset = SKAction.moveBy(x: -scaledSize.width, y: 0, duration: 0)
        let loop = SKAction.repeatForever(SKAction.sequence([move, reset]))

        bg1.run(loop)
        bg2.run(loop)

        addChild(bg1)
        addChild(bg2)
        backgroundNodes = [bg1, bg2]
    }

    private func applyBackgroundBrightness(_ value: CGFloat) {
        let clamped = max(0, min(1, value))
        for node in backgroundNodes {
            node.alpha = 1
            node.color = .black
            node.colorBlendFactor = 1 - clamped
        }
    }

    private func loadBackgroundBrightness() -> CGFloat {
        let stored = UserDefaults.standard.object(forKey: "backgroundBrightness") as? NSNumber
        let value = stored?.doubleValue ?? 0.5
        return CGFloat(value)
    }

    private func addMenuBgm() {
        // BGM is handled by AudioManager.
    }

    override func mouseDown(with event: NSEvent) {
        let location = event.location(in: self)
        handleSelection(at: location)
    }

    private func handleSelection(at location: CGPoint) {
        let nodesAtPoint = nodes(at: location)

        if nodesAtPoint.contains(where: { $0.name == "play_button" }) {
            route(.play)
            return
        }

        if nodesAtPoint.contains(where: { $0.name == "characters_button" }) {
            route(.character)
            return
        }

        if nodesAtPoint.contains(where: { $0.name == "settings_button" }) {
            route(.settings)
            return
        }
    }

    private func route(_ action: MenuAction) {
        // TODO: hook up routing logic when scenes are ready.
        switch action {
        case .play:
            break
        case .character:
            presentCharacters()
        case .settings:
            presentSettings()
        }
    }

    private func presentCharacters() {
        guard let view = view else {
            return
        }

        let scene = CharactersScene(size: size)
        scene.scaleMode = scaleMode
        view.presentScene(scene)
    }

    private func presentSettings() {
        guard let view = view else {
            return
        }

        let scene = SettingsScene(size: size)
        scene.scaleMode = scaleMode
        view.presentScene(scene)
    }
}
