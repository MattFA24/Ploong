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
    
    // Get currently equipped character
    func getEquippedCharacter() -> String {
        return UserDefaults.standard.string(forKey: "EquippedCharacter") ?? defaultCharacter
    }
    
    // Equip a character
    func equipCharacter(name: String) {
        if getOwnedCharacters().contains(name) {
            UserDefaults.standard.set(name, forKey: "EquippedCharacter")
        }
    }
    
    // Get array of owned characters
    func getOwnedCharacters() -> [String] {
        if let owned = UserDefaults.standard.stringArray(forKey: "OwnedCharacters") {
            return owned
        }
        // Default: Player only owns Joy at the start
        let defaultOwned = [defaultCharacter]
        UserDefaults.standard.set(defaultOwned, forKey: "OwnedCharacters")
        return defaultOwned
    }
    
    // Purchase logic
    func purchaseCharacter(name: String, currentCoins: Int) -> Bool {
        guard let price = characterPrices[name], currentCoins >= price else {
            return false // Not enough coins
        }
        
        var owned = getOwnedCharacters()
        if !owned.contains(name) {
            owned.append(name)
            UserDefaults.standard.set(owned, forKey: "OwnedCharacters")
            
            // Deduct coins (Assuming you have a UserDefaults key for coins)
            let newBalance = currentCoins - price
            UserDefaults.standard.set(newBalance, forKey: "TotalCoins")
            return true
        }
        return false // Already owned
    }
}
