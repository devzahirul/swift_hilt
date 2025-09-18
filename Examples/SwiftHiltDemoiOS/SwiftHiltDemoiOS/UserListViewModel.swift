//
//  UserListViewModel.swift
//  SwiftHiltDemoiOS
//
//  Created by lynkto_1 on 9/18/25.
//


import SwiftUI
import SwiftHilt

class UserListViewModel: ObservableObject {
    private var userreposiotry: UserRepository
    
    @Published var user: UserInfo? = nil
    
    init(userreposiotry: UserRepository = resolve()) {
        self.userreposiotry = userreposiotry
    }
    
    func load() {
        user = self.userreposiotry.getUsers()
    }
}
