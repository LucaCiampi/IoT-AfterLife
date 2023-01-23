//
//  MainSquareView.swift
//  SwiftUI_FullApp
//
//  Created by Hugues Capet on 07.11.22.
//

import SwiftUI

struct MainInteraction3View: View {
    
    @EnvironmentObject var bleInterface: BLEObservable
    
    @State var connectionString = "No ESP32 connected"
    @State var scanButtonString = "Start scan"
    @State var isScanningDevices = false
    @State var isShowingDetailView = false
    
    @State var isCurrentlyIncompatibleSphero = false
    @State var compatibleSpheroSpinning = false
    @State var uncompatibleSpheroSpinning = false
    
    @State var compatibleSpheroId: Int = 0
    @State var uncompatibleSpheroId: Int = 1
    
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
                        MakeCompatibleSpheroSpin()
                    }.padding()
                    Button("Stop compatible") {
                        StopCompatibleSphero()
                    }
                }
                HStack {
                    Text(isCurrentlyIncompatibleSphero ? "incompatible en cours" : "compatible en cours").padding()
                    Button("Switch excepted sphero") {
                        isCurrentlyIncompatibleSphero = !isCurrentlyIncompatibleSphero
                    }
                }
                HStack {
                    Button("Spin uncompatible") {
                        MakeUncompatibleSpheroSpin()
                    }.padding()
                    Button("Stop uncompatible") {
                        StopUncompatibleSphero()
                    }
                }
            }
            
            if (isShowingDetailView) {
                VStack {
                    Text(bleInterface.cuveDataReceived.last?.content ?? "silence")
                }.onAppear {
                    RetrieveCompatibleAndUncompatibleSpherosId()
                    bleInterface.listenForCuveEsp32()
                }.onChange(of: bleInterface.cuveDataReceived.last) { newValue in
                    if (newValue?.content == "spin" && !isCurrentlyIncompatibleSphero) {
                        if (!compatibleSpheroSpinning) {
                            MakeCompatibleSpheroSpin()
                        }
                        else {
                            StopCompatibleSphero()
                            isCurrentlyIncompatibleSphero = true
                        }
                    }
                    //else if (newValue?.content == "pump") {
                    else if (newValue?.content == "spin" && isCurrentlyIncompatibleSphero) {
                        if (!uncompatibleSpheroSpinning) {
                            MakeUncompatibleSpheroSpin()
                        }
                        else {
                            StopUncompatibleSphero()
                            isCurrentlyIncompatibleSphero = false
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
     Gets the spheros id in array
     */
    func RetrieveCompatibleAndUncompatibleSpherosId() {
        print("RetrieveCompatibleAndUncompatibleSpherosId")
        for i in 0...(SharedToyBox.instance.bolts.count - 1) {
            if (SharedToyBox.instance.bolts[i].bloodGroup == "a") {
                compatibleSpheroId = i
                print("compatibleSpheroId = " + String(i))
            }
            else if (SharedToyBox.instance.bolts[i].bloodGroup == "o") {
                uncompatibleSpheroId = i
                print("uncompatibleSpheroId = " + String(i))
            }
        }
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
     Makes the compatible sphero bolt rotate when placed in the pot
     */
    func MakeCompatibleSpheroSpin() {
        print("MakeCompatibleSpheroSpin for")
        print(SharedToyBox.instance.bolts[compatibleSpheroId].identifier)
        SharedToyBox.instance.bolts[compatibleSpheroId].sendTurnCommand()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            compatibleSpheroSpinning = true
        }
    }
    
    /**
     Stops compatible sphero movement
     */
    func StopCompatibleSphero() {
        print("StopCompatibleSphero for")
        print(SharedToyBox.instance.bolts[compatibleSpheroId].identifier)
        SharedToyBox.instance.bolts[compatibleSpheroId].stopTurnCommand()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            compatibleSpheroSpinning = false
        }
    }
    
    /**
     Makes the uncompatible sphero bolt rotate when placed in the pot
     */
    func MakeUncompatibleSpheroSpin() {
        print("MakeUncompatibleSpheroSpin for")
        print(SharedToyBox.instance.bolts[uncompatibleSpheroId].identifier)
        SharedToyBox.instance.bolts[uncompatibleSpheroId].sendTurnCommand()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            uncompatibleSpheroSpinning = true
        }
    }
    
    /**
     Stops uncompatible sphero movement
     */
    func StopUncompatibleSphero() {
        print("StopUncompatibleSphero")
        print(SharedToyBox.instance.bolts[uncompatibleSpheroId].identifier)
        SharedToyBox.instance.bolts[uncompatibleSpheroId].stopTurnCommand()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            uncompatibleSpheroSpinning = false
        }
    }
}

struct MainInteraction3View_Previews: PreviewProvider {
    static var previews: some View {
        MainInteraction3View()
    }
}
