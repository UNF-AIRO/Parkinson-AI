//
//  ParkinsonsVoiceApp.swift
//  Shared
//
//  Created by Andreas on 10/22/21.
//

import SwiftUI

@main
struct ParkinsonsVoiceApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear() {
                    SpeechManager()
                }
        }
    }
}
