//
//  MainCircleView.swift
//  SwiftUI_FullApp
//
//  Created by Hugues Capet on 07.11.22.
//

import SwiftUI
import simd
import AVKit

struct MainInteraction2View: View {
    
    @EnvironmentObject var bleInterface: BLEObservable
    @Binding public var showModal: Bool
    @Binding public var startVideo: Bool
    
    @State var connectionString = "No device connected"
    @State var isScanningDevices = false
    @State var isShowingDetailView = false
    
    let spheroInteraction2Name = "SB-2020"
    
    @State var spheroHasMoved = false
    
    var body: some View {
        VStack {
            Text(connectionString)
            Button("Connect to sphero " + spheroInteraction2Name) {
                SharedToyBox.instance.searchForBoltsNamed([spheroInteraction2Name]) { err in
                    if err == nil {
                        self.connectionString = "Connected to " + spheroInteraction2Name
                        isShowingDetailView = true
                    }
                }
            }.padding()
            
            Button("Go full screen") {
                showModal = true
            }.padding()
            
            if (isShowingDetailView) {
                Text(spheroHasMoved ? "Lever has been activated" : "Lever hasn't been activated").onAppear {
                    if (!spheroHasMoved) {
                        self.retrieveSpheroMovements(boltId: 0)
                    }
                }.onChange(of: spheroHasMoved) { newValue in
                    startVideo = true
                }
            }
        }
        .padding()
    }
    
    func retrieveSpheroMovements(boltId: Int) {
        SharedToyBox.instance.bolts[boltId].sensorControl.enable(sensors: SensorMask.init(arrayLiteral: .accelerometer,.gyro))
        SharedToyBox.instance.bolts[boltId].sensorControl.interval = 1
        SharedToyBox.instance.bolts[boltId].setStabilization(state: SetStabilization.State.off)
        SharedToyBox.instance.bolts[boltId].sensorControl.onDataReady = { data in
            
            DispatchQueue.main.async {
                if let acceleration = data.accelerometer?.filteredAcceleration {
                    
                    // checks secousse
                    let absSum = abs(acceleration.x!)+abs(acceleration.y!)+abs(acceleration.z!)
                    
                    if absSum > 1.7 {
                        print("Lever activated")
                        spheroHasMoved = true
                        // v ?
                        SharedToyBox.instance.bolts[boltId].sensorControl.disable()
                    }
                }
                /*
                 if let gyro = data.gyro?.rotationRate {
                 // TOUJOURS PAS BIEN!!!
                 let rotationRate: double3 = [Double(gyro.x!)/2000.0, Double(gyro.y!)/2000.0, Double(gyro.z!)/2000.0]
                 }
                 */
            }
        }
    }
}
