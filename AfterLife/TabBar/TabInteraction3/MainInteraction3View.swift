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
    
    @State var spheroConnectionString = "No sphero connected"
    @State var isConnectedToSphero = false
    
    var esp32Interaction3Name = "rfid-luca"
    var spheroInteraction2Name = "SB-5D1C"
    
    @State var currentHeading: Double = 0
    
    var body: some View {
        VStack {
            HStack {
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
                                    bleInterface.connectToPeriphWithName(name: esp32Interaction3Name)
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
                VStack {
                    Text(spheroConnectionString)
                    Button("Connect to sphero " + spheroInteraction2Name) {
                        SharedToyBox.instance.searchForBoltsNamed([spheroInteraction2Name]) { err in
                            if err == nil {
                                self.spheroConnectionString = "Connected to " + spheroInteraction2Name
                                isConnectedToSphero = true
                                ActivateSpheroSensors()
                            }
                        }
                    }
                }
            }.padding()
            
            if (isShowingDetailView) {
                VStack {
                    Text("currentHeading : " + String(format: "%.1f", currentHeading))
                }.onChange(of: isConnectedToSphero) { newValue in
                    MakeSpheroSpin()
                }.padding()
            }
        }
        .padding()
    }
    
    /**
     Init parameters before moving the sphero bolt
     */
    func ActivateSpheroSensors() {
        SharedToyBox.instance.bolt?.sensorControl.enable(sensors: SensorMask.init(arrayLiteral: .accelerometer))
        SharedToyBox.instance.bolt?.sensorControl.interval = 1
        SharedToyBox.instance.bolt?.setStabilization(state: SetStabilization.State.off)
    }
    
    /**
     Makes the sphero bolt rotate when placed in the pot
     */
    func MakeSpheroSpin() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
            currentHeading += 180.0
            SharedToyBox.instance.bolt?.roll(heading: currentHeading, speed: 10)
            print("MakeSpheroSpin")
        })
    }
}

struct MainInteraction3View_Previews: PreviewProvider {
    static var previews: some View {
        MainInteraction3View()
    }
}
