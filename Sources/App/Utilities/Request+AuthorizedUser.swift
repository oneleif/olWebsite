//
//  Request+AuthorizedUser.swift
//  App
//
//  Created by Arkadiusz Żmudzin on 13/03/2020.
//

import Vapor
import JWT

extension Request {
    var token: String {
        return self.http.headers[.authorization].first?.replacingOccurrences(of: "Bearer ", with: "") ?? ""
    }
    
    func authorizedUser() throws -> Future<User> {
        let userId = try TokenHelpers.getUserId(fromPayloadOf: self.token)
        
        return User.find(userId, on: self)
            .unwrap(or: Abort(.unauthorized, reason: "Authorized user not found"))
    }
}
