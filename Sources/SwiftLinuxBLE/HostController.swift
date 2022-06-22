import Foundation
import Bluetooth
import GATT
import BluetoothLinux

@available(OSX 10.12, *)
extension HostController {
    public func newPeripheral() throws -> GATTPeripheral<HostController, L2CAPSocket> {
        // Setup peripheral
        let serverSocket = try L2CAPSocket.lowEnergyServer(isRandom: false)
        
        let peripheral = GATTPeripheral<HostController, L2CAPSocket>(controller: self)
        peripheral.newConnection = {
            let socket = try serverSocket.waitForConnection()
            let central = Central(identifier: socket.address)
            return (socket, central)
        }
        return peripheral
    }
}
