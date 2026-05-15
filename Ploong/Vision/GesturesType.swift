//
//  GesturesType.swift
//  Ploong
//
//  Created by Matthew Fernando Anggrian on 11/05/26.
//

enum HandGesture: Equatable, Sendable {
    case fist
    case point
    case unrecognized
    case unknown

    var displayText: String {
        switch self {
        case .fist:
            return "Gesture: Fist"
        case .point:
            return "Gesture: Point"
        case .unrecognized:
            return "Hand detected"
        case .unknown:
            return "No hand detected"
        }
    }
}
