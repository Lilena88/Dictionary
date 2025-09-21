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
    
    /// Attempts to find a Siri voice for the given BCP-47 language code.
    /// Falls back to the first available voice for that language, then to system default.
    private func preferredVoice(for languageCode: String) -> AVSpeechSynthesisVoice? {
        // Look for any voice whose name or identifier hints it's a Siri voice.
        let candidates = AVSpeechSynthesisVoice.speechVoices().filter { voice in
            guard voice.language == languageCode else { return false }
            let lowerName = voice.name.lowercased()
            let lowerId = voice.identifier.lowercased()
            return lowerName.contains("siri") || lowerId.contains("siri")
        }
        if let siri = candidates.first { return siri }
        // Fallback: any voice that matches the language code
        if let regular = AVSpeechSynthesisVoice.speechVoices().first(where: { $0.language == languageCode }) {
            return regular
        }
        // Final fallback: nil lets the system choose a default voice.
        return nil
    }
    
    override init() {
        super.init()
        speechSynthesizer.delegate = self
    }
    
    /// Pronounces the given word using auto-detected language (Cyrillic -> Russian, else English).
    /// - Parameters:
    ///   - word: The word to pronounce
    ///   - forceRussian: Optional override; if provided, skips auto-detection.
    func pronounceWord(_ word: String, forceRussian: Bool? = nil) {
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
        
        // Determine target language
    let isRussian: Bool = forceRussian ?? word.containsCyrillic
    let languageCode = isRussian ? "ru-RU" : "en-US"
        // Prefer a Siri voice if available for that language
        if let voice = preferredVoice(for: languageCode) {
            utterance.voice = voice
        } else if let langVoice = AVSpeechSynthesisVoice(language: languageCode) {
            utterance.voice = langVoice
        } // else leave nil for system default
        
    // Adjust speaking parameters (tweak if Siri voices sound too slow/fast)
    utterance.rate = AVSpeechUtteranceDefaultSpeechRate
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