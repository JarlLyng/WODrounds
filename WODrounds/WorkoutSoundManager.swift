//
//  WorkoutSoundManager.swift
//  WODrounds
//
//  Plays countdown and workout sounds. iOS and tvOS only. Uses .playback so sounds are audible even in silent mode.
//

#if os(iOS) || os(tvOS)
import AVFoundation
import Foundation

enum WorkoutSoundManager {
    private static var currentPlayer: AVAudioPlayer?

    /// User-controlled sound on/off. Defaults to `true` (sounds enabled). Read directly from
    /// UserDefaults so non-View contexts can check it. Mirrors `@AppStorage("soundEnabled")`
    /// in the SwiftUI views.
    static var isSoundEnabled: Bool {
        // Treat missing key as "enabled" (sound on by default).
        guard UserDefaults.standard.object(forKey: "soundEnabled") != nil else { return true }
        return UserDefaults.standard.bool(forKey: "soundEnabled")
    }

    /// Plays the "get ready / start" sound when the 10-second countdown reaches zero (before workout).
    static func playGetReadyStart() {
        play(name: "getReadyStart", ext: "mp3")
    }

    /// Plays the "30 seconds remaining" sound (once per phase, when 30 seconds remain in the round/phase).
    static func play30SecondsRemaining() {
        play(name: "30SecondsRemaining", ext: "mp3")
    }

    /// Plays a random "you did it" sound when the workout is complete.
    static func playYouDidIt() {
        let variants = ["youDidIt", "youDidIt2", "youDidIt3"]
        let name = variants.randomElement()!
        play(name: name, ext: "mp3")
    }

    /// Plays "10 rounds left" announcement.
    static func playTenRoundsLeft() {
        play(name: "tenRoundsLeft", ext: "mp3")
    }

    /// Plays "5 rounds left" announcement.
    static func playFiveRoundsLeft() {
        play(name: "fiveRoundsLeft", ext: "mp3")
    }

    /// Plays "2 rounds left" announcement.
    static func playTwoRoundsLeft() {
        play(name: "twoRoundsLeft", ext: "mp3")
    }

    /// Checks if a rounds-remaining sound should play and plays it.
    /// Call this when `currentRound` changes. `totalRounds` is the total number of rounds in the workout.
    static func checkRoundsRemaining(currentRound: Int, totalRounds: Int) {
        let roundsLeft = totalRounds - currentRound
        switch roundsLeft {
        case 10 where totalRounds > 10:
            playTenRoundsLeft()
        case 5 where totalRounds > 5:
            playFiveRoundsLeft()
        case 2:
            playTwoRoundsLeft()
        default:
            break
        }
    }

    private static func play(name: String, ext: String) {
        // Respect the user's sound on/off preference (toggle in the main UI).
        guard isSoundEnabled else { return }
        let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Sounds")
            ?? Bundle.main.url(forResource: name, withExtension: ext)
        guard let url = url else {
            print("[Sound] File not found: \(name).\(ext)")
            return
        }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("[Sound] Audio session setup failed: \(error.localizedDescription)")
            return
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            currentPlayer = player
            player.play()
        } catch {
            print("[Sound] Failed to play \(name).\(ext): \(error.localizedDescription)")
        }
    }
}
#endif
