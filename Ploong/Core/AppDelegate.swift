//
//  AppDelegate.swift
//  Ploong
//
//  Created by Matthew Fernando Anggrian on 11/05/26.
//


import Cocoa
import CoreText

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        CharacterManager.shared.resetProgress(startingCoins: 100)
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    private func registerAppFonts() {
        guard let fontURL = Bundle.main.url(forResource: "eas-vhs", withExtension: "ttf") else {
            return
        }

        _ = CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
    }
}
