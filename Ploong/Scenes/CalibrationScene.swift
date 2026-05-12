//
//  CalibrationScene.swift
//  Ploong
//
//  Created by Matthew Fernando Anggrian on 11/05/26.
//

import SpriteKit

final class CalibrationScene: SKScene {
    private var didSetupLayout = false

    override func sceneDidLoad() {
        super.sceneDidLoad()
        backgroundColor = .white
        AudioManager.shared.stopMenuBgm()
    }

    override func didMove(to view: SKView) {
        super.didMove(to: view)

        if !didSetupLayout {
            didSetupLayout = true
            buildLayout()
        }
    }

    private func buildLayout() {
        let header = SKLabelNode(fontNamed: "AvenirNext-Medium")
        header.text = "Show one of your hands, then try making a"
        header.fontSize = 22
        header.fontColor = .black
        header.verticalAlignmentMode = .center
        header.position = CGPoint(x: size.width * 0.5, y: size.height * 0.88)
        addChild(header)

        let headerBold = SKLabelNode(fontNamed: "AvenirNext-Bold")
        headerBold.text = "FIST for lower lane and OPEN PALM upper lane"
        headerBold.fontSize = 22
        headerBold.fontColor = .black
        headerBold.verticalAlignmentMode = .center
        headerBold.position = CGPoint(x: size.width * 0.5, y: size.height * 0.84)
        addChild(headerBold)

        let preview = SKShapeNode(rectOf: CGSize(width: size.width * 0.9, height: size.height * 0.62), cornerRadius: 12)
        preview.fillColor = NSColor(white: 0.8, alpha: 1)
        preview.strokeColor = NSColor(white: 0.7, alpha: 1)
        preview.position = CGPoint(x: size.width * 0.5, y: size.height * 0.45)
        addChild(preview)

        let status = SKLabelNode(fontNamed: "AvenirNext-Medium")
        status.text = "Hand Detected: FIST"
        status.fontSize = 22
        status.fontColor = .black
        status.verticalAlignmentMode = .center
        status.position = CGPoint(x: size.width * 0.5, y: size.height * 0.7)
        addChild(status)

        let previewLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        previewLabel.text = "User camera preview"
        previewLabel.fontSize = 22
        previewLabel.fontColor = .black
        previewLabel.verticalAlignmentMode = .center
        previewLabel.position = CGPoint(x: size.width * 0.5, y: size.height * 0.45)
        addChild(previewLabel)

        let hint = SKLabelNode(fontNamed: "AvenirNext-Medium")
        hint.text = "Press Enter to continue"
        hint.fontSize = 18
        hint.fontColor = NSColor(white: 0.2, alpha: 1)
        hint.verticalAlignmentMode = .center
        hint.position = CGPoint(x: size.width * 0.5, y: size.height * 0.12)
        addChild(hint)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            presentMenu()
            return
        }

        if event.keyCode == 36 || event.keyCode == 76 {
            presentGameLoop()
        }
    }

    private func presentMenu() {
        guard let view = view else {
            return
        }

        let scene = MenuScene(size: size)
        scene.scaleMode = scaleMode
        view.presentScene(scene)
    }

    private func presentGameLoop() {
        guard let view = view else {
            return
        }

        let scene = GameLoopScene(size: size)
        scene.scaleMode = scaleMode
        view.presentScene(scene)
    }
}
