//
//  AfterLifeApp.swift
//  AfterLife
//
//  Created by Hugues Capet on 08.11.22.
//

import SwiftUI

@main
struct AfterLifeApp: App {
    
    @StateObject var bleInterface = BLEObservable()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(bleInterface)
        }
    }
}
