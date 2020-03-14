//
//  AccessToken.swift
//  App
//
//  Created by Arkadiusz Żmudzin on 14/03/2020.
//

import FluentPostgreSQL
import Vapor

final class AccessToken: PostgreSQLModel {
    var id: Int?
    
    var userId: User.ID
    var value: String
    var expiresAt: Date
    var refreshTokenId: RefreshToken.ID
    
    init(id: Int? = nil,
         value: String,
         refreshTokenId: RefreshToken.ID,
         userId: User.ID,
         expiresAt: Date) {
        self.id = id
        self.value = value
        self.expiresAt = expiresAt
        self.refreshTokenId = refreshTokenId
        self.userId = userId
    }
}

extension AccessToken {
    var refreshToken: Parent<AccessToken, RefreshToken> {
        return self.parent(\.refreshTokenId)
    }
    
    var user: Parent<AccessToken, User> {
        return self.parent(\.userId)
    }
}

extension AccessToken: Migration { }
extension AccessToken: Parameter { }
