//
//  MainInteraction4View.swift
//  SwiftUI_TPFinal
//
//  Created by Hugues Capet on 20.12.22.
//

import SwiftUI

struct MainInteraction4View: View {
    @EnvironmentObject var bleInterface: BLEObservable
    
    @State var connectionString = "No device connected"
    @State var scanButtonString = "Start scan"
    @State var isScanningDevices = false
    @State var isShowingDetailView = false
    
    var esp32Interaction4Name = "rfid-luca"
    
    var body: some View {
        VStack {
            Text(connectionString)
            
            if bleInterface.connectedPeripheral != nil {
                Button("Disconnect") {
                    bleInterface.disconnectFrom(p: bleInterface.connectedPeripheral!)
                }
            }
            if (!isShowingDetailView) {
                HStack {
                    Button(scanButtonString) {
                        isScanningDevices = !isScanningDevices
                        if (isScanningDevices) {
                            scanButtonString = "Stop scan"
                            bleInterface.connectToPeriphWithName(name: esp32Interaction4Name)
                        }
                        else {
                            scanButtonString = "Start scan"
                            bleInterface.stopScan()
                        }
                    }
                }
            }
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
}

struct MainInteraction4View_Previews: PreviewProvider {
    static var previews: some View {
        MainInteraction4View()
    }
}
