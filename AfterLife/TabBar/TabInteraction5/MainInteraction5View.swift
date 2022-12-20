//
//  MainInteraction5View.swift
//  AfterLife
//
//  Created by Hugues Capet on 20.12.22.
//

import SwiftUI

struct MainInteraction5View: View {
    @EnvironmentObject var bleInterface: BLEObservable
    
    @State var connectionString = "No device connected"
    @State var scanButtonString = "Start scan"
    @State var isScanningDevices = false
    @State var isShowingDetailView = false
    @State var pokerSoundStatus = ""
    
    var esp32Interaction5Name = "rfid-luca"
    
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
                                bleInterface.connectToPeriphWithName(name: esp32Interaction5Name)
                            }
                            else {
                                scanButtonString = "Start scan"
                                bleInterface.stopScan()
                            }
                        }
                    }
                }
                else {
                    Button("Make poker game sound") {
                        makePokerGameSound()
                    }
                    Text(pokerSoundStatus)
                }
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
        })
        .padding()
    }
    
    func makePokerGameSound() {
        pokerSoundStatus = "sound started"
    }
}

struct MainInteraction5View_Previews: PreviewProvider {
    static var previews: some View {
        MainInteraction5View()
    }
}
