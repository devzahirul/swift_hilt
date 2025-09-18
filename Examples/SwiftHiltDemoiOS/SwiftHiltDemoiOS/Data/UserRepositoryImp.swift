//
//  UserRepositoryImp.swift
//  SwiftHiltDemoiOS
//
//  Created by lynkto_1 on 9/18/25.
//


struct UserRepositoryImp: UserRepository {
    let source: UserDataSource
    func getUsers() -> UserInfo {
        return source.getUsers() ?? UserInfo(name: "Zahirul", email: "")
    }
}
