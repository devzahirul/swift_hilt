//
//  UserRepository.swift
//  SwiftHiltDemoiOS
//
//  Created by lynkto_1 on 9/18/25.
//



struct UserInfo {
    let name: String
    let email: String
}


protocol UserRepository {
    func getUsers() -> UserInfo
}
