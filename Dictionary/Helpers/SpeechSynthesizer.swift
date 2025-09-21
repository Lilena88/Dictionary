//
//  SpeechSynthesizer.swift
//  Dictionary
//
//  Created by GitHub Copilot on 9/21/25.
//

import Foundation
import AVFoundation

/// A utility class that handles text-to-speech synthesis with proper audio session management.
final class SpeechSynthesizer: NSObject, ObservableObject {
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    override init() {
        super.init()
        speechSynthesizer.delegate = self
    }
    
    /// Pronounces the given word using the appropriate language voice
    /// - Parameters:
    ///   - word: The word to pronounce
    ///   - isRussian: Whether to use Russian voice (true) or English voice (false)
    func pronounceWord(_ word: String, isRussian: Bool = false) {
        // Configure audio session for speech synthesis
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to configure audio session: \(error)")
            return
        }
        
        // Stop any current speech
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: word)
        
        // Configure voice based on language
        let languageCode = isRussian ? "ru-RU" : "en-US"
        if let voice = AVSpeechSynthesisVoice(language: languageCode) {
            utterance.voice = voice
        } else {
            // Fallback to default voice if specific language is unavailable
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        }
        
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        speechSynthesizer.speak(utterance)
    }
    
    /// Stops any current speech synthesis
    func stopSpeaking() {
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension SpeechSynthesizer: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        print("Speech synthesis started for: \(utterance.speechString)")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        print("Speech synthesis finished for: \(utterance.speechString)")
        
        // Deactivate audio session when done
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        print("Speech synthesis cancelled for: \(utterance.speechString)")
    }
}