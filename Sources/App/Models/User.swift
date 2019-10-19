//
//  User.swift
//  App
//
//  Created by Zach Eriksen on 3/21/19.
//

import FluentSQLite
import Vapor
import Authentication

struct UserData: Content {
    let id: Int?
    let username: String
}

final class User: SQLiteModel {
    var id: Int?
    var username: String
    var password: String
    
    init(id: Int? = nil, username: String, password: String) {
        self.id = id
        self.username = username
        self.password = password
    }
}

extension User {
    var userData: UserData {
        return UserData(id: id, username: username)
    }
}

extension User: Content {}
extension User: Migration {}
extension User: PasswordAuthenticatable {
    static var usernameKey: WritableKeyPath<User, String> {
        return \User.username
    }
    static var passwordKey: WritableKeyPath<User, String> {
        return \User.password
    }
}
extension User: SessionAuthenticatable {}
