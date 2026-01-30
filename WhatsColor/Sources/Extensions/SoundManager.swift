import Foundation
import AudioToolbox
import UIKit

class SoundManager {
    static let shared = SoundManager()
    
    // System sound IDs
    private let selectionChangedSound: SystemSoundID = 1104
    private let dragStartSound: SystemSoundID = 1117 // Tock
    private let dropSound: SystemSoundID = 1118 // Tink
    private let errorSound: SystemSoundID = 1053 // Pulsing
    private let successSound: SystemSoundID = 1013 // Fanfare-like
    
    private init() {}
    
    func playSelection() {
        AudioServicesPlaySystemSound(selectionChangedSound)
    }
    
    func playDragStart() {
        AudioServicesPlaySystemSound(dragStartSound)
    }
    
    func playDrop() {
        AudioServicesPlaySystemSound(dropSound)
    }
    
    func playError() {
        AudioServicesPlaySystemSound(errorSound)
    }
    
    func playSuccess() {
        AudioServicesPlaySystemSound(successSound)
    }
    
    func hapticLight() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
    
    func hapticMedium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    
    func hapticSuccess() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }
}
