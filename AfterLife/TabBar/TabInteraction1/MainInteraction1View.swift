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
    @State var connectionString = "No ESP32 connected"
    @State var scanButtonString = "Start scan"
    @State var isScanningDevices = false
    @State var isConnectedToEsp = false
    
    
    // Spheros
    @State var isConnectedToSpheros = false
    @State var spheroConnectionString = "No sphero connected"
    
    var spherosInteraction1 = [
        SpheroInteraction1Struct(name: "SB-8C49", bloodGroup: "a"),
        //SpheroInteraction1Struct(name: "SB-5D1C", bloodGroup: "b"),
        //SpheroInteraction1Struct(name: "SB-42C1", bloodGroup: "o"),
        SpheroInteraction1Struct(name: "SB-0994", bloodGroup: "a"),
        SpheroInteraction1Struct(name: "SB-F682", bloodGroup: "ab")
    ]
    
    //var spheroInteraction2Name = "SB-2020"
    
    @State var spherosThatRotated: [UUID] = []
    @State var spherosThatClashed: [UUID] = []
    
    @State var spherosRotationReady = false
    @State var spherosClashingReady = false
    
    var body: some View {
        VStack {
            VStack {
                Text(spheroConnectionString)
                Button(!isConnectedToSpheros ? "Connect to spheros" : "Disconnect from spheros") {
                    if (!isConnectedToSpheros) {
                        print("Connection to spheros")
                        SharedToyBox.instance.searchForBoltsNamed(getAllSpherosToConnectTo()) { err in
                            if err == nil {
                                self.spheroConnectionString = "Connected to " + String(spherosInteraction1.count) + " spheros"
                                isConnectedToSpheros = true
                            }
                            else {
                                print("erreur connexion spheros")
                            }
                        }
                    }
                    else {
                        SharedToyBox.instance.bolts.forEach { bolt in
                            SharedToyBox.instance.box.disconnect(toy: bolt)
                        }
                        SharedToyBox.instance.boltsNames = []
                        isConnectedToSpheros = false
                        spheroConnectionString = "No sphero connected"
                    }
                }
                VStack {
                    Text(connectionString)
                    
                    if bleInterface.connectedPeripheral != nil {
                        Button("Disconnect") {
                            bleInterface.disconnectFrom(p: bleInterface.connectedPeripheral!)
                        }
                    }
                    
                    HStack {
                        if (!isConnectedToEsp) {
                            Button(scanButtonString) {
                                isScanningDevices = !isScanningDevices
                                if (isScanningDevices) {
                                    scanButtonString = "Stop scan"
                                    bleInterface.connectToInteraction1Esp32()
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
                            isConnectedToEsp = true
                        }
                        else {
                            connectionString = "No ESP32 connected"
                            isConnectedToEsp = false
                        }
                    }).onChange(of: bleInterface.connectionState, perform: { newValue in
                        switch newValue {
                        case .disconnected:
                            break
                        case .connecting:
                            connectionString = "Connecting... "
                            break
                        case .discovering:
                            connectionString = "Discovering... "
                            break
                        case .ready:
                            connectionString = "Connected to " + connectionString
                            break
                            
                        }
                    })
                }.padding()
            }.padding()
            /*
             HStack {
             Button("send to esp") {
             bleInterface.sendMessageToVerresESP32(message: "a")
             }
             }
             */
            if (isConnectedToSpheros) {
                VStack {
                    
                    // Rotation
                    if (spherosThatRotated.count != spherosInteraction1.count) {
                        if (!spherosRotationReady) {
                            Text("Loading spheros rotation").onAppear {
                                checkAllSpherosRotation()
                            }
                        }
                        else {
                            Text(String(spherosThatRotated.count) + "/" + String(spherosInteraction1.count) + " spheros rotated")
                        }
                    }
                    
                    // Clash
                    if (spherosThatRotated.count == spherosInteraction1.count) {
                        if (!spherosClashingReady) {
                            Text("Loading spheros clashing").onAppear {
                                checkAllSpherosClash()
                            }
                        }
                        else {
                            Text(String(spherosThatClashed.count) + "/" + String(spherosInteraction1.count) + " spheros clashed")
                        }
                    }
                    
                    // Disabling
                    if (spherosThatClashed.count == spherosInteraction1.count) {
                        Text("All spheros have clashed").onAppear {
                            for i in 0...(spherosInteraction1.count - 1) {
                                // removes data collection
                                DispatchQueue.main.asyncAfter(deadline: .now() + Double(1 + i)) {
                                    SharedToyBox.instance.bolts[i].sensorControl.disable()
                                }
                            }
                        }
                    }
                }.padding()
                
                // Emergency
                HStack {
                    Button("Skip rotation") {
                        skipRotation()
                    }.padding()
                    Button("Skip clash") {
                        skipClash()
                    }.padding()
                    Button("Turn spheros off") {
                        spherosOff()
                    }.padding()
                    Button("Turn leds off") {
                        bleInterface.sendMessageToVerresESP32(message: "off")
                    }.padding()
                }
            }
        }
    }
    
    /**
     Returns array of name of all spheros to connect to based on spherosInteraction1[]
     */
    func getAllSpherosToConnectTo() -> [String] {
        var returnArray: [String] = []
        
        spherosInteraction1.forEach { sphero in
            returnArray.append(sphero.name)
        }
        
        return returnArray
    }
    
    /**
     For each sphero, sends message to enable data collection related to spinning
     */
    func checkAllSpherosRotation() {
        spherosRotationReady = false
        
        for i in 0...(spherosInteraction1.count - 1) {
            // Waits 5 seconds before calling + "i" seconds based on index
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(5 + i)) {
                print("checking if sphero rotated #"+String(i))
                checkIfSpheroHasRotated(bolt: SharedToyBox.instance.bolts[i]) {
                    print(spherosInteraction1[i].name + " has rotated")
                    SharedToyBox.instance.bolts[i].setMatrix(color: .red)
                }
                
                if (i == (spherosInteraction1.count - 1)) {
                    spherosRotationReady = true
                }
            }
        }
    }
    
    /**
     For each sphero, sends message to enable data collection related to clashing
     */
    func checkAllSpherosClash() {
        spherosClashingReady = false
        
        for i in 0...(spherosInteraction1.count - 1) {
            // Waits 1 seconds before calling + "i" seconds based on index
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(1 + i)) {
                SharedToyBox.instance.bolts[i].sensorControl.disable()
                print("checking if sphero clashed #"+String(i))
                checkIfSpheroHasClashed(bolt: SharedToyBox.instance.bolts[i]) {
                    print(spherosInteraction1[i].name + " has clashed")
                    drawLetterOnMatrix(letter: spherosInteraction1[i].bloodGroup, bolt: SharedToyBox.instance.bolts[i])
                    
                    // Sends message to the ESP32 in order to light up the adequate led for the wine glass
                    bleInterface.sendMessageToVerresESP32(message: spherosInteraction1[i].bloodGroup)
                }
                
                if (i == (spherosInteraction1.count - 1)) {
                    spherosClashingReady = true
                }
            }
        }
    }
    
    /**
     Checks if the sphero bolt has done a 180 degrees flip to fill its screen
     */
    func checkIfSpheroHasRotated(bolt: BoltToy?, onRotation: @escaping (() -> ())) {
        print("checkIfSpheroHasRotated")
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
        print("checkIfSpheroHasClashed")
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
                        if absSum > 4.5 {
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
    
    /**
     Forces non-rotated spheros
     */
    func skipRotation() {
        for i in 0...(spherosInteraction1.count - 1) {
            if (!spherosThatRotated.contains(SharedToyBox.instance.bolts[i].identifier)) {
                spherosThatRotated.append(SharedToyBox.instance.bolts[i].identifier)
                SharedToyBox.instance.bolts[i].setMatrix(color: .red)
                print("Forced color red to bolt #" + String(i))
            }
        }
    }
    
    /**
     Forces non-clashed spheros
     */
    func skipClash() {
        for i in 0...(spherosInteraction1.count - 1) {
            if (!spherosThatClashed.contains(SharedToyBox.instance.bolts[i].identifier)) {
                spherosThatClashed.append(SharedToyBox.instance.bolts[i].identifier)
                SharedToyBox.instance.bolts[i].setMatrix(color: .red)
                drawLetterOnMatrix(letter: spherosInteraction1[i].bloodGroup, bolt: SharedToyBox.instance.bolts[i])
                print("Forced displaying letter to bolt #" + String(i))
            }
        }
    }
    
    /**
     Turns every sphero sensors and matrix off
     */
    func spherosOff() {
        spherosThatRotated = []
        spherosThatClashed = []
        
        for i in 0...(spherosInteraction1.count - 1) {
            SharedToyBox.instance.bolts[i].clearMatrix()
            SharedToyBox.instance.bolts[i].sensorControl.disable()
            print("disabled bolt #" + String(i))
        }
    }
}

struct MainInteraction1View_Previews: PreviewProvider {
    static var previews: some View {
        MainInteraction1View()
    }
}
