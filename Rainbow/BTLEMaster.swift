//
//  BTLEMaster.swift
//  Rainbow
//
//  Created by Greg Omelaenko on 26/7/16.
//  Copyright © 2016 Mostly Infinite Studios. All rights reserved.
//

import CoreBluetooth

let serviceUUID = CBUUID(string: "a36c108a-2998-4094-9a66-de5c2230abf8")
let characteristicUUID = CBUUID(string: "650221cb-a455-46c1-ae42-4e6eb1bb28f5")

@objc protocol BTLEMasterDelegate : class {

    @objc optional func master(_ master: BTLEMaster, connected peripheral: CBPeripheral)
    
    @objc optional func master(_ master: BTLEMaster, got data: Data, from peripheral: CBPeripheral)

    @objc optional func masterActivationError(_ master: BTLEMaster, description: String)

    @objc optional func master(_ master: BTLEMaster, shouldConnect peripheral: CBPeripheral, advertisementData: [String : AnyObject]) -> Bool

}

class BTLEMaster : NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {

    private var central: CBCentralManager!

    weak var delegate: BTLEMasterDelegate?

    private var connected = [CBPeripheral : CBCharacteristic?]()

    private var _value = Data()
    var value: Data {
        get { return _value }
        set {
            _value = newValue
            for (p, c) in connected where c != nil {
                p.writeValue(value, for: c!, type: .withoutResponse)
            }
        }
    }

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: nil)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            startScanning()
        case .poweredOff:
            delegate?.masterActivationError?(self, description: "Please turn on Bluetooth.")
        case .unsupported, .unauthorized:
            delegate?.masterActivationError?(self, description: "Your device does not support Bluetooth LE.")
        default:
            break
        }
    }

    func startScanning() {
        central.scanForPeripherals(withServices: [serviceUUID], options: nil)
    }

    func stopScanning() {
        central.stopScan()
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : AnyObject], rssi RSSI: NSNumber) {
        if delegate?.master?(self, shouldConnect: peripheral, advertisementData: advertisementData) ?? true {
            print("Connecting peripheral \(peripheral)")
            central.connect(peripheral, options: nil)
            connected[peripheral] = .some(nil)
        }
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: NSError?) {
        print("Failed to connect to \(peripheral). (\(error!.localizedDescription))")

        cleanup(peripheral: peripheral)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected peripheral \(peripheral)")
        peripheral.delegate = self
        peripheral.discoverServices([serviceUUID])
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        guard error == nil else {
            print("Error discovering services: \(error!.localizedDescription)")
            cleanup(peripheral: peripheral)
            return
        }

        guard let services = peripheral.services else { return }

        for service in services where service.uuid == serviceUUID {
            peripheral.discoverCharacteristics([characteristicUUID], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: NSError?) {
        guard error == nil else {
            print("Error discovering service characteristics: \(error!.localizedDescription)")
            cleanup(peripheral: peripheral)
            return
        }

        guard let characteristics = service.characteristics else { return }

        for characteristic in characteristics where characteristic.uuid == characteristicUUID {
            print("Discovered data characteristic for \(peripheral)")
            peripheral.setNotifyValue(true, for: characteristic)
            connected[peripheral] = characteristic
            peripheral.writeValue(value, for: characteristic, type: .withoutResponse)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: NSError?) {
        guard error == nil else {
            print("Error in value update: \(error!.localizedDescription)")
            return
        }

        _value = characteristic.value ?? Data()
        delegate?.master?(self, got: value, from: peripheral)
        for (p, c) in connected where p != peripheral && c != nil {
            p.writeValue(value, for: c!, type: .withoutResponse)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: NSError?) {
        if let err = error {
            print("Error changing notification state: \(err.localizedDescription)")
        }

        guard characteristic.uuid == characteristicUUID else {
            return
        }

        if characteristic.isNotifying {
            print("Notification began on \(characteristic)")
        }
        else {
            print("Notification stopped on \(characteristic). Disconnecting")
            central.cancelPeripheralConnection(peripheral)
        }
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        print("Peripheral disconnected")
    }

    func cleanup(peripheral: CBPeripheral) {
        guard peripheral.state == .connected else { return }

        if let services = peripheral.services {
            for s in services where s.uuid == serviceUUID {
                if let characteristics = s.characteristics {
                    for c in characteristics where c.uuid == characteristicUUID && c.isNotifying {
                        peripheral.setNotifyValue(false, for: c)
                    }
                }
            }
        }
        central.cancelPeripheralConnection(peripheral)
        connected.removeValue(forKey: peripheral)
    }

}
