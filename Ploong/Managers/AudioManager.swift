//
//  AudioManager.swift
//  Ploong
//
//  Created by Matthew Fernando Anggrian on 11/05/26.
//  

import AVFoundation

final class AudioManager {
    static let shared = AudioManager()

    private var menuPlayer: AVAudioPlayer?

    private init() {}

    func playMenuBgm() {
        if menuPlayer?.isPlaying == true {
            return
        }

        guard let url = Bundle.main.url(forResource: "menu_bgm", withExtension: "mp3") else {
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.prepareToPlay()
            player.play()
            menuPlayer = player
        } catch {
            menuPlayer = nil
        }
    }

    func stopMenuBgm() {
        menuPlayer?.stop()
        menuPlayer = nil
    }
}
