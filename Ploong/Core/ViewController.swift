//
//  ViewController.swift
//  Ploong
//
//  Created by Matthew Fernando Anggrian on 11/05/26.
//

import Cocoa
import SpriteKit

final class ViewController: NSViewController {
    @IBOutlet private var skView: SKView!
    private let targetSceneSize = CGSize(width: 1280, height: 800)

    override func viewDidLoad() {
        super.viewDidLoad()

        let scene = MenuScene(size: targetSceneSize)
        scene.scaleMode = .aspectFit

        skView.presentScene(scene)
        skView.ignoresSiblingOrder = true
    }

    override func viewDidAppear() {
        super.viewDidAppear()

        guard let window = view.window else {
            return
        }

        let minSize = NSSize(width: targetSceneSize.width, height: targetSceneSize.height)
        window.setContentSize(minSize)
        window.contentMinSize = minSize
        window.contentAspectRatio = minSize
    }
}
