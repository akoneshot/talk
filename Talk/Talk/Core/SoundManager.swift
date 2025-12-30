import AVFoundation
import AppKit

class SoundManager {
    static let shared = SoundManager()

    private var startSound: NSSound?
    private var stopSound: NSSound?
    private var successSound: NSSound?
    private var errorSound: NSSound?

    private init() {
        loadSounds()
    }

    private func loadSounds() {
        // Use system sounds
        startSound = NSSound(named: "Tink")
        stopSound = NSSound(named: "Pop")
        successSound = NSSound(named: "Glass")
        errorSound = NSSound(named: "Basso")
    }

    func playStartSound() {
        startSound?.play()
    }

    func playStopSound() {
        stopSound?.play()
    }

    func playSuccessSound() {
        successSound?.play()
    }

    func playErrorSound() {
        errorSound?.play()
    }
}
