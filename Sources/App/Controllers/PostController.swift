//
//  PostController.swift
//  App
//
//  Created by Zach Eriksen on 10/23/19.
//

import Vapor
import FluentPostgreSQL
import Crypto
import Authentication

struct BadPost: Error {
    let description = "BadPost"
}

class PostController: RouteCollection {
    func boot(router: Router) throws {
        let authSessionRouter = router.grouped(JWTMiddleware())
        
        authSessionRouter.get("api", "post", PostItem.parameter, use: postHandler)
        authSessionRouter.get("api", "posts", use: postsHandler)
        
        authSessionRouter.post("api", "post", use: addPostHandler)
        authSessionRouter.put("api", "post", PostItem.parameter, use: updatePost)
        authSessionRouter.delete("api", "post", PostItem.parameter, use: deletePostHandler)
    }
    
    // MARK: Handlers
    
    func addPostHandler(_ req: Request) throws -> Future<PostItem> {
        return try req.content.decode(PostItem.self)
            .flatMap { post in
                return PostItem.query(on: req)
                    .filter(\PostItem.id == post.id)
                    .first()
                    .flatMap { result in
                        if let _ = result {
                            return req.future(error: BadPost())
                        }
                        return post.save(on: req)
                }
        }
    }
    
    func postsHandler(_ req: Request) throws -> Future<[PostItem]> {
        try req.authorizedUser().flatMap { _ in
            return PostItem.query(on: req).all()
        }
    }
    
    
    func postHandler(_ req: Request) throws -> Future<PostItem> {
        let postId = Int(try req.parameters.next(Int.self))
        
        return PostItem.query(on: req)
            .filter(\PostItem.id == postId)
            .first()
            .flatMap { result in
                
                guard let result = result else {
                    return req.future(error: BadPost())
                }
                
                return req.future(result)
        }
    }
    
    func updatePost(_ req: Request) throws -> Future<PostItem> {
        let postId = Int(try req.parameters.next(Int.self))
        
        return try req.authorizedUser().flatMap(to: PostItem.self) { user in
            return try req.content.decode(PostItem.self)
                .flatMap { updatedPostItem in
                    if updatedPostItem.author != user.id {
                        return req.future(error: BadPost())
                    }
                    return PostItem.query(on: req)
                        .filter(\PostItem.id == postId)
                        .first()
                        .flatMap { postItem in
                            guard let item = postItem else {
                                return req.future(error: BadPost())
                            }
                            
                            updatedPostItem.id = item.id
                            
                            return updatedPostItem.update(on: req)
                    }
            }
        }
    }
    
    func deletePostHandler(_ req: Request) throws -> Future<HTTPStatus> {
        let postId = Int(try req.parameters.next(Int.self))
        
        return PostItem.query(on: req)
            .filter(\PostItem.id == postId)
            .first()
            .flatMap { result in
                guard let result = result else {
                    return req.future(error: BadPost())
                }
                
                return result.delete(on: req).map { .accepted }
        }
    }
}
