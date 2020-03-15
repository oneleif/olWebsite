//
//  SocialController.swift
//  App
//
//  Created by Zach Eriksen on 10/23/19.
//

import Vapor
import FluentPostgreSQL
import Crypto
import Authentication

struct BadUser: Error {
    let description = "BadUser"
}

class SocialController: RouteCollection {
    func boot(router: Router) throws {
        let authSessionRouter = router.grouped(JWTMiddleware())
        
        authSessionRouter.get("api", "social", use: socialHandler)
        authSessionRouter.post("api", "social", use: updateSocialHandler)
    }
    
    // MARK: Handlers
    /// SocialHandler
    /// - Parameter: Request with an Authenticated `User`
    ///
    /// - Returns: `SocialInformation` of `User`
    func socialHandler(_ req: Request) throws -> Future<SocialInformation> {
        return try req.authorizedUser().map { user in
            return user.social ?? SocialInformation(
                id: user.id,
                username: "",
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
            
        }

    }
    
    /// UpdateSocialHandler
    /// - Parameter: Request with an Authenticated `User`
    ///             Body with a `SocialInformation` to update the User's `SocialInformation`
    ///
    /// - Throws: Error `BadUser` if the `\User.id != social.id` 
    ///
    /// - Returns: `SocialInformation` of `User`
    func updateSocialHandler(_ req: Request) throws -> Future<SocialInformation> {
        return try req.authorizedUser().flatMap { user in
            return try req.content.decode(SocialInformation.self)
                .flatMap { (social) -> Future<SocialInformation> in
                    return User.query(on: req)
                        .filter(\User.id == social.id)
                        .first()
                        .flatMap { result in
                            guard let result = result else {
                                return req.future(error: BadUser())
                            }
                            
                            result.social = social
                            
                            return result.update(on: req).map { _ in social }
                    }
            }
        }
    }
}
