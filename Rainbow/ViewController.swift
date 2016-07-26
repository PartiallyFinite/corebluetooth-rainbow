//
//  ViewController.swift
//  Rainbow
//
//  Created by Greg Omelaenko on 26/7/16.
//  Copyright © 2016 Mostly Infinite Studios. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, BTLEMasterDelegate, BTLESlaveDelegate {

    var master: BTLEMaster?
    var slave: BTLESlave?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        perform(#selector(ViewController.choose), with: nil, afterDelay: 0.5)
    }

    func choose() {
        let alert = UIAlertController(title: "Master or slave?", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Master", style: .default, handler: { _ in
            self.master = BTLEMaster()
            self.master!.delegate = self
        }))
        alert.addAction(UIAlertAction(title: "Slave", style: .default, handler: { _ in
            self.slave = BTLESlave()
            self.slave!.delegate = self
        }))
        present(alert, animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func setColour(_ data: Data) {
        if let str = String(data: data, encoding: .utf8), let hex = UInt(str) {
            view.backgroundColor = UIColor(hex: hex)
        }
    }

    func master(_ master: BTLEMaster, got data: Data, from peripheral: CBPeripheral) {
        setColour(data)
    }

    func slave(_ slave: BTLESlave, got data: Data) {
        setColour(data)
    }

    @IBAction func tap() {
        let hex = arc4random() % 0x00ffffff
        view.backgroundColor = UIColor(hex: UInt(hex))
        master?.value = String(hex).data(using: .utf8)!
        slave?.value = String(hex).data(using: .utf8)!
    }

}

