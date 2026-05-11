//
//  SliderComponent.swift
//  Ploong
//
//  Created by Matthew Fernando Anggrian on 11/05/26.
//

import SpriteKit
import GameplayKit

final class SliderComponent: GKComponent {
    private let trackNode: SKShapeNode
    private let knobNode: SKShapeNode

    private(set) var value: CGFloat
    private var minX: CGFloat = 0.0
    private var maxX: CGFloat = 0.0
    private var knobRadius: CGFloat = 0.0
    private var knobCenterY: CGFloat = 0.0
    private var isDragging = false

    init(trackNode: SKShapeNode, knobNode: SKShapeNode, value: CGFloat) {
        self.trackNode = trackNode
        self.knobNode = knobNode
        self.value = min(max(value, 0.0), 1.0)
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(range: ClosedRange<CGFloat>, centerY: CGFloat) {
        minX = range.lowerBound
        maxX = range.upperBound
        knobCenterY = centerY
        knobRadius = knobNode.frame.width * 0.5

        guard maxX > minX else { return }

        let x = minX + (maxX - minX) * value
        knobNode.position = CGPoint(x: x - knobRadius, y: knobCenterY - knobRadius)
    }

    func beginDrag(at scenePoint: CGPoint, in parent: SKNode) -> Bool {
        let localPoint = parent.convert(scenePoint, from: parent.scene ?? parent)
        let knobFrame = knobNode.calculateAccumulatedFrame()
        let trackFrame = trackNode.calculateAccumulatedFrame()

        guard knobFrame.contains(localPoint) || trackFrame.contains(localPoint) else { return false }

        isDragging = true
        updateValue(using: localPoint.x)
        return true
    }

    func drag(to scenePoint: CGPoint, in parent: SKNode) {
        guard isDragging else { return }
        let localPoint = parent.convert(scenePoint, from: parent.scene ?? parent)
        updateValue(using: localPoint.x)
    }

    func endDrag() {
        isDragging = false
    }

    private func updateValue(using localX: CGFloat) {
        guard maxX > minX else { return }

        let clampedX = min(max(localX, minX), maxX)
        value = (clampedX - minX) / (maxX - minX)
        knobNode.position = CGPoint(x: clampedX - knobRadius, y: knobCenterY - knobRadius)
    }
}
