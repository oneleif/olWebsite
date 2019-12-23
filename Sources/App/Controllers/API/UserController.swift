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

enum UserValidationError: Error {
    case usernameAlreadyTaken
}

class UserController: RouteCollection {
    func boot(router: Router) throws {
        
        router.post(RegisterUserRequest.self, at: "api", "register", use: self.register)
        
        let authSessionRouter = router.grouped(User.authSessionsMiddleware())
        authSessionRouter.post("api", "login", use: login)
        
        router.get("api", "logout", use: logout)
    }
    
    // MARK: Request Handlers
    
    func register(_ req: Request, _ registerBody: RegisterUserRequest) throws -> Future<HTTPResponse> {
        try registerBody.validate()
        
        return User.query(on: req)
            .filter(\User.username == registerBody.username)
            .first()
            .flatMap { existingUser -> Future<User> in
                guard existingUser == nil else {
                    throw UserValidationError.usernameAlreadyTaken
                }
                
            let hashedPassword = try BCryptDigest().hash(registerBody.password)
            let user = User(username: registerBody.username, password: hashedPassword)
                
                return Future.map(on: req) { user }
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
        }.map(to: HTTPResponse.self) { publicUser in
            var response = HTTPResponse(status: .ok)
            try JSONEncoder().encode(publicUser, to: &response, on: req)
            return response
        }.mapIfError { error -> HTTPResponse in
            guard let error = error as? UserValidationError else {
                return HTTPResponse(status: .internalServerError)
            }
            
            switch error {
            case .usernameAlreadyTaken:
                let errorBody = [
                    "message": "Username already taken"
                ]
                var response = HTTPResponse(status: .badRequest)
                try? JSONEncoder().encode(errorBody, to: &response, on: req)
                return response
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
