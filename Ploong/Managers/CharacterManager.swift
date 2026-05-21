//
//  CharacterManager.swift
//  Ploong
//
//  Created by Matthew Fernando Anggrian on 20/05/26.
//

import Foundation

struct CharacterManager {
    static let shared = CharacterManager()
    
    let defaultCharacter = "Joy"
    let availableCharacters = ["Joy", "Farrell", "Jevon", "Tiu", "Vey"]
    let characterPrices: [String: Int] = [
        "Joy": 0,
        "Farrell": 20,
        "Jevon": 20,
        "Tiu": 20,
        "Vey": 20
    ]
    
    func getEquippedCharacter() -> String {
        return UserDefaults.standard.string(forKey: "EquippedCharacter") ?? defaultCharacter
    }
    
    func equipCharacter(name: String) {
        if getOwnedCharacters().contains(name) {
            UserDefaults.standard.set(name, forKey: "EquippedCharacter")
        }
    }
    
    func getOwnedCharacters() -> [String] {
        if let owned = UserDefaults.standard.stringArray(forKey: "OwnedCharacters") {
            return owned
        }
        let defaultOwned = [defaultCharacter]
        UserDefaults.standard.set(defaultOwned, forKey: "OwnedCharacters")
        return defaultOwned
    }
    
    func purchaseCharacter(name: String, currentCoins: Int) -> Bool {
        guard let price = characterPrices[name], currentCoins >= price else {
            return false
        }
        var owned = getOwnedCharacters()
        if !owned.contains(name) {
            owned.append(name)
            UserDefaults.standard.set(owned, forKey: "OwnedCharacters")
            let newBalance = currentCoins - price
            UserDefaults.standard.set(newBalance, forKey: "TotalCoins")
            return true
        }
        return false
    }

    // ── Debug reset ───────────────────────────────────────────────────────────
    func resetProgress(startingCoins: Int = 0) {
        let defaults = UserDefaults.standard
        defaults.set([defaultCharacter], forKey: "OwnedCharacters")
        defaults.set(defaultCharacter,   forKey: "EquippedCharacter")
        defaults.set(startingCoins,      forKey: "TotalCoins")
        defaults.synchronize()
    }
}
