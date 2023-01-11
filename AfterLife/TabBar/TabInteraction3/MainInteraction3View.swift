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
    
    @State var compatibleSpheroSpinning = false
    @State var uncompatibleSpheroSpinning = false
    
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
                                    bleInterface.connectToInteraction3Esp32()
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
                /*
                VStack {
                    Text(spheroConnectionString)
                    Button("Connect to spheros") {
                        SharedToyBox.instance.searchForBoltsNamed([spheroInteraction3Name, incompatibleSpheroInteraction3Name]) { err in
                            if err == nil {
                                self.spheroConnectionString = "Connected to spheros"
                                isConnectedToSphero = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    ActivateSpheroSensors(boltId: 0)
                                    ActivateSpheroSensors(boltId: 1)
                                }
                            }
                        }
                    }
                }
                */
            }.padding()
            
            VStack {
                HStack {
                    Button("Spin compatible") {
                        MakeSpheroSpin(boltId: 0)
                    }.padding()
                    Button("Stop compatible") {
                        StopSphero(boltId: 0)
                    }
                }
                HStack {
                    Button("Spin uncompatible") {
                        MakeSpheroSpin(boltId: 1)
                    }.padding()
                    Button("Stop uncompatible") {
                        StopSphero(boltId: 1)
                    }
                }
            }
            
            if (isShowingDetailView) {
                VStack {
                    Text(bleInterface.cuveDataReceived.last?.content ?? "silence")
                }.onAppear {
                    bleInterface.listenForCuveEsp32()
                }.onChange(of: bleInterface.cuveDataReceived.last?.content) { newValue in
                    if (newValue == "spin") {
                        compatibleSpheroSpinning = !compatibleSpheroSpinning
                        if (compatibleSpheroSpinning) {
                            MakeSpheroSpin(boltId: 0)
                        }
                        else {
                            StopSphero(boltId: 0)
                        }
                    }
                    else if (newValue == "pump") {
                        uncompatibleSpheroSpinning = !uncompatibleSpheroSpinning
                        if (uncompatibleSpheroSpinning) {
                            MakeSpheroSpin(boltId: 1)
                        }
                        else {
                            StopSphero(boltId: 1)
                        }
                    }
                    else {
                        print("message de l'ESP32 de la cuve non conforme")
                    }
                }
                .padding()
            }
        }
        .padding()
    }
    
    /**
     Init parameters before moving the sphero bolt
     */
    func ActivateSpheroSensors(boltId: Int) {
        //SharedToyBox.instance.bolts[boltId].sensorControl.enable(sensors: SensorMask.init(arrayLiteral: .accelerometer))
        //SharedToyBox.instance.bolts[boltId].sensorControl.interval = 1
        SharedToyBox.instance.bolts[boltId].setStabilization(state: SetStabilization.State.off)
    }
    
    /**
     Makes the sphero bolt rotate when placed in the pot
     */
    func MakeSpheroSpin(boltId: Int) {
        SharedToyBox.instance.bolts[boltId].sendTurnCommand()
    }
    
    /**
     Stops sphero movement
     */
    func StopSphero(boltId: Int) {
        SharedToyBox.instance.bolts[boltId].stopTurnCommand()
    }
}

struct MainInteraction3View_Previews: PreviewProvider {
    static var previews: some View {
        MainInteraction3View()
    }
}
