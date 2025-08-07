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
        
        return await callPhoneRegisterAPI(phoneNumber: phoneNumber)
    }
    
    func verifyOTP(_ otp: String, for phoneNumber: String) async -> Bool {
        return await callPhoneVerifyAPI(phoneNumber: phoneNumber, otp: otp)
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
    
    // MARK: - API Integration
    private func callPhoneRegisterAPI(phoneNumber: String) async -> Bool {
        guard let url = URL(string: "http://localhost:3000/api/auth/phone-register") else { return false }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "phoneNumber": phoneNumber
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                return true
            }
        } catch {
            print("Phone register API error: \(error)")
        }
        
        return false
    }
    
    private func callPhoneVerifyAPI(phoneNumber: String, otp: String) async -> Bool {
        guard let url = URL(string: "http://localhost:3000/api/auth/phone-verify") else { return false }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "phoneNumber": phoneNumber,
            "otp": otp
        ]
        
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
                
                storeDetectedPhoneNumber(phoneNumber)
                
                await MainActor.run {
                    self.currentUserID = userId
                    self.currentPhoneNumber = phoneNumber
                    self.isAuthenticated = true
                    self.saveAuth()
                }
                
                // Store token for API calls
                UserDefaults.standard.set(token, forKey: "auth_token")
                
                return true
            }
        } catch {
            print("Phone verify API error: \(error)")
        }
        
        return false
    }
}