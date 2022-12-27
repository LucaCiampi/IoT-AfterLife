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
    var firstSpheroInteraction1Name = "SB-0994"
    var secondSpheroInteraction1Name = "SB-42C1"
    
    @State var spheroConnectionString = "No sphero connected"
    @State var isConnectedToSpheros = false
    
    @State var firstSpheroCurrentSituationString = "Checking if sphero is rotating"
    @State var firstSpheroHasRotated = false
    @State var firstSpheroHasClashed = false
    
    @State var secondSpheroCurrentSituationString = "Checking if sphero is rotating"
    @State var secondSpheroHasRotated = false
    @State var secondSpheroHasClashed = false
    
    var body: some View {
        VStack {
            VStack {
                Text(spheroConnectionString)
                Button("Connect to spheros") {
                    SharedToyBox.instance.searchForBoltsNamed([firstSpheroInteraction1Name]) { err in
                        if err == nil {
                            self.spheroConnectionString = "Connected to " + firstSpheroInteraction1Name + " and " + secondSpheroInteraction1Name
                            isConnectedToSpheros = true
                        }
                    }
                }
            }.padding()
            
            if (isConnectedToSpheros) {
                HStack {
                    VStack {
                        Text(firstSpheroInteraction1Name)
                        Text(firstSpheroCurrentSituationString)
                    }.onAppear {
                        checkIfSpheroHasRotated(bolt: SharedToyBox.instance.bolts[0]) {
                            firstSpheroHasRotated = true
                        }
                    }.onChange(of: firstSpheroHasRotated, perform: { newValue in
                        SharedToyBox.instance.bolts[0].setMatrix(color: .red)
                        firstSpheroCurrentSituationString = "Checking if sphero has clashed"
                        checkIfSpheroHasClashed(bolt: SharedToyBox.instance.bolts[0]) {
                            firstSpheroHasClashed = true
                        }
                    }).onChange(of: firstSpheroHasClashed, perform: { newValue in
                        firstSpheroCurrentSituationString = "Activating leds band on cup"
                        activateLedsBand()
                        drawLetterOnMatrix(letter: "a", bolt: SharedToyBox.instance.bolts[0])
                    }).padding()
                    
                    /*
                    VStack {
                        Text(secondSpheroInteraction1Name)
                        Text(secondSpheroCurrentSituationString)
                    }.onAppear {
                        checkIfSpheroHasRotated(bolt: SharedToyBox.instance.bolts[1]) {
                            secondSpheroHasRotated = true
                        }
                    }.onChange(of: secondSpheroHasRotated, perform: { newValue in
                        SharedToyBox.instance.bolts[1].setMatrix(color: .red)
                        secondSpheroCurrentSituationString = "Checking if sphero has clashed"
                        checkIfSpheroHasClashed(bolt: SharedToyBox.instance.bolts[1]) {
                            secondSpheroHasClashed = true
                        }
                    }).onChange(of: secondSpheroHasClashed, perform: { newValue in
                        secondSpheroCurrentSituationString = "Activating leds band on cup"
                        activateLedsBand()
                        drawLetterOnMatrix(letter: "b", bolt: SharedToyBox.instance.bolts[1])
                    }).padding()
                    */
                }
            }
        }
    }
    
    /**
     Checks if the sphero bolt has done a 180 degrees flip to fill its screen
     */
    func checkIfSpheroHasRotated(bolt: BoltToy?, onRotation: @escaping (() -> ())) {
        var currentGyroData = [Double]()
        
        bolt?.sensorControl.enable(sensors: SensorMask.init(arrayLiteral: .gyro))
        bolt?.sensorControl.interval = 1
        bolt?.setStabilization(state: SetStabilization.State.off)
        bolt?.sensorControl.onDataReady = { data in
            
            DispatchQueue.main.async {
                if let gyro = data.gyro?.rotationRate {
                    // TOUJOURS PAS BIEN!!!
                    //let rotationRate: double3 = [Double(gyro.x!)/2000.0, Double(gyro.y!)/2000.0, Double(gyro.z!)/2000.0]
                    let rotationRate: Double = abs(Double(gyro.x!)/2000.0) + abs(Double(gyro.y!)/2000.0) + abs(Double(gyro.z!)/2000.0)
                    print(rotationRate)
                    if (rotationRate > 0.3) {
                        onRotation()
                    }
                    currentGyroData.append(contentsOf: [Double(gyro.x!), Double(gyro.y!), Double(gyro.z!)])
                }
            }
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
