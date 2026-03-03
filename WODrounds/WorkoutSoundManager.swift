//
//  WorkoutSoundManager.swift
//  WODrounds
//
//  Plays countdown and workout sounds. iOS only. Uses .playback so sounds are audible even in silent mode.
//

#if os(iOS)
import AVFoundation
import Foundation

enum WorkoutSoundManager {
    private static var currentPlayer: AVAudioPlayer?
    private static let getReadyStartName = "getReadyStart"
    private static let thirtySecondsRemainingName = "30SecondsRemaining"
    private static let youDidItName = "youDidIt"

    /// Plays the "get ready / start" sound when the 10-second countdown reaches zero (before workout).
    static func playGetReadyStart() {
        play(name: getReadyStartName, ext: "mp3")
    }

    /// Plays the "30 seconds remaining" sound (once per phase, when 30 seconds remain in the round/phase).
    static func play30SecondsRemaining() {
        play(name: thirtySecondsRemainingName, ext: "mp3")
    }

    /// Plays the "you did it" sound when the workout is complete.
    static func playYouDidIt() {
        play(name: youDidItName, ext: "mp3")
    }

    private static func play(name: String, ext: String) {
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
