//
//  User.swift
//  App
//
//  Created by Zach Eriksen on 3/21/19.
//

import FluentSQLite
import Vapor
import Authentication


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
