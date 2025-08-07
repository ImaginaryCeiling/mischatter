//
//  ContentView.swift
//  app
//
//  Created by Shubham Patil on 8/7/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var silentAuthManager = SilentAuthManager()
    
    var body: some View {
        if silentAuthManager.isAuthenticated {
            SilentAuthenticatedView(authManager: silentAuthManager)
        } else {
            SilentAuthView()
                .environmentObject(silentAuthManager)
        }
    }
}

#Preview {
    ContentView()
}
