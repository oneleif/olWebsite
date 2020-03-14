//
//  JWTMiddleware.swift
//  App
//
//  Created by Arkadiusz Żmudzin on 13/03/2020.
//

import Vapor
import JWT

class JWTMiddleware: Middleware {
    
    func respond(to request: Request, chainingTo next: Responder) throws -> EventLoopFuture<Response> {
        let token = request.token
        guard !token.isEmpty else {
            throw Abort(.unauthorized, reason: "No Access Token")
        }
        
        do {
            try TokenHelpers.verifyToken(token)
            return try next.respond(to: request)
        } catch let error as JWTError {
            throw Abort(.unauthorized, reason: error.reason)
        }
    }
}
