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
        
        router.post(RegisterUserRequest.self, at: "api", "register", use: self.register)
        
        let authSessionRouter = router.grouped(User.authSessionsMiddleware())
        authSessionRouter.post(LoginRequest.self, at: "api", "login", use: self.login)
        
        router.get("api", "logout", use: logout)
    }
    
    // MARK: Request Handlers
    
    func register(_ req: Request, _ registerRequest: RegisterUserRequest) throws -> Future<HTTPResponse> {
        try registerRequest.validate()
        
        return User.query(on: req)
            .filter(\User.username == registerRequest.username)
            .first()
            .flatMap { existingUser -> Future<User> in
                guard existingUser == nil else {
                    throw BasicValidationError("username already taken")
                }
                
                let hashedPassword = try BCryptDigest().hash(registerRequest.password)
                let user = User(username: registerRequest.username, password: hashedPassword)
                
                return req.future(user)
        }.flatMap { user in
            return user.save(on: req)
        }.flatMap { (user: User) -> EventLoopFuture<User> in
            user.social = SocialInformation(id: user.id,
                                            username: user.username,
                                            firstName: "",
                                            lastName: "",
                                            email: "",
                                            discordUsername: "",
                                            githubUsername: "",
                                            tags: [],
                                            profileImage: "",
                                            biography: "",
                                            links: [],
                                            location: "")
            
            return user.save(on: req)
        }.map(to: PublicUserResponse.self) { user in
            PublicUserResponse(id: user.id, username: user.username, social: user.social)
        }
        .map(to: HTTPResponse.self) { publicUser in
            var response = HTTPResponse(status: .created)
            try JSONEncoder().encode(publicUser, to: &response, on: req)
            return response
        }
    }
    
    func login(_ req: Request, _ loginRequest: LoginRequest) throws -> Future<HTTPStatus> {
        return User.authenticate(
            username: loginRequest.username,
            password: loginRequest.password,
            using: BCryptDigest(),
            on: req
        ).map { user in
            guard let user = user else {
                return .unauthorized
            }
            try req.authenticateSession(user)
            return .ok
        }
    }
    
    func logout(_ req: Request) throws -> Future<HTTPStatus> {
        try req.unauthenticateSession(User.self)
        return req.future(.noContent)
    }
}
