//
//  User.swift
//  App
//
//  Created by Zach Eriksen on 3/21/19.
//

import FluentSQLite
import Vapor
import Authentication

struct SocialInformation: Content {
    var id: Int?
    var username: String = ""
    var firstName: String = ""
    var lastName: String = ""
    var email: String = ""
    var discordUsername: String = ""
    var githubUsername: String = ""
    var tags: [String] = []
    var profileImage: String = ""
    var biography: String = ""
    var links: [String] = []
    var location: String = ""
}

final class User: SQLiteModel {
    var id: Int?
    // Auth Information
    var username: String
    var password: String
    // Social Information
    var social: SocialInformation?
    
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
extension User: Parameter {
    typealias ResolvedParameter = String
    
    static func resolveParameter(_ parameter: String,
                                 on container: Container) throws -> ImageUpload.ResolvedParameter {
        return parameter
    }
}
