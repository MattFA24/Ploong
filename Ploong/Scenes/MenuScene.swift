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
    private var bgmNode: SKAudioNode?

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
        addMenuBgm()

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

        let playButton = MenuButtonNode(action: .play,
                                        size: CGSize(width: 420, height: 140),
                                        fontSize: 72)
        playButton.position = CGPoint(x: size.width * 0.5, y: size.height * 0.50)
        addChild(playButton)

        let characterButton = MenuButtonNode(action: .character,
                                             size: CGSize(width: 280, height: 80),
                                             fontSize: 28)
        characterButton.position = CGPoint(x: size.width * 0.5, y: size.height * 0.34)
        addChild(characterButton)

        let settingsButton = MenuButtonNode(action: .settings,
                                            size: CGSize(width: 260, height: 70),
                                            fontSize: 26)
        settingsButton.position = CGPoint(x: size.width * 0.5, y: size.height * 0.24)
        addChild(settingsButton)
    }

    private func addScrollingBackground() {
        let texture = SKTexture(imageNamed: "main_menu_bg")
        let textureSize = texture.size()
        guard textureSize.width > 0, textureSize.height > 0 else {
            return
        }

        let scale = max(size.width / textureSize.width, size.height / textureSize.height)
        let scaledSize = CGSize(width: textureSize.width * scale, height: textureSize.height * scale)
        let duration = TimeInterval(scaledSize.width / 18)

        let bg1 = SKSpriteNode(texture: texture, size: scaledSize)
        let bg2 = SKSpriteNode(texture: texture, size: scaledSize)

        bg1.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        bg2.position = CGPoint(x: bg1.position.x - scaledSize.width, y: bg1.position.y)

        bg1.zPosition = -2
        bg2.zPosition = -2

        let move = SKAction.moveBy(x: scaledSize.width, y: 0, duration: duration)
        let reset = SKAction.moveBy(x: -scaledSize.width, y: 0, duration: 0)
        let loop = SKAction.repeatForever(SKAction.sequence([move, reset]))

        bg1.run(loop)
        bg2.run(loop)

        addChild(bg1)
        addChild(bg2)
    }

    private func addMenuBgm() {
        if bgmNode != nil {
            return
        }

        let node = SKAudioNode(fileNamed: "menu_bgm.mp3")
        node.autoplayLooped = true
        node.isPositional = false
        node.zPosition = -10
        addChild(node)
        bgmNode = node
    }

    override func mouseDown(with event: NSEvent) {
        let location = event.location(in: self)
        handleSelection(at: location)
    }

    private func handleSelection(at location: CGPoint) {
        let nodesAtPoint = nodes(at: location)
        let button = nodesAtPoint.first { $0 is MenuButtonNode } as? MenuButtonNode
        guard let action = button?.action else {
            return
        }

        route(action)
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

private final class MenuButtonNode: SKShapeNode {
    let action: MenuScene.MenuAction

    init(action: MenuScene.MenuAction, size: CGSize, fontSize: CGFloat) {
        self.action = action
        super.init()

        let rect = CGRect(origin: CGPoint(x: -size.width * 0.5, y: -size.height * 0.5),
                          size: size)
        path = CGPath(roundedRect: rect, cornerWidth: size.height * 0.35, cornerHeight: size.height * 0.35, transform: nil)
        fillColor = NSColor(white: 0.7, alpha: 1)
        strokeColor = NSColor.clear

        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.text = action.rawValue.uppercased()
        label.fontSize = fontSize
        label.fontColor = .black
        label.verticalAlignmentMode = .center
        addChild(label)
    }

    required init?(coder: NSCoder) {
        return nil
    }
}
