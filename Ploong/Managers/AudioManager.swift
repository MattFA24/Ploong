import AVFoundation
import Foundation

final class AudioManager {
    static let shared = AudioManager()

    private var menuPlayer: AVAudioPlayer?
    private var gamePlayer: AVAudioPlayer?
    private var sfxPlayers: [AVAudioPlayer] = []

    // MARK: - Volume Properties
    
    var musicVolume: Float {
        get { UserDefaults.standard.float(forKey: "MusicVolume") }
        set {
            let clampedValue = max(0.0, min(newValue, 1.0))
            UserDefaults.standard.set(clampedValue, forKey: "MusicVolume")
            
            menuPlayer?.volume = clampedValue
            gamePlayer?.volume = clampedValue
        }
    }

    var sfxVolume: Float {
        get { UserDefaults.standard.float(forKey: "SFXVolume") }
        set {
            let clampedValue = max(0.0, min(newValue, 1.0))
            UserDefaults.standard.set(clampedValue, forKey: "SFXVolume")
            
            sfxPlayers.forEach { $0.volume = clampedValue }
        }
    }

    private init() {
        UserDefaults.standard.register(defaults: [
            "MusicVolume": 1.0,
            "SFXVolume": 1.0
        ])
    }

    // MARK: - Music Control

    func playMenuBgm() {
        if menuPlayer?.isPlaying == true { return }
        guard let url = Bundle.main.url(forResource: "bgm_menu", withExtension: "mp3") else { return }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = musicVolume
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

    func playGameBgm() {
        if gamePlayer?.isPlaying == true { return }
        guard let url = Bundle.main.url(forResource: "bgm_main_battle", withExtension: "mp3") else { return }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = musicVolume
            player.prepareToPlay()
            player.play()
            gamePlayer = player
        } catch {
            gamePlayer = nil
        }
    }

    func stopGameBgm() {
        gamePlayer?.stop()
        gamePlayer = nil
    }

    // MARK: - SFX Control

    func playSFX(named resourceName: String) {
        sfxPlayers.removeAll { !$0.isPlaying }
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "mp3") else { return }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = sfxVolume
            player.prepareToPlay()
            player.play()
            sfxPlayers.append(player)
        } catch {
            return
        }
    }
    
    func stopSFX(named resourceName: String) {
        sfxPlayers.removeAll { player in
            player.stop()
            return true
        }
    }
    
    func stopAllSFX() {
        sfxPlayers.forEach { $0.stop() }
        sfxPlayers.removeAll()
    }
    
    func fadeGameBgm(duration: TimeInterval) {
        guard let player = gamePlayer, player.isPlaying else { return }
        player.setVolume(0, fadeDuration: duration)
    }
}
