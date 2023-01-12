//
//  MainInteraction5View.swift
//  AfterLife
//
//  Created by Hugues Capet on 20.12.22.
//

import SwiftUI
import AVFoundation

struct MainInteraction5View: View {
    @EnvironmentObject var bleInterface: BLEObservable
    
    @State var connectionString = "No device connected"
    @State var scanButtonString = "Start scan"
    @State var isScanningDevices = false
    @State var isShowingDetailView = false
    
    @State var pokerSoundStatus = ""
    @State var isPokerSoundPlaying = false
    @State var pokerEsp32ReceivedMessage = ""
    
    @State var player: AVAudioPlayer?
    
    var body: some View {
        VStack {
            VStack {
                Text(connectionString)
                
                if bleInterface.connectedPeripheral != nil {
                    Button("Disconnect") {
                        bleInterface.disconnectFrom(p: bleInterface.connectedPeripheral!)
                    }
                }
            }.padding()
            VStack {
                if (!isShowingDetailView) {
                    HStack {
                        Button(scanButtonString) {
                            isScanningDevices = !isScanningDevices
                            if (isScanningDevices) {
                                scanButtonString = "Stop scan"
                                bleInterface.connectToInteraction5Esp32()
                                /*DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    bleInterface.connectToInteraction5Esp32Bis()
                                }*/
                            }
                            else {
                                scanButtonString = "Start scan"
                                bleInterface.stopScan()
                            }
                        }
                    }
                }
                else {
                    Text("Ready").onAppear {
                        bleInterface.listenForPokerEsp32()
                    }
                    Text(pokerSoundStatus)
                    Text(pokerEsp32ReceivedMessage)
                }
                Button("Make poker game sound") {
                    makePokerGameSound()
                }.padding()
            }.padding()
        }.onChange(of: bleInterface.connectionState, perform: { newValue in
            switch newValue {
                
            case .disconnected:
                isShowingDetailView = false
                break
            case .connecting:
                connectionString = "Connecting... "
                break
            case .discovering:
                connectionString = "Discovering... "
                break
            case .ready:
                connectionString = "Connected to " + connectionString
                isShowingDetailView = true
                break
            }
        }).onChange(of: bleInterface.connectedPeripheral, perform: { newValue in
            if let p = newValue {
                connectionString = p.name
            }
            else {
                connectionString = "No ESP32 connected"
            }
        }).onChange(of: bleInterface.pokerDataReceived, perform: { newValue in
            pokerEsp32ReceivedMessage = (bleInterface.pokerDataReceived.last?.content ?? "nothing") + " just badged !"
            makePokerGameSound()
        })
        .padding()
    }
    
    func makePokerGameSound() {
        guard let url = Bundle.main.url(forResource: "giant_bell", withExtension: "mp3") else { return print("giant_bell sound not found") }

        do {
            try AVAudioSession.sharedInstance().setCategory(.soloAmbient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            /* The following line is required for the player to work on iOS 11. Change the file type accordingly*/
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)

            /* iOS 10 and earlier require the following line:
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileTypeMPEGLayer3) */

            guard let player = player else { return }

            if (!isPokerSoundPlaying) {
                isPokerSoundPlaying = true
                player.play()
                print("giant_bell just played")
                DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                    isPokerSoundPlaying = false
                }
            }

        } catch let error {
            print(error.localizedDescription)
        }
    }
}

struct MainInteraction5View_Previews: PreviewProvider {
    static var previews: some View {
        MainInteraction5View()
    }
}
