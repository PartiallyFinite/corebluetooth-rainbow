# corebluetooth-rainbow

Uses [CoreBluetooth](https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CoreBluetooth_Framework/index.html#//apple_ref/doc/uid/TP40011295) to sync up all devices (master device automatically connects to all available slaves) and display a random screen colour that changes when any screen is tapped.

`BTLEMaster` and `BTLESlave` are reusable in more complex projects with some modifications (delegate methods are provided for filtering of slave devices to pair with).
