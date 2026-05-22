import SpriteKit

// MARK: - WarningScene
final class WarningScene: SKScene {

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        presentGameLoop()
    }

    private func presentGameLoop() {
        guard let view else { return }

        let scene = GameLoopScene(size: size, showWarningOverlay: true)
        scene.scaleMode = scaleMode
        view.presentScene(scene)
    }
}

// MARK: - WarningOverlayNode
final class WarningOverlayNode: SKNode {

    // MARK: - Configuration

    var displayDuration: TimeInterval = 3.0
    var onDismiss: (() -> Void)?

    // MARK: - Private nodes

    private weak var backdrop: SKSpriteNode?
    private weak var warningImageNode: SKSpriteNode?

    // MARK: - Init

    init(size: CGSize) {
        super.init()
        zPosition = 1_000
        buildNodes(for: size)
        scheduleAutoDismiss()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout
    func layout(for size: CGSize) {
        backdrop?.size     = size
        backdrop?.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        warningImageNode?.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        scaleWarningImage(to: size)
    }

    // MARK: - Build

    private func buildNodes(for size: CGSize) {
        let bg = SKSpriteNode(
            color: SKColor(white: 0, alpha: 0.5),
            size: size
        )
        bg.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        bg.position    = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        bg.zPosition   = 0
        addChild(bg)
        backdrop = bg

        let texture = SKTexture(imageNamed: "warning")
        texture.filteringMode = .nearest

        let img = SKSpriteNode(texture: texture)
        img.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        img.position    = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        img.zPosition   = 1
        addChild(img)
        warningImageNode = img

        scaleWarningImage(to: size)
    }

    private func scaleWarningImage(to size: CGSize) {
        guard let img     = warningImageNode,
              let texture = img.texture else { return }

        let textureSize = texture.size()
        guard textureSize.width > 0, textureSize.height > 0 else { return }

        let scale = min(
            (size.width  * 0.75) / textureSize.width,
            (size.height * 0.75) / textureSize.height
        )
        img.setScale(scale)
    }

    // MARK: - Dismiss

    private func scheduleAutoDismiss() {
        run(.sequence([
            .wait(forDuration: displayDuration),
            .run { [weak self] in self?.dismiss() }
        ]), withKey: "overlayAutoDismiss")
    }

    func dismiss() {
        removeAction(forKey: "overlayAutoDismiss")
        run(.fadeOut(withDuration: 0.3)) { [weak self] in
            self?.removeFromParent()
            self?.onDismiss?()
        }
    }
}
