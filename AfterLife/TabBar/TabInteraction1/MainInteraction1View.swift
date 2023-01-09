//
//  MainCircleView.swift
//  SwiftUI_FullApp
//
//  Created by Hugues Capet on 07.11.22.
//

import SwiftUI
import simd

struct SpheroInteraction1Struct:  Equatable {
    static func == (lhs: SpheroInteraction1Struct, rhs: SpheroInteraction1Struct) -> Bool {
        return true
    }
    
    var name: String
    var bloodGroup: String
    @State var hasRotated = false
    @State var hasClashed = false
}

struct MainInteraction1View: View {
    
    @EnvironmentObject var bleInterface: BLEObservable
    
    // ESP32
    @State var connectionString = "No device connected"
    @State var isScanningDevices = false
    @State var isConnectedToSpheros = false
    
    // Spheros
    var spherosInteraction1 = [
        SpheroInteraction1Struct(name: "SB-0994", bloodGroup: "a"),
        SpheroInteraction1Struct(name: "SB-42C1", bloodGroup: "b")
    ]
    
    //@State var spherosInteraction1Rotation = [false, false]
    //@State var spherosInteraction1Clash = [false, false]
    
    @State var spheroConnectionString = "No sphero connected"
    
    var body: some View {
        VStack {
            VStack {
                Text(spheroConnectionString)
                Button("Connect to spheros") {
                    SharedToyBox.instance.searchForBoltsNamed([spherosInteraction1[0].name, spherosInteraction1[1].name]) { err in
                        if err == nil {
                            self.spheroConnectionString = "Connected to " + String(spherosInteraction1.count) + " spheros"
                            isConnectedToSpheros = true
                            print(SharedToyBox.instance.bolts[0].identifier)
                            print(SharedToyBox.instance.bolts[1].identifier)
                        }
                        else {
                            print(err)
                        }
                    }
                }
            }.padding()
            
            if (isConnectedToSpheros) {
                VStack {
                    Text(String(spherosInteraction1.count) + " spheros have rotated")
                    Button("check rotation spheros") {
                        for i in 0...1 {
                            // Checks if sphero i has rotated
                            if (spherosInteraction1[i].hasRotated == false) {
                                // Checks rotation of sphero i
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    checkIfSpheroHasRotated(bolt: SharedToyBox.instance.bolts[i]) {
                                        spherosInteraction1[i].hasRotated = true
                                        print(spherosInteraction1[i].name + " has rotated")
                                    }
                                }
                            }
                            // Checks clash of sphero i
                            else if (spherosInteraction1[i].hasRotated) {
                                SharedToyBox.instance.bolts[i].setMatrix(color: .red)
                                print("Checking if sphero " + spherosInteraction1[i].name + " has clashed")
                                checkIfSpheroHasClashed(bolt: SharedToyBox.instance.bolts[i]) {
                                    spherosInteraction1[i].hasClashed = true
                                }
                            }
                            // Prints letter on sphero i
                            else if (spherosInteraction1[i].hasClashed) {
                                print("Activating leds band on cup " + spherosInteraction1[i].name)
                                activateLedsBand()
                                drawLetterOnMatrix(letter: spherosInteraction1[i].bloodGroup, bolt: SharedToyBox.instance.bolts[i])
                            }
                        }
                    }
                }.padding()
            }
        }
    }
    
    /**
     Checks if the sphero bolt has done a 180 degrees flip to fill its screen
     */
    func checkIfSpheroHasRotated(bolt: BoltToy?, onRotation: @escaping (() -> ())) {
        var currentGyroData = [Double]()
        
        if (bolt != nil) {
            print(bolt?.identifier)
            bolt?.sensorControl.enable(sensors: SensorMask.init(arrayLiteral: .gyro))
            bolt?.sensorControl.interval = 1
            bolt?.setStabilization(state: SetStabilization.State.off)
            bolt?.sensorControl.onDataReady = { data in
                //print(data)
                DispatchQueue.main.async {
                    if let gyro = data.gyro?.rotationRate {
                        let rotationRate: Double = abs(Double(gyro.x!)/2000.0) + abs(Double(gyro.y!)/2000.0) + abs(Double(gyro.z!)/2000.0)
                        print(rotationRate)
                        //if (rotationRate > 0.3) {
                        if (rotationRate > 0.1) {
                            onRotation()
                        }
                        currentGyroData.append(contentsOf: [Double(gyro.x!), Double(gyro.y!), Double(gyro.z!)])
                    }
                }
            }
        }
        else {
            print("bolt introuvable")
        }
    }
    
    /**
     Checks if sphero has clashed with something (should be with another sphero)
     */
    func checkIfSpheroHasClashed(bolt: BoltToy?, onClash: @escaping (() -> ())) {
        //var currentAccData = [Double]()
        
        bolt?.sensorControl.enable(sensors: SensorMask.init(arrayLiteral: .accelerometer))
        bolt?.sensorControl.interval = 1
        bolt?.setStabilization(state: SetStabilization.State.off)
        bolt?.sensorControl.onDataReady = { data in
            
            DispatchQueue.main.async {
                if let acceleration = data.accelerometer?.filteredAcceleration {
                    
                    // checks secousse
                    let absSum = abs(acceleration.x!)+abs(acceleration.y!)+abs(acceleration.z!)
                    print(absSum)
                    
                    if absSum > 3.7 {
                        print("Secousse")
                        onClash()
                    }
                }
            }
        }
    }
    
    func activateLedsBand() {
        print("activating leds band")
    }
    
    func drawLetterOnMatrix(letter: String, bolt: BoltToy) {
        switch letter {
        case "a":
            bolt.drawMatrixLine(from: Pixel(x: 3, y: 0), to: Pixel(x: 4, y: 0), color: .white)
            bolt.drawMatrix(pixel: Pixel(x: 2, y: 1), color: .white)
            bolt.drawMatrix(pixel: Pixel(x: 5, y: 1), color: .white)
            bolt.drawMatrixLine(from: Pixel(x: 1, y: 2), to: Pixel(x: 1, y: 7), color: .white)
            bolt.drawMatrixLine(from: Pixel(x: 6, y: 2), to: Pixel(x: 6, y: 7), color: .white)
            bolt.drawMatrixLine(from: Pixel(x: 2, y: 4), to: Pixel(x: 5, y: 4), color: .white)
        case "b":
            bolt.drawMatrixLine(from: Pixel(x: 6, y: 0), to: Pixel(x: 6, y: 7), color: .white)
            bolt.drawMatrixLine(from: Pixel(x: 2, y: 0), to: Pixel(x: 5, y: 0), color: .white)
            bolt.drawMatrixLine(from: Pixel(x: 2, y: 3), to: Pixel(x: 5, y: 3), color: .white)
            bolt.drawMatrixLine(from: Pixel(x: 2, y: 7), to: Pixel(x: 5, y: 7), color: .white)
            bolt.drawMatrixLine(from: Pixel(x: 1, y: 1), to: Pixel(x: 1, y: 2), color: .white)
            bolt.drawMatrixLine(from: Pixel(x: 1, y: 4), to: Pixel(x: 1, y: 6), color: .white)
        case "o":
            bolt.drawMatrixLine(from: Pixel(x: 6, y: 1), to: Pixel(x: 6, y: 6), color: .white)
            bolt.drawMatrixLine(from: Pixel(x: 1, y: 1), to: Pixel(x: 1, y: 6), color: .white)
            bolt.drawMatrixLine(from: Pixel(x: 2, y: 0), to: Pixel(x: 5, y: 0), color: .white)
            bolt.drawMatrixLine(from: Pixel(x: 2, y: 7), to: Pixel(x: 5, y: 7), color: .white)
        case "ab":
            bolt.drawMatrixLine(from: Pixel(x: 7, y: 1), to: Pixel(x: 7, y: 7), color: .white)
            bolt.drawMatrixLine(from: Pixel(x: 4, y: 1), to: Pixel(x: 4, y: 7), color: .white)
            bolt.drawMatrixLine(from: Pixel(x: 5, y: 0), to: Pixel(x: 6, y: 0), color: .white)
            bolt.drawMatrixLine(from: Pixel(x: 5, y: 3), to: Pixel(x: 6, y: 3), color: .white)
            bolt.drawMatrixLine(from: Pixel(x: 3, y: 0), to: Pixel(x: 3, y: 7), color: .white)
            bolt.drawMatrixLine(from: Pixel(x: 1, y: 0), to: Pixel(x: 2, y: 0), color: .white)
            bolt.drawMatrixLine(from: Pixel(x: 1, y: 3), to: Pixel(x: 2, y: 3), color: .white)
            bolt.drawMatrixLine(from: Pixel(x: 1, y: 7), to: Pixel(x: 2, y: 7), color: .white)
            bolt.drawMatrixLine(from: Pixel(x: 0, y: 1), to: Pixel(x: 0, y: 2), color: .white)
            bolt.drawMatrixLine(from: Pixel(x: 0, y: 4), to: Pixel(x: 0, y: 6), color: .white)
        default:
            print("unkown letter to draw")
        }
    }
}

struct MainInteraction1View_Previews: PreviewProvider {
    static var previews: some View {
        MainInteraction1View()
    }
}
