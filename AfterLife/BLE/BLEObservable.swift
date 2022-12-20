//
//  BLEObservable.swift
//  SwiftUI_BLE
//
//  Created by Hugues Capet on 28.10.22.
//

import Foundation
import CoreBluetooth

struct Periph: Identifiable, Equatable {
    var id = UUID().uuidString
    var blePeriph: CBPeripheral
    
    var name: String
}

class BLEObservable: ObservableObject {
    
    @Published var points: [LineChartDataPoint] = []
    @Published var hasLessThanHundredPoints: Bool = true
    //@Published var cities: [CityListElement] = []
    //@Published var history: [HistoryListElement] = []
    
    enum ConnectionState {
        case disconnected, connecting, discovering, ready
    }
    
    @Published var periphList: [Periph] = []
    @Published var connectedPeripheral: Periph? = nil
    @Published var connectionState: ConnectionState = .disconnected
    
    let stopCitiesMessage = "stopCities"
    
    init() {
        _ = BLEManager.instance
    }
    
    func startScan() {
        BLEManager.instance.scan { p, pname  in
            var periph = Periph(blePeriph: p, name: pname)
            if !self.periphList.contains(periph) {
                self.periphList.append(periph)
                periph.name = pname
            }
        }
    }
    
    func stopScan() {
        BLEManager.instance.stopScan()
    }
    
    func connectTo(p: Periph) {
        self.connectionState = .connecting
        
        BLEManager.instance.connectPeripheral(p.blePeriph) { cbPeriph in
            self.connectionState = .discovering
            
            BLEManager.instance.discoverPeripheral(cbPeriph) { cbPeriphh in
                self.connectedPeripheral = p
                self.connectionState = .ready
                print(p.blePeriph.identifier)
            }
        }
        
        BLEManager.instance.didDisconnectPeripheral { cbPeriph in
            if self.connectedPeripheral?.blePeriph == cbPeriph {
                self.connectedPeripheral = nil
                self.connectionState = .disconnected
            }
        }
    }
    
    func disconnectFrom(p: Periph) {
        BLEManager.instance.discoverPeripheral(p.blePeriph) { cbPeriph in
            if self.connectedPeripheral?.blePeriph == cbPeriph {
                self.connectedPeripheral = nil
                self.connectionState = .disconnected
            }
        }
    }
    
    /**
     Connects the the bluetooth peripheral with specified name
     */
    func connectToPeriphWithName(name: String) {
        BLEManager.instance.scan { p, pname in
            let periph = Periph(blePeriph: p, name: pname)
            if periph.name == name {
                self.connectTo(p: periph)
            }
        }
    }
    
    /**
     Connects the the bluetooth peripheral with specified UUID
     */
    func connectToPeriphWithUUID(uuid: String) {
        BLEManager.instance.scan { p, pname in
            let periph = Periph(blePeriph: p, name: pname)
            if periph.blePeriph.identifier == UUID(uuidString: uuid) {
                self.connectTo(p: periph)
            }
        }
    }
    
    /**
     Listens for messages on the "readAccelerometerCBUUID" constant
     */
    func listenForAccelerometer() {
        BLEManager.instance.listenForAccelerometer { data in
            if let message = String(bytes: data!, encoding: .utf8) {
                print(message)
                
                //self.appendToHistory(text: message)
                
                if let newAcceleroPoint = Double(message) {
                    self.appendLineChartPoint(value: newAcceleroPoint)
                }
            }
            else {
                print("ERROR : could not read accelerometer data (wrong encoding, need utf-8)")
            }
        }
    }
    
    /**
     Connects the the ESP32 managing the interaction 3 which is the sphero bolt in a cuve
     */
    func connectToInteraction3Esp32() {
        BLEManager.instance.scan { p, pname in
            var periph = Periph(blePeriph: p, name: pname)
            if periph.name == "rfid-luca" {
                self.connectTo(p: periph)
            }
        }
    }
    
    /**
     Sends a message to "writeCBUUID" constant
     */
    func sendMessage(message: String) {
        if let messageToSend: Data = message.data(using: .utf8) {
            print("Sent : " + message)
            //self.appendToHistory(text: "Sent : " + message)
            BLEManager.instance.sendData(data: messageToSend) { returnMessage in
                print(returnMessage ?? "no return message")
            }
        }
        else {
            print("Could not send data")
        }
    }
    
    /**
     Sends a message to the image recogntion "writeImageRecognitionCBUUID" constant
     */
    func sendMessageToImageRecognition(message: String) {
        if let messageToSend: Data = message.data(using: .utf8) {
            print("Sent : " + message + " to AI")
            //self.appendToHistory(text: "Sent : " + message)
            BLEManager.instance.sendDataToImageRecognition(data: messageToSend) { returnMessage in
                print(returnMessage ?? "no return message")
            }
        }
        else {
            print("Could not send data to AI")
        }
    }
}

extension BLEObservable {
    /**
     Appends the value to the array of LineChartDataPoint
     */
    func appendLineChartPoint(value: Double) {
        if self.points.count >= 100 && self.hasLessThanHundredPoints == true {
            self.hasLessThanHundredPoints = false
        }
        
        self.points.append(LineChartDataPoint(value: value))
    }
    
    /**
     Appends a city name to the array of cities
     */
    /*func appendCity(name: String) {
        if self.cities.count >= 7 {
            self.sendMessage(message: stopCitiesMessage)
        }
        
        if !self.cities.contains(where: { $0.name == name }) {
            self.cities.append(CityListElement(name: name))
        }
    }
    
    /**
     Appends the action to the array of HistoryListElement
     */
    func appendToHistory(text: String) {
        self.history.append(HistoryListElement(text: text))
    }*/
}
