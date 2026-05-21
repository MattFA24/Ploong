//
//  WarningScene.swift
//  Ploong
//
//  Created by Coding Assistant on 21/05/26.
//

import SpriteKit

final class WarningScene: SKScene {

    // MARK: - Properties

    private weak var warningNode: SKSpriteNode?
    private var didScheduleGameplay = false

    // MARK: - Scene Lifecycle

    override func sceneDidLoad() {
        super.sceneDidLoad()

        backgroundColor = .black

        buildWarningImage()
    }

    override func didMove(to view: SKView) {
        super.didMove(to: view)

        scheduleGameplayTransitionIfNeeded()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)

        layoutWarningImage()
    }

    override func willMove(from view: SKView) {
        super.willMove(from: view)

        removeAction(forKey: "warningGameplayTransition")
    }

    // MARK: - Warning Image

    private func buildWarningImage() {

        let texture = SKTexture(imageNamed: "warning")
        texture.filteringMode = .nearest

        let node = SKSpriteNode(texture: texture)

        node.zPosition = 10
        node.anchorPoint = CGPoint(x: 0.5, y: 0.5)

        addChild(node)

        warningNode = node

        layoutWarningImage()
    }

    private func layoutWarningImage() {

        guard let warningNode,
              let texture = warningNode.texture else {
            return
        }

        // Center the image
        warningNode.position = CGPoint(
            x: size.width * 0.5,
            y: size.height * 0.5
        )

        let textureSize = texture.size()

        guard textureSize.width > 0,
              textureSize.height > 0 else {
            return
        }

        let widthScale = size.width / textureSize.width
        let heightScale = size.height / textureSize.height

        // Keeps aspect ratio without stretching
        let scale = min(widthScale, heightScale)

        warningNode.setScale(scale)
    }

    // MARK: - Transition

    private func scheduleGameplayTransitionIfNeeded() {

        guard !didScheduleGameplay else {
            return
        }

        didScheduleGameplay = true

        let sequence = SKAction.sequence([
            .wait(forDuration: 3.0),

            .run { [weak self] in
                self?.presentGameLoop()
            }
        ])

        run(sequence, withKey: "warningGameplayTransition")
    }

    private func presentGameLoop() {

        guard let view else {
            return
        }

        let scene = GameLoopScene(size: size)

        scene.scaleMode = scaleMode

        view.presentScene(
            scene,
            transition: SKTransition.crossFade(withDuration: 0.2)
        )
    }
}
