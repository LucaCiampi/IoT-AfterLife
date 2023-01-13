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

struct DataReceived:Identifiable,Equatable{
    var id = UUID().uuidString
    var content:String
}

class BLEObservable: ObservableObject {
    
    enum ConnectionState {
        case disconnected, connecting, discovering, ready
    }
    
    @Published var periphList: [Periph] = []
    @Published var connectedPeripheral: Periph? = nil
    @Published var connectedPeripherals: [Periph]? = nil
    @Published var connectionState: ConnectionState = .disconnected
    
    // Interaction 1
    @Published var glassesDataReceived: [DataReceived] = []
    
    // Interaction 3
    @Published var cuveDataReceived: [DataReceived] = []
    
    // Interaction 4
    @Published var djiButtonPressed: Bool = false
    
    // Interaction 5
    @Published var pokerDataReceived: [DataReceived] = []
    
    
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
    
    func connectToMultiple(p: Periph, callback: @escaping () -> ()) {
        self.connectionState = .connecting
        
        BLEManager.instance.connectPeripheral(p.blePeriph) { cbPeriph in
            self.connectionState = .discovering
            
            BLEManager.instance.discoverPeripheral(cbPeriph) { cbPeriphh in
                self.connectedPeripheral = p
                self.connectionState = .ready
                print(p.blePeriph.identifier)
                callback()
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
    func listenForCuveEsp32() {
        BLEManager.instance.listenForCuveEsp32() { data in
            if let d = data,
               let s = String(data: d, encoding: .utf8){
                print(DataReceived(content: s))
                self.cuveDataReceived.append(DataReceived(content: s))
            }
        }
    }
    
    /**
     Listens for messages on the "readAccelerometerCBUUID" constant
     */
    func listenForPokerEsp32() {
        BLEManager.instance.listenForPokerEsp32() { data in
            if let d = data,
               let s = String(data: d, encoding: .utf8){
                print(DataReceived(content: s))
                self.pokerDataReceived.append(DataReceived(content: s))
            }
        }
    }
    
    /**
     Connects the the ESP32 managing the interaction 1
     */
    func connectToInteraction1Esp32() {
        BLEManager.instance.scan { p, pname in
            let periph = Periph(blePeriph: p, name: pname)
            if periph.name == "verres-led-esp" {
                self.connectTo(p: periph)
            }
        }
    }
    
    /**
     Connects the the ESP32 managing the interaction 3 which is the sphero bolt in a cuve
     TODO: change this for UUID in BLEManager
     */
    func connectToInteraction3Esp32() {
        BLEManager.instance.scan { p, pname in
            let periph = Periph(blePeriph: p, name: pname)
            if periph.name == "cuve-esp" {
                self.connectTo(p: periph)
            }
        }
    }
    
    /**
     Connects to the ESP32 managing the interaction 5 which is the poker game
     */
    func connectToInteraction5Esp32() {
        BLEManager.instance.scan { p, pname in
            let periph = Periph(blePeriph: p, name: pname)
            if periph.name == "rfid-poker-1" {
                self.connectToMultiple(p: periph) {
                    self.connectToInteraction5Esp32Bis()
                }
            }
        }
    }
    
    /**
     Connects to the second ESP32 bis managing the interaction 5 which is the poker game
     */
    func connectToInteraction5Esp32Bis() {
        BLEManager.instance.scan { p, pname in
            let periph = Periph(blePeriph: p, name: pname)
            if periph.name == "rfid-poker-2" {
                self.connectToMultiple(p: periph) {
                    self.connectToInteraction5Esp32Leds()
                }
            }
        }
    }
    
    /**
     Connects to the second ESP32 managing the interaction 5 leds which is the poker game
     */
    func connectToInteraction5Esp32Leds() {
        BLEManager.instance.scan { p, pname in
            let periph = Periph(blePeriph: p, name: pname)
            if periph.name == "rfid-poker-leds" {
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
            BLEManager.instance.sendData(data: messageToSend) { returnMessage in
                print(returnMessage ?? "no return message")
            }
        }
        else {
            print("Could not send data")
        }
    }
    
    /**
     Sends a message to the verres ESP32
     */
    func sendMessageToVerresESP32(message: String) {
        if let messageToSend: Data = message.data(using: .utf8) {
            print("Sent : " + message + " to verres esp32")
            //self.appendToHistory(text: "Sent : " + message)
            BLEManager.instance.sendDataToVerresESP(data: messageToSend) { returnMessage in
                print(returnMessage ?? "no return message")
            }
        }
        else {
            print("Could not send data to verres esp32")
        }
    }
    
    /**
     Sends a message to the poker ESP32
     */
    func sendMessageToPokerLedsESP32(message: String) {
        if let messageToSend: Data = message.data(using: .utf8) {
            print("Sent : " + message + " to poker leds esp32")
            //self.appendToHistory(text: "Sent : " + message)
            BLEManager.instance.sendDataToPokerLedsESP(data: messageToSend) { returnMessage in
                print(returnMessage ?? "no return message")
            }
        }
        else {
            print("Could not send data to poker")
        }
    }
}

extension BLEObservable {
    
}
