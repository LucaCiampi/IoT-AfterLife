//
//  ContentView.swift
//  AfterLife
//
//  Created by Hugues Capet on 08.11.22.
//

import SwiftUI
import AVKit

struct ContentView: View {
    
    @EnvironmentObject var bleInterface: BLEObservable
    
    @State var showModal = false
    @State var startVideo = false
    
    var body: some View {
        ZStack {
            TabView {
                MainInteraction1View().tabItem {
                    Label("Verres", systemImage: "wineglass")
                }
                MainInteraction2View(showModal: $showModal, startVideo: $startVideo).tabItem {
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
            }.disabled(showModal)
            
            if showModal {
                modalVideo.zIndex(1)
            }
        }
    }
    
    // Full screen modal video for interaction 2
    let player = AVPlayer()
    let videoUrl = Bundle.main.url(forResource: "test", withExtension: "mp4")!
    
    var modalVideo: some View {
        VideoPlayer(player: player)
            .onAppear{
                if player.currentItem == nil {
                    let item = AVPlayerItem(url: videoUrl)
                    player.replaceCurrentItem(with: item)
                }
                player.preventsDisplaySleepDuringVideoPlayback = true
            }
            .onChange(of: startVideo, perform: { newValue in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                    player.play()
                })
            })
            .edgesIgnoringSafeArea(.all)
    }
}
