import SwiftUI

struct SilentAuthView: View {
    @StateObject private var authManager = SilentAuthManager()
    @State private var animateGradient = false
    
    var body: some View {
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
                    
                    if authManager.isLoading {
                        Text("entering the void")
                            .font(.system(size: 14, weight: .light))
                            .foregroundColor(.white.opacity(0.6))
                    } else {
                        Text("welcome to the void")
                            .font(.system(size: 14, weight: .light))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                if authManager.isLoading {
                    VStack(spacing: 24) {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white.opacity(0.6)))
                        
                        Text("authenticating device")
                            .font(.system(size: 12, weight: .light))
                            .foregroundColor(.white.opacity(0.4))
                    }
                } else if authManager.isAuthenticated {
                    VStack(spacing: 16) {
                        Text("\(authManager.currentUserID?.prefix(16) ?? "unknown")")
                            .font(.system(size: 12, weight: .light, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text("device authenticated")
                            .font(.system(size: 12, weight: .light))
                            .foregroundColor(.green.opacity(0.6))
                    }
                }
                
                Spacer()
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct SilentAuthenticatedView: View {
    @ObservedObject var authManager: SilentAuthManager
    
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
                    
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.green.opacity(0.7))
                        Text("frictionless auth")
                            .font(.system(size: 12, weight: .light))
                            .foregroundColor(.green.opacity(0.7))
                    }
                }
                
                Spacer()
                
                VStack(spacing: 16) {
                    Button("reset device") {
                        authManager.resetAndReauth()
                    }
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(.red.opacity(0.6))
                    
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
    SilentAuthView()
}