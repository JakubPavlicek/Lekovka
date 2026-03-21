import Foundation
import CoreBluetooth
import UserNotifications
import Combine

// MARK: - BLE Background Manager
class BLEBackgroundManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    // MARK: - Published Properties
    @Published var receivedData: Data = Data()
    @Published var isConnected: Bool = false
    @Published var connectionStatus: String = "Disconnected"
    @Published var lastReceivedString: String = ""
    @Published var isScanning: Bool = false
    
    // MARK: - UUIDs (ESP32_BLE_JSON_DEVICE)
    private let serviceUUID = CBUUID(string: "12345678-1234-1234-1234-1234567890ab")
    private let txCharacteristicUUID = CBUUID(string: "12345678-1234-1234-1234-1234567890ac") // ESP → Phone
    private let rxCharacteristicUUID = CBUUID(string: "12345678-1234-1234-1234-1234567890ad") // Phone → ESP
    
    // MARK: - State Restoration Key
    private let stateRestorationIdentifier = "com.lekovka.ble.central"
    
    // MARK: - Private Properties
    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    private var targetCharacteristic: CBCharacteristic?
    private var rxCharacteristic: CBCharacteristic? // For sending data to ESP
    private var shouldAutoReconnect: Bool = true
    
    // MARK: - Initialization
    override init() {
        super.init()
        // CRITICAL: Use state restoration for background wake-up
        centralManager = CBCentralManager(
            delegate: self,
            queue: nil,
            options: [
                CBCentralManagerOptionRestoreIdentifierKey: stateRestorationIdentifier,
                CBCentralManagerOptionShowPowerAlertKey: true
            ]
        )
    }
    
    // MARK: - Public Methods
    func startScanning() {
        guard centralManager.state == .poweredOn else {
            connectionStatus = "Bluetooth not ready"
            return
        }
        shouldAutoReconnect = true
        isScanning = true
        
        // CRITICAL: Must specify service UUID for background scanning
        centralManager.scanForPeripherals(
            withServices: [serviceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
        connectionStatus = "Scanning for ESP32_JSON_DEVICE..."
    }
    
    func stopScanning() {
        centralManager.stopScan()
        isScanning = false
        connectionStatus = "Stopped scanning"
    }
    
    func disconnect() {
        shouldAutoReconnect = false
        guard let peripheral = connectedPeripheral else { return }
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
    // MARK: - State Restoration (Critical for Background)
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        // Called when iOS wakes the app from background
        print("Will restore state - app woke from background")
        
        // Restore connected peripherals
        if let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] {
            for peripheral in peripherals {
                connectedPeripheral = peripheral
                peripheral.delegate = self
                isConnected = true
                connectionStatus = "Restored: \(peripheral.name ?? "Device")"
            }
        }
        
        // Restore scan services
        if let scanServices = dict[CBCentralManagerRestoredStateScanServicesKey] as? [CBUUID] {
            print("Restoring scan for services: \(scanServices)")
        }
    }
    
    // MARK: - CBCentralManagerDelegate
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            connectionStatus = "Bluetooth ready"
            // Auto-connect: start scanning as soon as Bluetooth is ready
            if !isConnected && connectedPeripheral == nil {
                startScanning()
            }
        case .poweredOff:
            connectionStatus = "Bluetooth is off"
            isConnected = false
            isScanning = false
        case .unauthorized:
            connectionStatus = "Bluetooth unauthorized"
        case .unsupported:
            connectionStatus = "Bluetooth not supported"
        default:
            connectionStatus = "Bluetooth state: \(central.state.rawValue)"
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        connectionStatus = "Found: \(peripheral.name ?? "Unknown")"
        
        // Check if this is our ESP32 device
        if peripheral.name?.contains("ESP32") == true || peripheral.name?.contains("JSON") == true {
            print("Found ESP32 device: \(peripheral.name ?? "Unknown")")
        }
        isScanning = false
        
        centralManager.stopScan()
        
        connectedPeripheral = peripheral
        peripheral.delegate = self
        
        centralManager.connect(
            peripheral,
            options: [
                CBConnectPeripheralOptionNotifyOnDisconnectionKey: true,
                CBConnectPeripheralOptionNotifyOnConnectionKey: true
            ]
        )
        connectionStatus = "Connecting..."
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        DispatchQueue.main.async {
            self.isConnected = true
            self.connectionStatus = "Connected to \(peripheral.name ?? "Device")"
        }
        
        peripheral.discoverServices([serviceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        DispatchQueue.main.async {
            self.connectionStatus = "Failed to connect: \(error?.localizedDescription ?? "Unknown")"
        }
        
        if shouldAutoReconnect {
            central.connect(peripheral, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        DispatchQueue.main.async {
            self.isConnected = false
            self.connectionStatus = "Disconnected"
        }
        
        if shouldAutoReconnect {
            connectionStatus = "Reconnecting..."
            central.connect(peripheral, options: nil)
        }
    }
    
    // MARK: - CBPeripheralDelegate
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            connectionStatus = "Service discovery failed: \(error.localizedDescription)"
            return
        }
        
        guard let services = peripheral.services else { return }
        
        for service in services where service.uuid == serviceUUID {
            // Discover both TX and RX characteristics
            peripheral.discoverCharacteristics([txCharacteristicUUID, rxCharacteristicUUID], for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            connectionStatus = "Characteristic discovery failed: \(error.localizedDescription)"
            return
        }
        
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            if characteristic.uuid == txCharacteristicUUID {
                // TX characteristic (ESP → Phone): Enable notifications
                targetCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
                print("TX characteristic found and notifications enabled")
            } else if characteristic.uuid == rxCharacteristicUUID {
                // RX characteristic (Phone → ESP): For sending data
                rxCharacteristic = characteristic
                print("RX characteristic found")
                
                // Once RX is found, send the initial time configuration handshake
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    self?.postNtcTime()
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            connectionStatus = "Notification setup failed: \(error.localizedDescription)"
            return
        }
        
        if characteristic.isNotifying {
            connectionStatus = "Listening for data..."
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error receiving data: \(error.localizedDescription)")
            return
        }
        
        guard let data = characteristic.value else { return }
        
        // ============================================================
        // Parse incoming ESP32 JSON
        if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let action = jsonObject["action"] as? String {
            if action == "medicaments-taken-confirmation" {
                postIntakeLog()
            }
            else if action == "heartbeat" {
                postHeartbeat(batteryLevel: 100)
            }
        }
        // ============================================================
        
        // Convert data to string for display
        var receivedString: String
        if let stringData = String(data: data, encoding: .utf8) {
            receivedString = stringData
        } else {
            receivedString = data.map { String(format: "%02x", $0) }.joined(separator: " ")
        }
        
        DispatchQueue.main.async {
            self.receivedData = data
            self.lastReceivedString = receivedString
        }
        
        print("Received \(data.count) bytes: \(data.map { String(format: "%02x", $0) }.joined(separator: " "))")
        
        // SHOW LOCAL NOTIFICATION when data received (works when locked)
        showLocalNotification(message: receivedString)
    }
    
    // MARK: - Local Notification
    private func showLocalNotification(message: String) {
        let content = UNMutableNotificationContent()
        content.title = "BLE Data Received"
        content.body = message.isEmpty ? "New data received" : String(message.prefix(100))
        content.sound = .default
        content.badge = 1
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Immediate delivery
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error.localizedDescription)")
            } else {
                print("Notification sent successfully")
            }
        }
    }
    
    // MARK: - Sending Data
    func sendData(_ data: Data) {
        // Send data directly using RX characteristic
        guard let peripheral = connectedPeripheral,
              let characteristic = rxCharacteristic else {
            connectionStatus = "Not connected"
            return
        }
        
        if characteristic.properties.contains(.write) || characteristic.properties.contains(.writeWithoutResponse) {
            let writeType: CBCharacteristicWriteType = characteristic.properties.contains(.write) ? .withResponse : .withoutResponse
            peripheral.writeValue(data, for: characteristic, type: writeType)
        }
    }
    
    func sendString(_ string: String) {
        if let data = string.data(using: .utf8) {
            sendData(data)
        }
    }
    
    // MARK: - NTC Auto-Handshake
    func postNtcTime() {
        let timestamp = Int(Date().timeIntervalSince1970)
        let payload: [String: Any] = [
            "action": "post-ntc-time",
            "current_timestamp": timestamp
        ]
        if let data = try? JSONSerialization.data(withJSONObject: payload),
           let jsonString = String(data: data, encoding: .utf8) {
            sendString(jsonString)
            print("🕒 Sent post-ntc-time: \(jsonString)")
        }
    }
    
    // MARK: - Backend Intake Log Sync
    func postIntakeLog() {
        // Base API URL is managed globally by AuthManager. 
        // We trim trailing slash if it exists to build safe endpoints.
        let baseURL = AuthManager.apiBaseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: "\(baseURL)/intake-logs") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let userId = UserDefaults.standard.string(forKey: "lekovka_user_id") {
            request.setValue(userId, forHTTPHeaderField: "X-User-ID")
        }
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                print("❌ Failed to POST /intake-logs: \(error.localizedDescription)")
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                print("📝 POST /intake-logs response: HTTP \(httpResponse.statusCode)")
            }
        }.resume()
    }
    
    // MARK: - Backend Heartbeat Sync
    func postHeartbeat(batteryLevel: Int) {
        let baseURL = AuthManager.apiBaseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: "\(baseURL)/device/heartbeat") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let userId = UserDefaults.standard.string(forKey: "lekovka_user_id") {
            request.setValue(userId, forHTTPHeaderField: "X-User-ID")
        }
        
        let body: [String: Any] = ["batteryLevel": batteryLevel]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                print("❌ Failed to POST /device/heartbeat: \(error.localizedDescription)")
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                print("💓 POST /device/heartbeat response: HTTP \(httpResponse.statusCode)")
            }
        }.resume()
    }
}
