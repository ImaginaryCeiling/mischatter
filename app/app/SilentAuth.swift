import Foundation
import UIKit
import CryptoKit
import Security

class SilentAuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUserID: String?
    @Published var isLoading = true
    
    private let keychain = SilentKeychainManager()
    
    init() {
        autoAuthenticate()
    }
    
    // MARK: - Silent Device Fingerprinting
    func generateDeviceFingerprint() -> String {
        var components: [String] = []
        
        // Device identifier (persists until app uninstall)
        if let vendorID = UIDevice.current.identifierForVendor?.uuidString {
            components.append(vendorID)
        }
        
        // Device characteristics
        components.append(UIDevice.current.model)
        components.append(UIDevice.current.systemName)
        components.append(UIDevice.current.systemVersion)
        
        // Screen fingerprint
        let screen = UIScreen.main
        components.append("\(screen.bounds.width)x\(screen.bounds.height)@\(screen.scale)")
        
        // Additional hardware identifiers
        components.append(ProcessInfo.processInfo.processorCount.description)
        components.append(TimeZone.current.identifier)
        
        // Create deterministic hash
        let fingerprint = components.joined(separator: "|")
        let data = Data(fingerprint.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    // MARK: - Auto Authentication
    func autoAuthenticate() {
        Task {
            let deviceFingerprint = generateDeviceFingerprint()
            
            // Check if device is known
            if let storedUserID = keychain.retrieve(String.self, forKey: "user_\(deviceFingerprint)") {
                // Device recognized, auto-login
                await MainActor.run {
                    self.currentUserID = storedUserID
                    self.isAuthenticated = true
                    self.isLoading = false
                }
            } else {
                // New device, create user
                await createNewUser(deviceFingerprint: deviceFingerprint)
            }
        }
    }
    
    private func createNewUser(deviceFingerprint: String) async {
        // Generate unique user ID from device fingerprint
        let userID = "user_" + deviceFingerprint.prefix(16)
        
        // Store this device
        keychain.store(userID, forKey: "user_\(deviceFingerprint)")
        
        // Simulate brief loading for new device setup
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        await MainActor.run {
            self.currentUserID = userID
            self.isAuthenticated = true
            self.isLoading = false
        }
    }
    
    // MARK: - Enhanced Fingerprinting
    func getEnhancedFingerprint() -> [String: Any] {
        var fingerprint: [String: Any] = [:]
        
        // Device info
        fingerprint["model"] = UIDevice.current.model
        fingerprint["systemName"] = UIDevice.current.systemName
        fingerprint["systemVersion"] = UIDevice.current.systemVersion
        fingerprint["vendorId"] = UIDevice.current.identifierForVendor?.uuidString
        
        // Screen info
        let screen = UIScreen.main
        fingerprint["screenBounds"] = "\(screen.bounds.width)x\(screen.bounds.height)"
        fingerprint["screenScale"] = screen.scale
        fingerprint["screenNativeBounds"] = "\(screen.nativeBounds.width)x\(screen.nativeBounds.height)"
        
        // Hardware info
        fingerprint["processorCount"] = ProcessInfo.processInfo.processorCount
        fingerprint["physicalMemory"] = ProcessInfo.processInfo.physicalMemory
        
        // Locale info
        fingerprint["timezone"] = TimeZone.current.identifier
        fingerprint["locale"] = Locale.current.identifier
        
        // App info
        fingerprint["bundleId"] = Bundle.main.bundleIdentifier
        fingerprint["appVersion"] = Bundle.main.infoDictionary?["CFBundleShortVersionString"]
        
        return fingerprint
    }
    
    func logout() {
        let deviceFingerprint = generateDeviceFingerprint()
        keychain.delete(forKey: "user_\(deviceFingerprint)")
        
        currentUserID = nil
        isAuthenticated = false
        isLoading = false
    }
    
    func resetAndReauth() {
        logout()
        isLoading = true
        autoAuthenticate()
    }
}

// MARK: - Silent Keychain Manager
class SilentKeychainManager {
    private let service = "com.mischatter.app.silent"
    
    func store<T: Codable>(_ item: T, forKey key: String) {
        guard let data = try? JSONEncoder().encode(item) else { return }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    func retrieve<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let item = try? JSONDecoder().decode(type, from: data) else {
            return nil
        }
        
        return item
    }
    
    func delete(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}