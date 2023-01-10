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
}

struct MainInteraction1View: View {
    
    @EnvironmentObject var bleInterface: BLEObservable
    
    // ESP32
    @State var connectionString = "No device connected"
    @State var isScanningDevices = false
    @State var isConnectedToSpheros = false
    
    // Spheros
    var spherosInteraction1 = [
        SpheroInteraction1Struct(name: "SB-8C49", bloodGroup: "a"),
        SpheroInteraction1Struct(name: "SB-5D1C", bloodGroup: "b"),
        SpheroInteraction1Struct(name: "SB-42C1", bloodGroup: "o"),
        SpheroInteraction1Struct(name: "SB-F682", bloodGroup: "ab"),
        //SpheroInteraction1Struct(name: "SB-6C4C", bloodGroup: "a")
    ]
    
    @State var spherosThatRotated: [UUID] = []
    @State var spherosThatClashed: [UUID] = []
    
    //@State var spherosInteraction1Rotation = [false, false]
    //@State var spherosInteraction1Clash = [false, false]
    
    @State var spheroConnectionString = "No sphero connected"
    
    var body: some View {
        VStack {
            VStack {
                Text(spheroConnectionString)
                Button("Connect to spheros") {
                    SharedToyBox.instance.searchForBoltsNamed([spherosInteraction1[0].name, spherosInteraction1[1].name, spherosInteraction1[2].name, spherosInteraction1[3].name]) { err in
                        if err == nil {
                            self.spheroConnectionString = "Connected to " + String(spherosInteraction1.count) + " spheros"
                            isConnectedToSpheros = true
                        }
                        else {
                            print("erreur connexion spheros")
                        }
                    }
                }
            }.padding()
            
            if (isConnectedToSpheros) {
                VStack {
                    if (spherosThatRotated.count != spherosInteraction1.count) {
                        Text(String(spherosThatRotated.count) + "/" + String(spherosInteraction1.count) + " spheros rotated").onAppear {
                            for i in 0...(spherosInteraction1.count - 1) {
                                
                                // Checks rotation of sphero i
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    
                                    checkIfSpheroHasRotated(bolt: SharedToyBox.instance.bolts[i]) {
                                        print(spherosInteraction1[i].name + " has rotated")
                                        SharedToyBox.instance.bolts[i].setMatrix(color: .red)
                                    }
                                    
                                    sleep(1)
                                }
                                
                            }
                        }
                    }
                    if (spherosThatRotated.count == spherosInteraction1.count) {
                        Text(String(spherosThatClashed.count) + "/" + String(spherosInteraction1.count) + " spheros clashed").onAppear {
                            for i in 0...(spherosInteraction1.count - 1) {
                                
                                // Checks clashing of sphero i
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    
                                    checkIfSpheroHasClashed(bolt: SharedToyBox.instance.bolts[i]) {
                                        print(spherosInteraction1[i].name + " has clashed")
                                        drawLetterOnMatrix(letter: spherosInteraction1[i].bloodGroup, bolt: SharedToyBox.instance.bolts[i])
                                    }
                                    
                                    sleep(1)
                                }
                            }
                        }
                    }
                    if (spherosThatClashed.count == spherosInteraction1.count) {
                        Text("All spheros have clashed").onAppear {
                            for i in 0...(spherosInteraction1.count - 1) {
                                // removes data collection
                                SharedToyBox.instance.bolts[i].sensorControl.disable()
                                sleep(1)
                            }
                        }
                    }
                }.padding()
                
                // Emergency
                HStack {
                    Button("Skip rotation") {
                        for i in 0...(spherosInteraction1.count - 1) {
                            spherosThatRotated.append(SharedToyBox.instance.bolts[i].identifier)
                            SharedToyBox.instance.bolts[i].setMatrix(color: .red)
                            print("set color red to bolt #" + String(i))
                        }
                    }.padding()
                    Button("Skip clash") {
                        for i in 0...(spherosInteraction1.count - 1) {
                            spherosThatClashed.append(SharedToyBox.instance.bolts[i].identifier)
                            drawLetterOnMatrix(letter: spherosInteraction1[i].bloodGroup, bolt: SharedToyBox.instance.bolts[i])
                            print("displayed letter to bolt #" + String(i))
                        }
                    }.padding()
                    Button("Turn off") {
                        for i in 0...(spherosInteraction1.count - 1) {
                            SharedToyBox.instance.bolts[i].clearMatrix()
                            SharedToyBox.instance.bolts[i].sensorControl.disable()
                            print("disabled bolt #" + String(i))
                        }
                    }.padding()
                }
            }
        }
    }
    
    /**
     Checks if the sphero bolt has done a 180 degrees flip to fill its screen
     */
    func checkIfSpheroHasRotated(bolt: BoltToy?, onRotation: @escaping (() -> ())) {
        if let bolt = bolt {
            
            bolt.sensorControl.enable(sensors: SensorMask.init(arrayLiteral: .gyro))
            bolt.sensorControl.interval = 1
            bolt.setStabilization(state: SetStabilization.State.off)
            
            bolt.sensorControl.onDataReady = { data in
                DispatchQueue.main.async {
                    if let gyro = data.gyro?.rotationRate {
                        let rotationRate: Double = abs(Double(gyro.x!)/2000.0) + abs(Double(gyro.y!)/2000.0) + abs(Double(gyro.z!)/2000.0)
                        
                        // If rotation rate is too important, sphero has been rotated 180 degrees
                        if (rotationRate > 0.3) {
                            // Adding the sphero UUID to array of spheros that rotated
                            if !self.spherosThatRotated.contains(bolt.identifier) {
                                self.spherosThatRotated.append(bolt.identifier)
                                onRotation()
                            }
                            return
                        }
                    }
                }
            }
        }
    }
    
    /**
     Checks if sphero has clashed with something (should be with another sphero)
     */
    func checkIfSpheroHasClashed(bolt: BoltToy?, onClash: @escaping (() -> ())) {
        if let bolt = bolt {
            
            bolt.sensorControl.enable(sensors: SensorMask.init(arrayLiteral: .accelerometer))
            bolt.sensorControl.interval = 1
            bolt.setStabilization(state: SetStabilization.State.off)
            bolt.sensorControl.onDataReady = { data in
                
                DispatchQueue.main.async {
                    if let acceleration = data.accelerometer?.filteredAcceleration {
                        
                        // checks secousse
                        let absSum = abs(acceleration.x!)+abs(acceleration.y!)+abs(acceleration.z!)
                        
                        // If sphero is shaking too much, add to array of clashed spheros
                        if absSum > 3.7 {
                            if !self.spherosThatClashed.contains(bolt.identifier) {
                                self.spherosThatClashed.append(bolt.identifier)
                                onClash()
                            }
                            return
                        }
                    }
                }
            }
        }
    }
    
    /**
     Activates led band
     */
    func activateLedsBand() {
        print("activating leds band")
    }
    
    /**
     Draws the blood type letter on the sphero bolt screen
     */
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
