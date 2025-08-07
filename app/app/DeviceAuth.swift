import Foundation
import LocalAuthentication
import UIKit
import CryptoKit
import Security

class DeviceAuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUserID: String?
    @Published var currentPhoneNumber: String?
    @Published var deviceTrusted = false
    
    private let keychain = DeviceKeychainManager()
    
    init() {
        loadStoredAuth()
        checkDeviceTrust()
    }
    
    // MARK: - Device Fingerprinting
    func generateDeviceFingerprint() -> String {
        var components: [String] = []
        
        // Device identifier (persists until app uninstall)
        if let vendorID = UIDevice.current.identifierForVendor?.uuidString {
            components.append(vendorID)
        }
        
        // Device model
        components.append(UIDevice.current.model)
        components.append(UIDevice.current.systemName)
        components.append(UIDevice.current.systemVersion)
        
        // Screen dimensions (helps identify device type)
        let screen = UIScreen.main
        components.append("\(screen.bounds.width)x\(screen.bounds.height)")
        components.append("\(screen.scale)")
        
        // Timezone
        components.append(TimeZone.current.identifier)
        
        // Create hash of all components
        let fingerprint = components.joined(separator: "|")
        let data = Data(fingerprint.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    // MARK: - Biometric Authentication
    func authenticateWithBiometrics() async -> Bool {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            print("Biometric authentication not available: \(error?.localizedDescription ?? "Unknown error")")
            return false
        }
        
        do {
            let result = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "authenticate to access mischatter"
            )
            return result
        } catch {
            print("Biometric authentication failed: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Device Trust
    func establishDeviceTrust(phoneNumber: String) async -> Bool {
        let deviceFingerprint = generateDeviceFingerprint()
        
        let trustData = DeviceTrustData(
            phoneNumber: phoneNumber,
            deviceFingerprint: deviceFingerprint,
            timestamp: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        )
        
        // Store device trust locally
        keychain.store(trustData, forKey: "device_trust")
        
        // Send to server for verification
        let success = await callDeviceTrustAPI(phoneNumber: phoneNumber, deviceFingerprint: deviceFingerprint)
        
        await MainActor.run {
            self.deviceTrusted = success
        }
        
        return success
    }
    
    // MARK: - Authentication Flow
    func authenticateWithDevice(phoneNumber: String) async -> AuthResult {
        let deviceFingerprint = generateDeviceFingerprint()
        
        // Check if device is already trusted
        if let storedTrust = keychain.retrieve(DeviceTrustData.self, forKey: "device_trust"),
           storedTrust.deviceFingerprint == deviceFingerprint,
           storedTrust.phoneNumber == phoneNumber {
            
            // Device is trusted, try biometric auth
            let biometricSuccess = await authenticateWithBiometrics()
            
            if biometricSuccess {
                // Call API for device authentication
                let apiResult = await callDeviceAuthAPI(phoneNumber: phoneNumber, deviceFingerprint: deviceFingerprint, biometricVerified: true)
                
                if apiResult {
                    await MainActor.run {
                        self.isAuthenticated = true
                        self.deviceTrusted = true
                        self.saveAuth()
                    }
                    return .success
                } else {
                    return .error("API authentication failed")
                }
            } else {
                return .biometricFailed
            }
        } else {
            // New device, needs verification
            return .deviceNotTrusted
        }
    }
    
    func generateUserID(from phoneNumber: String, deviceFingerprint: String) -> String {
        let combined = phoneNumber + deviceFingerprint
        let data = Data(combined.utf8)
        let hash = SHA256.hash(data: data)
        return "user_" + hash.compactMap { String(format: "%02x", $0) }.joined().prefix(16)
    }
    
    // MARK: - Storage
    private func saveAuth() {
        keychain.store(currentUserID, forKey: "current_user_id")
        keychain.store(currentPhoneNumber, forKey: "current_phone")
    }
    
    private func loadStoredAuth() {
        currentUserID = keychain.retrieve(String.self, forKey: "current_user_id")
        currentPhoneNumber = keychain.retrieve(String.self, forKey: "current_phone")
        isAuthenticated = currentUserID != nil && currentPhoneNumber != nil
    }
    
    private func checkDeviceTrust() {
        let deviceFingerprint = generateDeviceFingerprint()
        if let storedTrust = keychain.retrieve(DeviceTrustData.self, forKey: "device_trust"),
           storedTrust.deviceFingerprint == deviceFingerprint {
            deviceTrusted = true
        }
    }
    
    func logout() {
        currentUserID = nil
        currentPhoneNumber = nil
        isAuthenticated = false
        deviceTrusted = false
        keychain.delete(forKey: "current_user_id")
        keychain.delete(forKey: "current_phone")
    }
    
    func resetDeviceTrust() {
        deviceTrusted = false
        keychain.delete(forKey: "device_trust")
    }
}

// MARK: - Supporting Types
enum AuthResult {
    case success
    case deviceNotTrusted
    case biometricFailed
    case error(String)
}

struct DeviceTrustData: Codable {
    let phoneNumber: String
    let deviceFingerprint: String
    let timestamp: Date
    let appVersion: String
}

// MARK: - Device Keychain Manager
class DeviceKeychainManager {
    private let service = "com.mischatter.app"
    
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

// MARK: - API Integration
extension DeviceAuthManager {
    private func callDeviceTrustAPI(phoneNumber: String, deviceFingerprint: String) async -> Bool {
        guard let url = URL(string: "http://localhost:3000/api/auth/device-trust") else { return false }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "phoneNumber": phoneNumber,
            "deviceFingerprint": deviceFingerprint,
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                return true
            }
        } catch {
            print("Device trust API error: \(error)")
        }
        
        return false
    }
    
    private func callDeviceAuthAPI(phoneNumber: String, deviceFingerprint: String, biometricVerified: Bool) async -> Bool {
        guard let url = URL(string: "http://localhost:3000/api/auth/device-auth") else { return false }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "phoneNumber": phoneNumber,
            "deviceFingerprint": deviceFingerprint,
            "biometricVerified": biometricVerified
        ] as [String : Any]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200,
               let jsonData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let success = jsonData["success"] as? Bool,
               success,
               let user = jsonData["user"] as? [String: Any],
               let userId = user["id"] as? String,
               let token = jsonData["token"] as? String {
                
                await MainActor.run {
                    self.currentUserID = userId
                    self.currentPhoneNumber = phoneNumber
                }
                
                // Store token for API calls
                UserDefaults.standard.set(token, forKey: "auth_token")
                
                return true
            }
        } catch {
            print("Device auth API error: \(error)")
        }
        
        return false
    }
}