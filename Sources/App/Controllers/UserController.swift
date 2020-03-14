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
        router.post(LoginRequest.self, at: "api", "login", use: self.login)
        router.post(RefreshTokenRequest.self, at: "api", "refresh-token", use: self.refreshToken)
        
        let authSessionRouter = router.grouped(JWTMiddleware())
        authSessionRouter.get("api", "logout", use: logout)
    }
    
    // MARK: Request Handlers
    
    func register(_ req: Request, _ registerRequest: RegisterUserRequest) throws -> Future<Response> {
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
        .flatMap(to: Response.self) { publicUser in
            return publicUser.encode(status: .created, for: req)
        }
    }
    
    func login(_ req: Request, _ loginRequest: LoginRequest) throws -> Future<LoginResponse> {
        let userService = try req.make(UserService.self)
        let authService = try req.make(AuthService.self)
        
        return userService.authorize(
            email: loginRequest.email,
            password: loginRequest.password,
            on: req
        )
        .flatMap(to: LoginResponse.self) { user in
            guard let user = user else {
                throw Abort(.unauthorized)
            }
            let publicUser = PublicUserResponse(id: user.id, email: user.email, social: user.social)
            return try authService.createAccessToken(for: user, on: req).map({
                LoginResponse(token: $0, user: publicUser)
            })
        }
    }
    
    func refreshToken(_ req: Request, _ refreshTokenRequest: RefreshTokenRequest) throws -> Future<AccessTokenResponse> {
        try req.validate(refreshTokenRequest)
        
        let authService = try req.make(AuthService.self)
        
        return try authService.refreshAccessToken(refreshToken: refreshTokenRequest.refreshToken, on: req)
    }
    
    func logout(_ req: Request) throws -> Future<HTTPStatus> {
        let authService = try req.make(AuthService.self)
        
        return try authService.invalidateToken(req.token, on: req)
            .transform(to: .noContent)
    }
}
