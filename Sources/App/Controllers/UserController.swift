//
//  UserController.swift
//  App
//
//  Created by Zach Eriksen on 3/21/19.
//

import Vapor
import FluentSQL
import Crypto
import Authentication

class UserController: RouteCollection {
    func boot(router: Router) throws {
        
        router.post("register", use: register)
        
        
        let authSessionRouter = router.grouped(User.authSessionsMiddleware())
        
        authSessionRouter.post("login", use: login)
        
        router.get("logout", use: logout)
    }
    
    // MARK: Request Handlers
    
    func register(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.content.decode(User.self).flatMap { user in
            return User.query(on: req).filter(\User.username == user.username).first().flatMap { result in
                if let _ = result {
                    return Future.map(on: req) {
                        return .badRequest
                    }
                }
                user.password = try BCryptDigest().hash(user.password)
                
                return user.save(on: req).map { _ in
                    return .accepted
                }
            }
        }
    }
    
    func login(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.content.decode(User.self).flatMap { user in
            return User.authenticate(
                username: user.username,
                password: user.password,
                using: BCryptDigest(),
                on: req
            ).map { user in
                guard let user = user else {
                    return .badRequest
                }
                
                try req.authenticateSession(user)
                return .accepted
            }
        }
    }
    
    func logout(_ req: Request) throws -> Future<HTTPStatus> {
        try req.unauthenticateSession(User.self)
        return Future.map(on: req) { return .accepted }
    }
}
