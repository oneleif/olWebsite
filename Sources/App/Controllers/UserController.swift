//
//  UserController.swift
//  App
//
//  Created by Zach Eriksen on 3/21/19.
//

import Vapor
import FluentPostgreSQL
import Crypto
import Authentication

class UserController: RouteCollection {
    func boot(router: Router) throws {
        
        router.post(RegisterUserRequest.self, at: "api", "register", use: self.register)
        
        let authSessionRouter = router.grouped(User.authSessionsMiddleware())
        authSessionRouter.post(LoginRequest.self, at: "api", "login", use: self.login)
        
        router.get("api", "logout", use: logout)
    }
    
    // MARK: Request Handlers
    
    func register(_ req: Request, _ registerRequest: RegisterUserRequest) throws -> Future<HTTPResponse> {
        try req.validate(registerRequest)
        let userService = try req.make(UserService.self)
        
        return userService.isEmailTaken(email: registerRequest.email, on: req)
            .flatMap { isTaken -> EventLoopFuture<User> in
                guard !isTaken else {
                    throw BasicValidationError("email already taken")
                }
                
                return try userService.createUser(registerRequest: registerRequest, on: req)
        }.map(to: PublicUserResponse.self) { user in
            PublicUserResponse(id: user.id, email: user.email, social: user.social)
        }
        .map(to: HTTPResponse.self) { publicUser in
            var response = HTTPResponse(status: .created)
            try JSONEncoder().encode(publicUser, to: &response, on: req)
            return response
        }
    }
    
    func login(_ req: Request, _ loginRequest: LoginRequest) throws -> Future<HTTPResponse> {
        let userService = try req.make(UserService.self)
        
        return userService.authorize(
            email: loginRequest.email,
            password: loginRequest.password,
            on: req
        )
        .map(to: PublicUserResponse.self) { user in
            guard let user = user else {
                throw BasicValidationError("Could not authorize User")
            }
            try req.authenticateSession(user)
            return PublicUserResponse(id: user.id, email: user.email, social: user.social)
        }
        .map(to: HTTPResponse.self) { publicUser in
            var response = HTTPResponse(status: .created)
            try JSONEncoder().encode(publicUser, to: &response, on: req)
            return response
        }
    }
    
    func logout(_ req: Request) throws -> Future<HTTPStatus> {
        try req.unauthenticateSession(User.self)
        return req.future(.noContent)
    }
}
