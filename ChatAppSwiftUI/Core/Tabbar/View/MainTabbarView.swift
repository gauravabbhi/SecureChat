//
//  MainTabbarView.swift
//  ChatAppSwiftUI
//
//  Created by Gaurav Abbhi on 23/5/2024.
//

import SwiftUI

struct MainTabbarView: View {
    @State private var selectedTab: Int = 0
    @StateObject private var viewModel = InboxViewModel()
    @Environment(\.colorScheme) var colorScheme
    private var user: User? {
        return viewModel.currentUser
    }
    
    var body: some View {
        TabView {
            InboxView()
                .tabItem {
                    VStack {
                        Image(systemName: "text.bubble")
                            .environment(\.symbolVariants,selectedTab == 0 ? .fill : .none)
                        Text("Chats")
                    }
                }
                .onAppear{
                    selectedTab = 0
                }
            
            Text("NFC")
                .tabItem {
                    VStack {
                        Image(systemName: "simcard.2")
                            .environment(\.symbolVariants,selectedTab == 2 ? .fill : .none)
                        Text("NFC Registeration")
                    }
                }
                .onAppear{
                    selectedTab = 2
                }
        }
        .tint(colorScheme == .dark ? .white : .black)
        .toolbarBackground(Color(colorScheme == .dark ? .black : .white), for: .tabBar)
    }
}

#Preview {
    MainTabbarView()
}
