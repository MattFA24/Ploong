//
//  InputComponent.swift
//  Ploong
//
//  Created by Matthew Fernando Anggrian on 11/05/26.
//  

import GameplayKit

final class InputComponent: GKComponent {
    typealias ActionHandler = () -> Void

    private let handler: ActionHandler

    init(handler: @escaping ActionHandler) {
        self.handler = handler
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func trigger() {
        handler()
    }
}
