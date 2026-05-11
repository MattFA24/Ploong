//
//  ViewController.swift
//  Ploong
//
//  Created by Matthew Fernando Anggrian on 11/05/26.
//

import Cocoa
import SpriteKit
import GameplayKit

class ViewController: NSViewController {

    @IBOutlet var skView: SKView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Create the menu scene in code so it always uses GameScene.swift.
        let sceneNode = GameScene(size: skView.bounds.size)
        sceneNode.scaleMode = .resizeFill

        // Present the scene
        if let view = self.skView {
            view.presentScene(sceneNode)

            view.ignoresSiblingOrder = true

            view.showsFPS = true
            view.showsNodeCount = true
        }
    }

    override func viewDidAppear() {
        super.viewDidAppear()

        guard let window = view.window else { return }

        // Enforce a 16:10 content aspect ratio and allow resizing/fullscreen.
        window.contentAspectRatio = NSSize(width: 16.0, height: 10.0)
        window.styleMask.insert(.resizable)
        window.collectionBehavior.insert(.fullScreenPrimary)

        // Set a reasonable minimum size while preserving the 16:10 ratio.
        window.contentMinSize = NSSize(width: 1280.0, height: 800.0)
        window.setContentSize(NSSize(width: 1280.0, height: 800.0))
    }
}
