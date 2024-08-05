//
//  ContentView.swift
//  ChatAppSwiftUI
//
//  Created by Gaurav Abbhi on 2/5/2024.
//

import SwiftUI

struct RootView: View {
    @StateObject private var viewModel = RootViewModel()
    var body: some View {
        Group {
            if viewModel.userSession != nil {
                MainTabbarView()
            } else {
                WelcomeView()
            }
        }
    }
}

#Preview {
    RootView()
}
