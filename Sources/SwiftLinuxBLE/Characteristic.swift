import Foundation
import Bluetooth
import GATT
import BluetoothLinux


public protocol CharacteristicType {
    var uuid: BluetoothUUID { get }
    var properties: BitMaskOptionSet<GATT.Characteristic.Property> { get }
    var permissions: BitMaskOptionSet<GATT.Permission> { get }
    var descriptors: [GATT.Characteristic.Descriptor] { get }
    
    var data: Data { get set }
    var didSet: (Data) -> Void { get set }
}

@propertyWrapper
public class Characteristic<Value: DataConvertible> : CharacteristicType {
    var value: Value
    public let uuid: BluetoothUUID
    public var properties: BitMaskOptionSet<GATT.Characteristic.Property> = [.read, .write]
    public var permissions: BitMaskOptionSet<GATT.Permission> = [.read, .write]
    public let descriptors: [GATT.Characteristic.Descriptor]
    
    /*
     // Default arguments cause segfault in swift 5.1
    public init(wrappedValue value: Value, uuid: BluetoothUUID, _ properties: BitMaskOptionSet<GATT.Characteristic.Property>, _ permissions: BitMaskOptionSet<GATT.Permission>? = nil, _ descriptors: [GATT.Characteristic.Descriptor]? = nil) {
        self.value = value
        self.uuid = uuid
        self.properties = properties
        self.permissions = permissions ?? properties.inferredPermissions
        // we need this special descriptor to enable notifications!
        self.descriptors = descriptors ?? (properties.contains(.notify) ? [GATTClientCharacteristicConfiguration().descriptor] : [])
    }*/
    
    public init(wrappedValue value: Value, uuid: BluetoothUUID, _ properties: BitMaskOptionSet<GATT.Characteristic.Property>) {
        self.value = value
        self.uuid = uuid
        self.properties = properties
        self.permissions = properties.inferredPermissions
        // we need this special descriptor to enable notifications!
        self.descriptors = (properties.contains(.notify) ? [GATTClientCharacteristicConfiguration().descriptor] : [])
    }
    
    public var wrappedValue: Value {
        get { value }
        set { value = newValue; didSet(data) }
    }
    
    public var data: Data {
        get { return value.data }
        set { value = Value(data: newValue) ?? value }
    }
    public var didSet: (Data) -> Void = { _ in }
}


extension BitMaskOptionSet where Element == GATT.Characteristic.Property {
    var inferredPermissions: BitMaskOptionSet<GATT.Permission> {
        let mapping: [GATT.Characteristic.Property: ATTAttributePermission] = [
            .read: .read,
            .notify: .read,
            .write: .write
        ]
        var permissions = BitMaskOptionSet<GATT.Permission>()
        for (property, permission) in mapping {
            if contains(property) {
                permissions.insert(permission)
            }
        }
        return permissions
    }
}
