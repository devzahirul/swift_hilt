//
//  SwiftHiltDemoiOSApp.swift
//  SwiftHiltDemoiOS
//
//  Created by lynkto_1 on 9/18/25.
//

import SwiftUI

@main
struct SwiftHiltDemoiOSApp: App {
    
    init() {
        loadDependency()
    }
    
    var body: some Scene {
        WindowGroup {
            TaskListView()
        }
    }
}
