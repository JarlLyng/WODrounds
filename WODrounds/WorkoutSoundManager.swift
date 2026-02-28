//
//  WorkoutSoundManager.swift
//  WODrounds
//
//  Afspiller countdown- og workout-lyde. Kun iOS. Bruger .playback så lyd høres også ved lydløs.
//

#if os(iOS)
import AVFoundation
import Foundation

enum WorkoutSoundManager {
    private static var currentPlayer: AVAudioPlayer?
    private static let getReadyStartName = "getReadyStart"
    private static let thirtySecondsRemainingName = "30SecondsRemaining"
    private static let youDidItName = "youDidIt"

    /// Afspiller "get ready / start"-lyd når de 10 sekunder er talt ned til 0 (før workout).
    static func playGetReadyStart() {
        play(name: getReadyStartName, ext: "mp3")
    }

    /// Afspiller "30 sekunder tilbage"-lyd (én gang per fase, når der er 30 sek tilbage i runden/phasen).
    static func play30SecondsRemaining() {
        play(name: thirtySecondsRemainingName, ext: "mp3")
    }

    /// Afspiller "you did it"-lyd når workout er færdig.
    static func playYouDidIt() {
        play(name: youDidItName, ext: "mp3")
    }

    private static func play(name: String, ext: String) {
        let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Sounds")
            ?? Bundle.main.url(forResource: name, withExtension: ext)
        guard let url = url else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch { return }
        guard let player = try? AVAudioPlayer(contentsOf: url) else { return }
        currentPlayer = player
        player.play()
    }
}
#endif
