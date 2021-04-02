import Foundation
import Bluetooth
import GATT
import BluetoothLinux

@available(OSX 10.12, *)
public protocol Peripheral : class {
    var peripheral: GATTPeripheral<HostController, L2CAPSocket> { get }
    var services: [Service] { get set }
    var characteristicsByHandle: [UInt16: CharacteristicType] { get set }
}

@available(OSX 10.12, *)
extension Peripheral {
    public func advertise(name: GAPCompleteLocalName, services: [Service], iBeacon: AppleBeacon? = nil) throws {
        // Advertise services and peripheral name
        let serviceUUIDs = GAPIncompleteListOf128BitServiceClassUUIDs(uuids: services.map { UUID(bluetooth: $0.uuid) })
        let encoder = GAPDataEncoder()
        let data = try encoder.encodeAdvertisingData(name, serviceUUIDs)
        try peripheral.controller.setLowEnergyScanResponse(data, timeout: .default)
        print("BLE Advertising started")
        
        // Setup iBeacon
        if let iBeacon = iBeacon {
            let flags: GAPFlags = [.lowEnergyGeneralDiscoverableMode, .notSupportedBREDR]
            try peripheral.controller.iBeacon(iBeacon, flags: flags, interval: .min, timeout: .default)
        }
    }
    public func add(service: Service) throws {
        // Find all the characteristics for the service
        let characteristics = Mirror(reflecting: service).children.compactMap {
            $0.value as? CharacteristicType
        }
        
        let gattCharacteristics = characteristics.map {
            GATT.Characteristic(uuid: $0.uuid, value: $0.data, permissions: $0.permissions, properties: $0.properties, descriptors: $0.descriptors)
        }
        
        let gattService = GATT.Service(uuid: service.uuid, primary: true, characteristics: gattCharacteristics)
        let _ = try peripheral.add(service: gattService)
        
        
        for var characteristic in characteristics {
            guard let handle = peripheral.characteristics(for: characteristic.uuid).last else { continue }
            
            print("Characteristic \(characteristic.uuid) with permissions \(characteristic.permissions) and \(characteristic.descriptors.count) descriptors")
            
            // Register as observer for each characteristic
            characteristic.didSet { [weak self] in
                NSLog("MyPeripheral: characteristic \(characteristic.uuid) did change with new value \($0)")
                self?.peripheral[characteristic: handle] = $0
            }
          
            characteristicsByHandle[handle] = characteristic
            
        }
        services += [service]      
    }
    
    public func didWrite(_ confirmation: GATTWriteConfirmation<Central>) {
        if var characteristic = characteristicsByHandle[confirmation.handle] {
            characteristic.data = confirmation.value
        }
    }
}
