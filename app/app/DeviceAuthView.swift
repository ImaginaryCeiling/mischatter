import SwiftUI

struct DeviceAuthView: View {
    @StateObject private var deviceAuthManager = DeviceAuthManager()
    @State private var phoneNumber = ""
    @State private var selectedCountry = Country.default
    @State private var showCountryPicker = false
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var authStep: AuthStep = .phoneEntry
    @State private var animateGradient = false
    
    enum AuthStep {
        case phoneEntry
        case biometric
        case deviceSetup
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    colors: [.black, .gray.opacity(0.9), .black],
                    startPoint: animateGradient ? .topLeading : .bottomTrailing,
                    endPoint: animateGradient ? .bottomTrailing : .topLeading
                )
                .ignoresSafeArea()
                .onAppear {
                    withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                        animateGradient.toggle()
                    }
                }
                
                VStack(spacing: 32) {
                    Spacer()
                    
                    VStack(spacing: 8) {
                        Text("mischatter")
                            .font(.system(size: 34, weight: .ultraLight, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text(stepSubtitle)
                            .font(.system(size: 14, weight: .light))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Group {
                        switch authStep {
                        case .phoneEntry:
                            phoneEntryView
                        case .biometric:
                            biometricView
                        case .deviceSetup:
                            deviceSetupView
                        }
                    }
                    .padding(.horizontal, 32)
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.system(size: 14, weight: .light))
                            .foregroundColor(.red.opacity(0.8))
                            .padding(.horizontal, 32)
                    }
                    
                    Spacer()
                    Spacer()
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showCountryPicker) {
            CountryPickerView(selectedCountry: $selectedCountry)
        }
    }
    
    private var stepSubtitle: String {
        switch authStep {
        case .phoneEntry:
            return "verify your identity"
        case .biometric:
            return "authenticate with device"
        case .deviceSetup:
            return "securing your device"
        }
    }
    
    private var phoneEntryView: some View {
        VStack(spacing: 24) {
            HStack(spacing: 0) {
                Button(action: {
                    showCountryPicker = true
                }) {
                    HStack(spacing: 8) {
                        Text(selectedCountry.flag)
                            .font(.system(size: 20))
                        Text(selectedCountry.dialCode)
                            .font(.system(size: 16, weight: .light))
                            .foregroundColor(.white)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .light))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }
                .disabled(isLoading)
                
                Rectangle()
                    .fill(.white.opacity(0.2))
                    .frame(width: 1)
                    .padding(.vertical, 12)
                
                TextField("", text: $phoneNumber)
                    .placeholder(when: phoneNumber.isEmpty) {
                        Text("phone number")
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .keyboardType(.phonePad)
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .disabled(isLoading)
                    .onChange(of: phoneNumber) { newValue in
                        let formatted = PhoneFormatter.format(newValue, for: selectedCountry)
                        if formatted != newValue {
                            phoneNumber = formatted
                        }
                    }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
            )
            
            Button(action: authenticateWithDevice) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: .black))
                    } else {
                        Image(systemName: "faceid")
                            .font(.system(size: 16, weight: .medium))
                        Text("authenticate with device")
                            .font(.system(size: 16, weight: .medium))
                    }
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.white)
                )
            }
            .disabled(phoneNumber.isEmpty || isLoading)
            .opacity(phoneNumber.isEmpty || isLoading ? 0.5 : 1.0)
        }
    }
    
    private var biometricView: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Image(systemName: "faceid")
                    .font(.system(size: 64, weight: .ultraLight))
                    .foregroundColor(.white.opacity(0.8))
                
                Text("place your face in view")
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(.white.opacity(0.8))
                
                Text("or use touch id if available")
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Button("retry authentication") {
                performBiometricAuth()
            }
            .font(.system(size: 16, weight: .light))
            .foregroundColor(.white.opacity(0.6))
            .disabled(isLoading)
        }
    }
    
    private var deviceSetupView: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 64, weight: .ultraLight))
                    .foregroundColor(.green.opacity(0.8))
                
                Text("device secured")
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(.white.opacity(0.8))
                
                Text("your device is now trusted for future logins")
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
            }
            
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
        }
    }
    
    private func authenticateWithDevice() {
        let fullNumber = PhoneFormatter.getFullNumber(countryCode: selectedCountry.dialCode, phoneNumber: phoneNumber)
        
        isLoading = true
        errorMessage = ""
        
        Task {
            let result = await deviceAuthManager.authenticateWithDevice(phoneNumber: fullNumber)
            
            await MainActor.run {
                switch result {
                case .success:
                    // Already authenticated, nothing more needed
                    isLoading = false
                    
                case .deviceNotTrusted:
                    // New device, proceed to setup
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        authStep = .deviceSetup
                    }
                    setupNewDevice(phoneNumber: fullNumber)
                    
                case .biometricFailed:
                    isLoading = false
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        authStep = .biometric
                    }
                    
                case .error(let message):
                    isLoading = false
                    withAnimation(.easeInOut(duration: 0.3)) {
                        errorMessage = message
                    }
                }
            }
        }
    }
    
    private func performBiometricAuth() {
        let fullNumber = PhoneFormatter.getFullNumber(countryCode: selectedCountry.dialCode, phoneNumber: phoneNumber)
        
        isLoading = true
        
        Task {
            let success = await deviceAuthManager.authenticateWithBiometrics()
            
            await MainActor.run {
                isLoading = false
                if success {
                    let userID = deviceAuthManager.generateUserID(from: fullNumber, deviceFingerprint: deviceAuthManager.generateDeviceFingerprint())
                    deviceAuthManager.currentUserID = userID
                    deviceAuthManager.currentPhoneNumber = fullNumber
                    deviceAuthManager.isAuthenticated = true
                } else {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        errorMessage = "authentication failed"
                    }
                }
            }
        }
    }
    
    private func setupNewDevice(phoneNumber: String) {
        Task {
            let success = await deviceAuthManager.establishDeviceTrust(phoneNumber: phoneNumber)
            
            await MainActor.run {
                if success {
                    // Complete authentication
                    let userID = deviceAuthManager.generateUserID(from: phoneNumber, deviceFingerprint: deviceAuthManager.generateDeviceFingerprint())
                    deviceAuthManager.currentUserID = userID
                    deviceAuthManager.currentPhoneNumber = phoneNumber
                    deviceAuthManager.isAuthenticated = true
                }
                
                isLoading = false
            }
        }
    }
}

struct DeviceAuthenticatedView: View {
    @ObservedObject var authManager: DeviceAuthManager
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                VStack(spacing: 12) {
                    Text("welcome to the void")
                        .font(.system(size: 28, weight: .ultraLight, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("\(authManager.currentUserID?.prefix(16) ?? "unknown")")
                        .font(.system(size: 12, weight: .light, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                    
                    if authManager.deviceTrusted {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.green.opacity(0.7))
                            Text("trusted device")
                                .font(.system(size: 12, weight: .light))
                                .foregroundColor(.green.opacity(0.7))
                        }
                    }
                }
                
                Spacer()
                
                VStack(spacing: 16) {
                    if authManager.deviceTrusted {
                        Button("reset device trust") {
                            authManager.resetDeviceTrust()
                        }
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(.red.opacity(0.6))
                    }
                    
                    Button("disconnect") {
                        authManager.logout()
                    }
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(.white.opacity(0.6))
                }
                .padding(.bottom, 50)
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    DeviceAuthView()
}