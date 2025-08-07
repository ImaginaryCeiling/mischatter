import Foundation
import CryptoKit
import CoreTelephony

class PhoneAuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUserID: String?
    @Published var currentPhoneNumber: String?
    
    private let userDefaults = UserDefaults.standard
    private let userIDKey = "current_user_id"
    private let phoneKey = "current_phone"
    
    init() {
        loadStoredAuth()
    }
    
    func getDevicePhoneNumber() -> String? {
        let networkInfo = CTTelephonyNetworkInfo()
        let carrier = networkInfo.subscriberCellularProvider
        
        // Method 1: Try to get from carrier (limited access)
        if let mobileCountryCode = carrier?.mobileCountryCode,
           let mobileNetworkCode = carrier?.mobileNetworkCode {
            // This won't give actual number but we can try other methods
        }
        
        // Method 2: Check if stored from previous manual entry
        if let storedNumber = UserDefaults.standard.string(forKey: "detected_phone_number") {
            return storedNumber
        }
        
        return nil
    }
    
    func detectPhoneNumberFromSIM() -> String? {
        // Note: iOS doesn't allow direct access to phone number from SIM
        // This is a placeholder for demonstration
        return nil
    }
    
    func storeDetectedPhoneNumber(_ number: String) {
        UserDefaults.standard.set(number, forKey: "detected_phone_number")
    }
    
    func generateUserID(from phoneNumber: String) -> String {
        let cleanPhone = phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        let data = Data(cleanPhone.utf8)
        let hash = SHA256.hash(data: data)
        return "user_" + hash.compactMap { String(format: "%02x", $0) }.joined().prefix(16)
    }
    
    func validatePhoneNumber(_ phone: String) -> Bool {
        let cleanPhone = phone.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        return cleanPhone.count >= 10 && cleanPhone.count <= 15
    }
    
    func sendOTP(to phoneNumber: String) async -> Bool {
        guard validatePhoneNumber(phoneNumber) else { return false }
        
        await MainActor.run {
            print("Sending OTP to: \(phoneNumber)")
        }
        
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        return true
    }
    
    func verifyOTP(_ otp: String, for phoneNumber: String) async -> Bool {
        guard otp == "123456" else { return false }
        
        let userID = generateUserID(from: phoneNumber)
        storeDetectedPhoneNumber(phoneNumber)
        
        await MainActor.run {
            self.currentUserID = userID
            self.currentPhoneNumber = phoneNumber
            self.isAuthenticated = true
            self.saveAuth()
        }
        
        return true
    }
    
    func logout() {
        currentUserID = nil
        currentPhoneNumber = nil
        isAuthenticated = false
        clearStoredAuth()
    }
    
    private func saveAuth() {
        userDefaults.set(currentUserID, forKey: userIDKey)
        userDefaults.set(currentPhoneNumber, forKey: phoneKey)
    }
    
    private func loadStoredAuth() {
        currentUserID = userDefaults.string(forKey: userIDKey)
        currentPhoneNumber = userDefaults.string(forKey: phoneKey)
        isAuthenticated = currentUserID != nil && currentPhoneNumber != nil
    }
    
    private func clearStoredAuth() {
        userDefaults.removeObject(forKey: userIDKey)
        userDefaults.removeObject(forKey: phoneKey)
    }
}