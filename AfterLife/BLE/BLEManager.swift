import Foundation
import SwiftUI
import CoreBluetooth

class BLEManager: NSObject {
    static let instance = BLEManager()
    
    var isBLEEnabled = false
    var isScanning = false
    
    // Interaction 3 - Cuve
    let cuveAuthCBUUID = CBUUID(string: "CC140D37-A95D-46E4-AC14-D8B815B3273F")
    let cuveWriteCBUUID = CBUUID(string: "C715259B-5AAC-4341-ABC2-C8EA4E23C058")
    let cuveReadCBUUID = CBUUID(string: "3DE6F23F-AFAF-4B91-AB89-1B0D78B33E56")
    
    // Interaction 5 - Poker
    let pokerAuthCBUUID = CBUUID(string: "839B01C2-2F62-434F-82B8-670D7057AB98")
    let pokerWriteCBUUID = CBUUID(string: "4AA55938-382F-455E-B447-0C3676B8910F")
    let pokerReadCBUUID = CBUUID(string: "78CB0348-462A-441B-916F-320BC21DAF73")
    
    let pokerBisAuthCBUUID = CBUUID(string: "FDA6ADC0-D568-4586-ADE5-63F21168428D")
    let pokerBisWriteCBUUID = CBUUID(string: "19BF94C5-3219-4433-967C-CB29CBF2B173")
    let pokerBisReadCBUUID = CBUUID(string: "F4C8EE2A-8686-46C1-8CD3-06C263BFEB7D")
    
    var messageReceivedCallbackCuveEsp32: ((Data?)->())?
    var messageReceivedCallbackPokerEsp32: ((Data?)->())?
    var sendDataCallbackPokerEsp32: ((String?) -> ())?
    
    var centralManager: CBCentralManager?
    var connectedPeripherals = [CBPeripheral]()
    var readyPeripherals = [CBPeripheral]()
    
    var scanCallback: ((CBPeripheral,String) -> ())?
    var connectCallback: ((CBPeripheral) -> ())?
    var disconnectCallback: ((CBPeripheral) -> ())?
    var didFinishDiscoveryCallback: ((CBPeripheral) -> ())?
    var globalDisconnectCallback: ((CBPeripheral) -> ())?
    
    var sendDataCallback: ((String?) -> ())?
    
    var messageReceivedCallback: ((Data?)->())?
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func clear() {
        connectedPeripherals = []
        readyPeripherals = []
    }
    
    func scan(callback: @escaping (CBPeripheral,String) -> ()) {
        isScanning = true
        scanCallback = callback
        //centralManager?.scanForPeripherals(withServices: [authCBUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey:NSNumber(value: false)])
        centralManager?.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey:NSNumber(value: false)])
    }
    
    func stopScan() {
        isScanning = false
        centralManager?.stopScan()
    }
    
    func listenForMessages(callback:@escaping(Data?)->()) {
        messageReceivedCallback = callback
    }
    
    /**
     Interaction 3 cuve listen for messages
     */
    func listenForCuveEsp32(callback:@escaping(Data?)->()) {
        messageReceivedCallbackCuveEsp32 = callback
    }
    
    /**
     Interaction 5 listen for messages
     */
    func listenForPokerEsp32(callback:@escaping(Data?)->()) {
        messageReceivedCallbackPokerEsp32 = callback
    }
    
    func connectPeripheral(_ periph: CBPeripheral, callback: @escaping (CBPeripheral) -> ()) {
        connectCallback = callback
        centralManager?.connect(periph, options: nil)
    }
    
    func disconnectPeripheral(_ periph: CBPeripheral, callback: @escaping (CBPeripheral) -> ()) {
        disconnectCallback = callback
        centralManager?.cancelPeripheralConnection(periph)
    }
    
    func didDisconnectPeripheral(callback: @escaping (CBPeripheral) -> ()) {
        disconnectCallback = callback
        globalDisconnectCallback = callback
    }
    
    func discoverPeripheral(_ periph: CBPeripheral, callback: @escaping (CBPeripheral) -> ()) {
        didFinishDiscoveryCallback = callback
        periph.delegate = self
        periph.discoverServices(nil)
        
    }
    
    func getCharForUUID(_ uuid: CBUUID, forperipheral peripheral: CBPeripheral) -> CBCharacteristic? {
        if let services = peripheral.services {
            for service in services {
                if let characteristics = service.characteristics {
                    for char in characteristics {
                        if char.uuid == uuid {
                            return char
                        }
                    }
                }
            }
        }
        return nil
    }
    
    func sendData(data: Data, callback: @escaping (String?) -> ()) {
        sendDataCallback = callback
        for periph in readyPeripherals {
            //if let char = BLEManager.instance.getCharForUUID(writeCBUUID, forperipheral: periph) {
            if let char = BLEManager.instance.getCharForUUID(pokerWriteCBUUID, forperipheral: periph) {
                periph.writeValue(data, for: char, type: CBCharacteristicWriteType.withResponse)
            }
        }
    }
    
    /**
     Interaction 5 sending messages
     */
    func sendDataToPokerESP(data: Data, callback: @escaping (String?) -> ()) {
        sendDataCallbackPokerEsp32 = callback
        for periph in readyPeripherals {
            if let char = BLEManager.instance.getCharForUUID(pokerWriteCBUUID, forperipheral: periph) {
                periph.writeValue(data, for: char, type: CBCharacteristicWriteType.withResponse)
            }
        }
    }
    
    func readData() {
        for periph in readyPeripherals {
            //if let char = BLEManager.instance.getCharForUUID(readCBUUID, forperipheral: periph) {
            if let char = BLEManager.instance.getCharForUUID(pokerReadCBUUID, forperipheral: periph) {
                periph.readValue(for: char)
            }
        }
    }
    
}

extension BLEManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let services = peripheral.services {
            let count = services.filter { $0.characteristics == nil }.count
            if count == 0 {
                for s in services {
                    for c in s.characteristics! {
                        peripheral.setNotifyValue(true, for: c)
                    }
                }
                readyPeripherals.append(peripheral)
                didFinishDiscoveryCallback?(peripheral)
            }
        }
    }
}

extension BLEManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            isBLEEnabled = true
        } else {
            isBLEEnabled = false
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let localName = advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? "Unknown"
        scanCallback?(peripheral,localName)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if !connectedPeripherals.contains(peripheral) {
            connectedPeripherals.append(peripheral)
            connectCallback?(peripheral)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connectedPeripherals.removeAll { $0 == peripheral }
        readyPeripherals.removeAll { $0 == peripheral }
        disconnectCallback?(peripheral)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic == getCharForUUID(pokerReadCBUUID, forperipheral: peripheral) {
            print("Message recieved from poker ESP32")
            messageReceivedCallbackPokerEsp32?(characteristic.value)
        }
        else if characteristic == getCharForUUID(pokerBisReadCBUUID, forperipheral: peripheral) {
            print("Message recieved from poker ESP32 bis")
            messageReceivedCallbackPokerEsp32?(characteristic.value)
        }
        else if characteristic == getCharForUUID(cuveReadCBUUID, forperipheral: peripheral) {
            print("Message recieved from cuve ESP32")
            messageReceivedCallbackCuveEsp32?(characteristic.value)
        }
        else {
            print("Message recieved from unknown UUID")
            messageReceivedCallback?(characteristic.value)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic == getCharForUUID(pokerWriteCBUUID, forperipheral: peripheral) {
            print("Message sent to poker ESP32")
            sendDataCallbackPokerEsp32?(peripheral.name)
        }
        else if characteristic == getCharForUUID(pokerBisWriteCBUUID, forperipheral: peripheral) {
            print("Message sent to poker ESP32 bis")
            sendDataCallbackPokerEsp32?(peripheral.name)
        }
        else {
            print("Message sent to unknown UUID")
            sendDataCallback?(peripheral.name)
        }
    }
}
