//
//  ContentView.swift
//  SwiftHiltDemoiOS
//
//  Created by lynkto_1 on 9/18/25.
//

import SwiftUI
import SwiftHilt



struct ContentView: View {
    @StateObject var userListViewModel: UserListViewModel = resolve()
    
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text(userListViewModel.user?.name ?? "No Name")
        }
        .task {
            userListViewModel.load()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
