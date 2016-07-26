//
//  BTLESlave.swift
//  Rainbow
//
//  Created by Greg Omelaenko on 26/7/16.
//  Copyright © 2016 Mostly Infinite Studios. All rights reserved.
//

import CoreBluetooth

@objc protocol BTLESlaveDelegate : class {

    @objc optional func slave(_ slave: BTLESlave, got data: Data)

}

class BTLESlave : NSObject, CBPeripheralManagerDelegate {

    private var manager: CBPeripheralManager!
    private var characteristic: CBMutableCharacteristic!

    private var _value = Data()
    var value: Data {
        get { return _value }
        set {
            _value = newValue
            manager.updateValue(value, for: characteristic, onSubscribedCentrals: nil)
        }
    }

    weak var delegate: BTLESlaveDelegate?

    override init() {
        super.init()
        manager = CBPeripheralManager(delegate: self, queue: nil)
    }

    func startAdvertising() {
        print("Starting advertising")
        manager.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey: [serviceUUID],
        ])
    }

    func stopAdvertising() {
        print("Stopping advertising")
        manager.stopAdvertising()
    }

    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: NSError?) {
        if let err = error {
            print(err)
        }
    }

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        guard peripheral.state == .poweredOn else { return }

        characteristic = CBMutableCharacteristic(type: characteristicUUID, properties: [.notify, .writeWithoutResponse], value: nil, permissions: [.readable, .writeable])

        let service = CBMutableService(type: serviceUUID, primary: true)
        service.characteristics = [characteristic]

        manager.add(service)

        startAdvertising()
    }

    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {

    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for r in requests where r.characteristic.uuid == characteristicUUID {
            _value = r.value ?? Data()
            delegate?.slave?(self, got: value)
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        peripheral.respond(to: request, withResult: CBATTError.success)
    }

}
