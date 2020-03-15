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
            let payload = try TokenHelpers.verifyToken(token)
            let authService = try request.make(AuthService.self)
            
            return try authService.findAccessToken(value: payload.value, on: request)
                .unwrap(or: Abort(.unauthorized))
                .transform(to: try next.respond(to: request))
        } catch let error as JWTError {
            throw Abort(.unauthorized, reason: error.reason)
        }
    }
}
