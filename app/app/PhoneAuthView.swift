import SwiftUI

struct PhoneAuthView: View {
    @StateObject private var authManager = PhoneAuthManager()
    @State private var phoneNumber = ""
    @State private var otp = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var otpSent = false
    @State private var animateGradient = false
    @State private var selectedCountry = Country.default
    @State private var showCountryPicker = false
    
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
                        
                        Text("enter the void")
                            .font(.system(size: 14, weight: .light))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    VStack(spacing: 24) {
                        VStack(spacing: 16) {
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
                            
                            if otpSent {
                                TextField("", text: $otp)
                                    .placeholder(when: otp.isEmpty) {
                                        Text("verification code")
                                            .foregroundColor(.white.opacity(0.4))
                                    }
                                    .keyboardType(.numberPad)
                                    .font(.system(size: 18, weight: .light))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.white.opacity(0.1))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                                            )
                                    )
                                    .disabled(isLoading)
                                    .transition(.move(edge: .top).combined(with: .opacity))
                            }
                        }
                        
                        if otpSent && !otp.isEmpty {
                            Text("code sent to \(selectedCountry.dialCode) \(phoneNumber)")
                                .font(.system(size: 12, weight: .light))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        
                        Button(action: {
                            if !otpSent {
                                sendOTP()
                            } else {
                                verifyOTP()
                            }
                        }) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                } else {
                                    Text(otpSent ? "verify" : "continue")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.black)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.white)
                            )
                        }
                        .disabled(phoneNumber.isEmpty || isLoading || (otpSent && otp.isEmpty))
                        .opacity(phoneNumber.isEmpty || isLoading || (otpSent && otp.isEmpty) ? 0.5 : 1.0)
                        
                        if otpSent {
                            Button("resend code") {
                                sendOTP()
                            }
                            .font(.system(size: 14, weight: .light))
                            .foregroundColor(.white.opacity(0.6))
                            .disabled(isLoading)
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
    
    private func sendOTP() {
        let fullNumber = PhoneFormatter.getFullNumber(countryCode: selectedCountry.dialCode, phoneNumber: phoneNumber)
        guard authManager.validatePhoneNumber(fullNumber) else {
            withAnimation(.easeInOut(duration: 0.3)) {
                errorMessage = "invalid phone number"
            }
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        Task {
            let success = await authManager.sendOTP(to: fullNumber)
            await MainActor.run {
                isLoading = false
                if success {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        otpSent = true
                    }
                } else {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        errorMessage = "failed to send code"
                    }
                }
            }
        }
    }
    
    private func verifyOTP() {
        let fullNumber = PhoneFormatter.getFullNumber(countryCode: selectedCountry.dialCode, phoneNumber: phoneNumber)
        isLoading = true
        errorMessage = ""
        
        Task {
            let success = await authManager.verifyOTP(otp, for: fullNumber)
            await MainActor.run {
                isLoading = false
                if !success {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        errorMessage = "invalid code"
                    }
                }
            }
        }
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {

        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

struct AuthenticatedView: View {
    @ObservedObject var authManager: PhoneAuthManager
    
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
                }
                
                Spacer()
                
                Button("disconnect") {
                    authManager.logout()
                }
                .font(.system(size: 16, weight: .light))
                .foregroundColor(.white.opacity(0.6))
                .padding(.bottom, 50)
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    PhoneAuthView()
}