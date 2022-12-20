//
//  MainSquareView.swift
//  SwiftUI_FullApp
//
//  Created by Hugues Capet on 07.11.22.
//

import SwiftUI

struct MainInteraction3View: View {
    
    @EnvironmentObject var bleInterface: BLEObservable
    
    @State var connectionString = "No device connected"
    @State var scanButtonString = "Start scan"
    @State var isScanningDevices = false
    @State var isShowingDetailView = false
    
    var esp32Interaction3Name = "rfid-luca"
    
    var body: some View {
        VStack {            
            Text(connectionString)
            
            if bleInterface.connectedPeripheral != nil {
                Button("Disconnect") {
                    bleInterface.disconnectFrom(p: bleInterface.connectedPeripheral!)
                }
            }
            
            List(bleInterface.periphList.reversed().filter({ $0.name == esp32Interaction3Name })) { p in
                SinglePeripheralView(periphName: p.name).onTapGesture {
                    bleInterface.connectTo(p: p)
                }
            }
            
            if (isShowingDetailView) {
                VStack {
                    Text("Détails manipulation ici")
                }
            }
            
            HStack {
                Button(scanButtonString) {
                    isScanningDevices = !isScanningDevices
                    if (isScanningDevices) {
                        scanButtonString = "Stop scan"
                        bleInterface.startScan()
                    }
                    else {
                        scanButtonString = "Start scan"
                        bleInterface.stopScan()
                    }
                }
            }
        }.onChange(of: bleInterface.connectedPeripheral, perform: { newValue in
            if let p = newValue {
                connectionString = p.name
            }
            else {
                connectionString = "No ESP32 connected"
            }
        }).onChange(of: bleInterface.connectionState, perform: { newValue in
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
        })
        .padding()
    }
}

struct MainInteraction3View_Previews: PreviewProvider {
    static var previews: some View {
        MainInteraction3View()
    }
}
