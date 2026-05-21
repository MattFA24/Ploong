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
    
    // 1. Add the init() method to register the font immediately
    override init() {
        super.init()
        registerAppFonts()
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // 2. Remove registerAppFonts() from here
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
