//
//  SocialController.swift
//  App
//
//  Created by Zach Eriksen on 10/23/19.
//

import Vapor
import FluentSQL
import Crypto
import Authentication

struct BadUser: Error {
    let description = "BadUser"
}

class SocialController: RouteCollection {
    func boot(router: Router) throws {
        let authSessionRouter = router.grouped(User.authSessionsMiddleware())
        
        authSessionRouter.get("social", use: socialHandler)
        authSessionRouter.post("social", use: updateSocialHandler)
    }
    
    // MARK: Handlers
    
    func socialHandler(_ req: Request) throws -> Future<SocialInformation> {
        let user = try req.requireAuthenticated(User.self)
        
        guard let userId = user.id else {
            return req.future(error: BadUser())
        }
        
        return Future.map(on: req) { user.social ?? SocialInformation(id: userId, username: user.username, firstName: "", lastName: "", email: "", discordUsername: "", githubUsername: "", tags: [], profileImage: "", biography: "", links: [], location: "") }
    }
    
    func updateSocialHandler(_ req: Request) throws -> Future<SocialInformation> {
        _ = try req.requireAuthenticated(User.self)
        
        return try req.content.decode(SocialInformation.self)
            .flatMap { social in
                return User.query(on: req)
                    .filter(\User.id == social.id)
                    .first()
                    .flatMap { result in
                        guard let result = result else {
                            return req.future(error: BadPost())
                        }
                        
                        result.social = social
                        
                        return result.update(on: req).map { _ in social }
                }
        }
    }
}
