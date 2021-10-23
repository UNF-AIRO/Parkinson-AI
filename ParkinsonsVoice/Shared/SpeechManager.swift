//
//  SpeechManager.swift
//  ParkinsonsVoice
//
//  Created by Andreas on 10/22/21.
//

import SwiftUI
import Speech
import SigmaSwiftStatistics

class SpeechManager: ObservableObject {
    
    init() {
        SFSpeechRecognizer.requestAuthorization { (status) in
            switch status {
            case .notDetermined: print("Not determined")
          case .restricted: print("Restricted")
          case .denied: print("Denied")
          case .authorized: print("We can recognize speech now.")
          @unknown default: print("Unknown case")
          }
        }
        do {
            try startRecording()
        } catch {
            print(error)
        }
    }
    func speechAnalysis() {
        if let speechRecognizer = SFSpeechRecognizer() {
          if speechRecognizer.isAvailable {
            // Use the speech recognizer
          }
        }
      
    }
    let speechRecognizer = SFSpeechRecognizer()!
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?
    let audioEngine = AVAudioEngine()
    func startRecording() throws {
      
      // Cancel the previous recognition task.
      recognitionTask?.cancel()
      recognitionTask = nil
        
      // Audio session, to get information from the microphone.
      let audioSession = AVAudioSession.sharedInstance()
      try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
      try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
      let inputNode = audioEngine.inputNode
      
      // The AudioBuffer
      recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
      recognitionRequest!.shouldReportPartialResults = true
      
      // Force speech recognition to be on-device
      if #available(iOS 13, *) {
        recognitionRequest!.requiresOnDeviceRecognition = true
        
      }
       
      // Actually create the recognition task. We need to keep a pointer to it so we can stop it.
      recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest!) { result, error in
        var isFinal = false
        
        if let result = result {
          isFinal = result.isFinal
          print("Text \(result.bestTranscription.formattedString)")
          
            let jitter = result.speechRecognitionMetadata?.voiceAnalytics?.jitter.acousticFeatureValuePerFrame
            let pitch = result.speechRecognitionMetadata?.voiceAnalytics?.pitch.acousticFeatureValuePerFrame
            let shimmer = result.speechRecognitionMetadata?.voiceAnalytics?.shimmer.acousticFeatureValuePerFrame
            if let jitter = jitter {
                if let pitch = pitch {
                    if let shimmer = shimmer {
                        do {
                            print(jitter)
                    //let prediction = try ParkinsonsPredictor().prediction(MDVP_Fo_Hz_: Sigma.average(pitch) ?? 0.0, MDVP_Jitter___: Sigma.average(jitter) ?? 0.0, MDVP_Shimmer: Sigma.average(shimmer) ?? 0.0)
                            var predictions = [Int]()
                            for jitter in jitter {
                                let prediction = try ParkinsonsPredictor2().prediction(MDVP_Jitter___: jitter)
                                predictions.append(Int(prediction.status))
                            }
                           
                            print(Sigma.average(predictions.map{Double($0)}))
                        } catch {
                            
                        }
                }
                }
            
        }
        }
        
        if error != nil || isFinal {
          // Stop recognizing speech if there is a problem.
            self.audioEngine.stop()
          inputNode.removeTap(onBus: 0)
          
            self.recognitionRequest = nil
            self.recognitionTask = nil
        }
      }
      
      // Configure the microphone.
      let recordingFormat = inputNode.outputFormat(forBus: 0)
        // The buffer size tells us how much data should the microphone record before dumping it into the recognition request.
      inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
          self.recognitionRequest?.append(buffer)
      }
      
      audioEngine.prepare()
      try audioEngine.start()
    }

}
