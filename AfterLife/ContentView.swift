//
//  ContentView.swift
//  AfterLife
//
//  Created by Hugues Capet on 08.11.22.
//

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var bleInterface: BLEObservable
    
    var body: some View {
        TabView {
            MainInteraction1View().tabItem {
                Label("Verres", systemImage: "wineglass")
            }
            MainInteraction2View().tabItem {
                Label("Analyse", systemImage: "faxmachine")
            }
            MainInteraction3View().tabItem {
                Label("Cuve", systemImage: "humidifier.and.droplets")
            }
            MainInteraction4View().tabItem {
                Label("DJI", systemImage: "bird")
            }
            MainInteraction5View().tabItem {
                Label("Poker", systemImage: "greetingcard")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
