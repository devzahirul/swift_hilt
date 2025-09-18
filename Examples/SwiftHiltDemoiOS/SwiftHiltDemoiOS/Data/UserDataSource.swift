//
//  UserDataSource.swift
//  SwiftHiltDemoiOS
//
//  Created by lynkto_1 on 9/18/25.
//


protocol UserDataSource {
    func getUsers() -> UserInfo?
}

struct InMemoryUserDataSource: UserDataSource {
    func getUsers() -> UserInfo? {
        return nil
    }
}

struct APIUserDataSource: UserDataSource {
    func getUsers() -> UserInfo? {
        return nil
    }
}

struct CoreDataUserDataSource: UserDataSource {
    func getUsers() -> UserInfo? {
        return nil
    }
}
