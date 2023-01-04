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
    
    @State var connectionString = "No device connected"
    @State var isScanningDevices = false
    @State var isShowingDetailView = false
    
    var spheroInteraction2Name = "SB-5D1C"
    
    @State var spheroMovementString = "Lever hasn't been activated"
    @State var spheroHasMoved = false
    
    let videoUrl = Bundle.main.url(forResource: "test", withExtension: "mp4")!
    
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
            }
            
            if (isShowingDetailView) {
                VStack {
                    Text(spheroMovementString).onAppear {
                        if (!spheroHasMoved) {
                            self.retrieveSpheroMovements()
                        }
                    }
                }.onChange(of: spheroHasMoved) { newValue in
                    spheroMovementString = "Lever has been activated !"
                }
            }
            if (spheroHasMoved) {
                HStack {
                    VideoPlayer(player: AVPlayer(url: videoUrl))
                }
            }
            
        }
        .padding()
    }
    
    func retrieveSpheroMovements() {
        var currentAccData = [Double]()
        var currentGyroData = [Double]()
        
        SharedToyBox.instance.bolt?.sensorControl.enable(sensors: SensorMask.init(arrayLiteral: .accelerometer,.gyro))
        SharedToyBox.instance.bolt?.sensorControl.interval = 1
        SharedToyBox.instance.bolt?.setStabilization(state: SetStabilization.State.off)
        SharedToyBox.instance.bolt?.sensorControl.onDataReady = { data in
            
            DispatchQueue.main.async {
                if let acceleration = data.accelerometer?.filteredAcceleration {
                    
                    // checks secousse
                    let absSum = abs(acceleration.x!)+abs(acceleration.y!)+abs(acceleration.z!)
                    
                    if absSum > 1.7 {
                        print("Secousse")
                        spheroHasMoved = true
                    }
                }
                
                if let aaaa = data.verticalAcceleration {
                    print(aaaa)
                }
                
                if let gyro = data.gyro?.rotationRate {
                    // TOUJOURS PAS BIEN!!!
                    let rotationRate: double3 = [Double(gyro.x!)/2000.0, Double(gyro.y!)/2000.0, Double(gyro.z!)/2000.0]
                    currentGyroData.append(contentsOf: [Double(gyro.x!), Double(gyro.y!), Double(gyro.z!)])
                }
            }
        }
        
    }
    
    func playVideo() {
        //TODO
    }
}


struct MainInteraction2View_Previews: PreviewProvider {
    static var previews: some View {
        MainInteraction2View()
    }
}
