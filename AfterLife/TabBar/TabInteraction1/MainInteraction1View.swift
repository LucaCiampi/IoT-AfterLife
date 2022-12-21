//
//  MainCircleView.swift
//  SwiftUI_FullApp
//
//  Created by Hugues Capet on 07.11.22.
//

import SwiftUI
import simd

struct MainInteraction1View: View {
    
    @EnvironmentObject var bleInterface: BLEObservable
    
    // ESP32
    @State var connectionString = "No device connected"
    @State var isScanningDevices = false
    
    // Spheros
    var spheroInteraction1Name = "SB-8C49"
    
    @State var spheroConnectionString = "No sphero connected"
    @State var isConnectedToSphero = false
    
    @State var spheroCurrentSituationString = "Checking if sphero is rotating"
    @State var spheroHasRotated = false
    @State var spheroHasClashed = false
    
    var body: some View {
        VStack {
            VStack {
                Text(spheroConnectionString)
                Button("Connect to sphero " + spheroInteraction1Name) {
                    SharedToyBox.instance.searchForBoltsNamed([spheroInteraction1Name]) { err in
                        if err == nil {
                            self.spheroConnectionString = "Connected to " + spheroInteraction1Name
                            isConnectedToSphero = true
                        }
                    }
                }
            }.padding()
            
            if (isConnectedToSphero) {
                VStack {
                    Text(spheroCurrentSituationString)
                }.onAppear {
                    checkIfSpheroHasRotated()
                }.onChange(of: spheroHasRotated, perform: { newValue in
                    spheroCurrentSituationString = "Checking if sphero has clashed"
                    checkIfSpheroHasClashed()
                }).onChange(of: spheroHasClashed, perform: { newValue in
                    spheroCurrentSituationString = "Activating leds band on cup"
                    activateLedsBand()
                }).padding()
            }
        }
    }
    
    /**
     Checks if the sphero bolt has done a 180 degrees flip to fill its screen
     */
    func checkIfSpheroHasRotated() {
        var currentGyroData = [Double]()
        
        SharedToyBox.instance.bolt?.sensorControl.enable(sensors: SensorMask.init(arrayLiteral: .gyro))
        SharedToyBox.instance.bolt?.sensorControl.interval = 1
        SharedToyBox.instance.bolt?.setStabilization(state: SetStabilization.State.off)
        SharedToyBox.instance.bolt?.sensorControl.onDataReady = { data in
            
            DispatchQueue.main.async {
                if let gyro = data.gyro?.rotationRate {
                    // TOUJOURS PAS BIEN!!!
                    //let rotationRate: double3 = [Double(gyro.x!)/2000.0, Double(gyro.y!)/2000.0, Double(gyro.z!)/2000.0]
                    let rotationRate: Double = abs(Double(gyro.x!)/2000.0) + abs(Double(gyro.y!)/2000.0) + abs(Double(gyro.z!)/2000.0)
                    print(rotationRate)
                    if (rotationRate > 0.1) {
                        spheroHasRotated = true
                    }
                    currentGyroData.append(contentsOf: [Double(gyro.x!), Double(gyro.y!), Double(gyro.z!)])
                }
            }
        }
    }
    
    /**
     Checks if sphero has clashed with something (should be with another sphero)
     */
    func checkIfSpheroHasClashed() {
        //var currentAccData = [Double]()
        
        SharedToyBox.instance.bolt?.sensorControl.enable(sensors: SensorMask.init(arrayLiteral: .accelerometer))
        SharedToyBox.instance.bolt?.sensorControl.interval = 1
        SharedToyBox.instance.bolt?.setStabilization(state: SetStabilization.State.off)
        SharedToyBox.instance.bolt?.sensorControl.onDataReady = { data in
            
            DispatchQueue.main.async {
                if let acceleration = data.accelerometer?.filteredAcceleration {
                    
                    // checks secousse
                    let absSum = abs(acceleration.x!)+abs(acceleration.y!)+abs(acceleration.z!)
                    print(absSum)
                    
                    if absSum > 3.7 {
                        print("Secousse")
                        spheroHasClashed = true
                    }
                }
            }
        }
    }
    
    func activateLedsBand() {
        print("activating leds band")
    }
}

struct MainInteraction1View_Previews: PreviewProvider {
    static var previews: some View {
        MainInteraction1View()
    }
}
