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
    @Binding public var startMicroscopeVideo: Bool
    
    @State var connectionString = "No sphero connected"
    @State var isScanningDevices = false
    @State var isShowingDetailView = false
    
    let spheroInteraction2Name = "SB-2020"
    
    @State var spheroHasMoved = false
    @State var leverTimeEnded = false
    @State var leverBackToPosition = false
    
    var body: some View {
        VStack {
            Text("IPAD ONLY")
            Text(connectionString)
            Button("Connect to sphero " + spheroInteraction2Name) {
                SharedToyBox.instance.searchForBoltsNamed([spheroInteraction2Name]) { err in
                    if err == nil {
                        self.connectionString = "Connected to " + spheroInteraction2Name
                        isShowingDetailView = true
                    }
                }
            }
            
            Button("Go full screen") {
                showModal = true
            }.padding()
            
            if (isShowingDetailView) {
                Text(spheroHasMoved ? "Lever has been activated" : "Lever hasn't been activated").onAppear {
                    if (!spheroHasMoved) {
                        self.retrieveSpheroMovements(boltId: (0))
                    }
                }.onChange(of: spheroHasMoved) { newValue in
                    startVideo = true
                }
            }
        }
        .padding()
    }
    
    /**
     Retrieves movement of the lever sphero
     */
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
                        print("absSum > 1.7")
                        leverHasMoved()
                    }
                }
            }
        }
    }
    
    /**
     Assigns action corresponding to the video playing
     */
    func leverHasMoved() {
        spheroHasMoved = true;
        if (!leverTimeEnded) {
            // Plays video glasses filling
            print("Plays video glasses filling")
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                leverTimeEnded = true
            }
        }
        else if (leverTimeEnded && !leverBackToPosition) {
            // Stops filling glasses and displays microscope vision
            print("Stops filling glasses and displays microscope vision")
            leverBackToPosition = true
            playSecondVideo()
        }
    }
    
    /**
     Plays the video of the microscope
     */
    func playSecondVideo() {
        startMicroscopeVideo = true
    }
}
