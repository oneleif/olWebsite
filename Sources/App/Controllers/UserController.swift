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
        router.get("register", use: registerHandler)
        router.get("login", use: loginHandler)
        
        router.post("register", use: register)
        
        router.get(use: publicIndexHandler)
        
        router.get("feedback", use: feedbackHandler)
        router.get("search", use: searchHandler)
        router.get("projects", use: projectsHandler)
        router.get("blogs", use: blogsHandler)
        router.get("members", use: membersHandler)
        
        let authSessionRouter = router.grouped(User.authSessionsMiddleware())
        authSessionRouter.post("login", use: login)
        
        let protectedRouter = authSessionRouter.grouped(RedirectMiddleware<User>(path: "/"))
        protectedRouter.get("home", use: indexHandler)
        
        protectedRouter.get("profile", use: profile)
        protectedRouter.post("updateProfile", use: updateProfile)
        
        protectedRouter.get("dashboard", use: dashboardHandler)
        
        
        router.get("logout", use: logout)
    }
    
    // MARK: View Handlers
    
    func indexHandler(_ req: Request) throws -> Future<View> {
        let user = try req.requireAuthenticated(User.self)
        let context = HomeContext(user: user, isAuth: true)
        return try req.view().render("Children/index", context)
    }
    
    func publicIndexHandler(_ req: Request) throws -> Future<View> {
        let context = HomeContext(user: nil, isAuth: false)
        return try req.view().render("Children/index", context)
    }
    
    func feedbackHandler(_ req: Request) throws -> Future<View> {
        let context = LeafContext(title: "Login", user: nil)
        return try req.view().render("Children/feedback", context)
    }
    
    func searchHandler(_ req: Request) throws -> Future<View> {
        let context = LeafContext(title: "Search", user: nil)
        return try req.view().render("Children/search", context)
    }
    
    func projectsHandler(_ req: Request) throws -> Future<View> {
        let context = LeafContext(title: "Projects", user: nil)
        return try req.view().render("Children/projects", context)
    }
    
    func blogsHandler(_ req: Request) throws -> Future<View> {
        let context = LeafContext(title: "Blogs", user: nil)
        return try req.view().render("Children/blogs", context)
    }
    
    func membersHandler(_ req: Request) throws -> Future<View> {
        let context = LeafContext(title: "Members", user: nil)
        return try req.view().render("Children/members", context)
    }
    
    func dashboardHandler(_ req: Request) throws -> Future<User> {
        let user = try req.requireAuthenticated(User.self)
        return Future.map(on: req) { return user }
    }
    
    func loginHandler(_ req: Request) throws -> Future<View> {
        let context = LeafContext(title: "Login", user: nil)
        return try req.view().render("Children/login", context)
    }
    
    func registerHandler(_ req: Request) throws -> Future<View> {
        let context = LeafContext(title: "Register", user: nil)
        return try req.view().render("Children/register", context)
    }
    
    func listSolutionsHandler(_ req: Request) throws -> Future<View> {
        return Solution.query(on: req).all().flatMap { (solutions) -> Future<View> in
            let user = try req.requireAuthenticated(User.self)
            let context = SolutionsContext(solutions: solutions, user: user, title: "Solutions")
            return try req.view().render("Children/listSolutions", context)
        }
    }
    
    func addSolutionHandler(_ req: Request) throws -> Future<View> {
        let user = try req.requireAuthenticated(User.self)
        let context = LeafContext(title: "Add Solution", user: user)
        return try req.view().render("Children/addSolution", context)
    }
    
    func solutionHandler(_ req: Request) throws -> Future<View> {
        
        return try req.parameters.next(Solution.self)
            .flatMap { solution in
                let user = try req.requireAuthenticated(User.self)
                let context = SolutionContext(solution: solution, user: user, title: "Solution")
                return try req.view().render("canvas", context)
        }
    }
    
    // MARK: Request Handlers
    
    func register(_ req: Request) throws -> Future<Response> {
        return try req.content.decode(User.self).flatMap { user in
            return User.query(on: req).filter(\User.username == user.username).first().flatMap { result in
                if let _ = result {
                    return Future.map(on: req) {
                        return req.redirect(to: "/register")
                    }
                }
                user.password = try BCryptDigest().hash(user.password)
                
                return user.save(on: req).map { _ in
                    return req.redirect(to: "/login")
                }
            }
        }
    }
    
    func login(_ req: Request) throws -> Future<Response> {
        return try req.content.decode(User.self).flatMap { user in
            return User.authenticate(
                username: user.username,
                password: user.password,
                using: BCryptDigest(),
                on: req
            ).map { user in
                guard let user = user else {
                    return req.redirect(to: "/login")
                }
                
                try req.authenticateSession(user)
                return req.redirect(to: "/home")
            }
        }
    }
    
    func newSolution(_ req: Request) throws -> Future<Response> {
        return try req.content.decode(Solution.self).flatMap { solution in
            solution.json = solution.json.replacingOccurrences(of: "\"", with: "")
            return solution.save(on: req).map { _ in
                req.redirect(to: "/")
            }
        }
    }
    
    func updateSolution(_ req: Request) throws -> Future<Response> {
        _ = try req.requireAuthenticated(User.self)
        return try req.content.decode(Solution.self).flatMap { updatedsolution in
            updatedsolution.json = updatedsolution.json.replacingOccurrences(of: "\"", with: "")
            return updatedsolution.save(on: req).map { _ in
                req.redirect(to: "/")
            }
        }
    }
    
    
    func deleteSolution(_ req: Request) throws -> Future<Response> {
        _ = try req.requireAuthenticated(User.self)
        return try req.content.decode(Solution.self).flatMap { updatedsolution in
            return updatedsolution.delete(on: req).map { _ in
                req.redirect(to: "/")
            }
        }
    }
    
    func profile(_ req: Request) throws -> Future<User> {
        let user = try req.requireAuthenticated(User.self)
        return Future.map(on: req) { return user }
    }
    
    func updateProfile(_ req: Request) throws -> Future<(User)> {
        let user = try req.requireAuthenticated(User.self)
        return try req.content.decode(User.self).flatMap { updatedUser in
            if updatedUser.id != user.id {
                struct BadAccount: Error {
                    let desc = "BAD"
                }
                return req.future(error: BadAccount())
            }
            return updatedUser.save(on: req)
        }
    }
    
    func logout(_ req: Request) throws -> Future<Response> {
        try req.unauthenticateSession(User.self)
        return Future.map(on: req) { return req.redirect(to: "/login") }
    }
}


struct LeafContext: Encodable {
    let title: String
    let user: User?
}

struct SolutionsContext: Encodable {
    let solutions: [Solution]
    let user: User
    let title: String
}

struct SolutionContext: Encodable {
    let solution: Solution
    let user: User
    let title: String
}

struct HomeContext: Encodable {
    let title: String = "Home"
    let user: User?
    let isAuth: Bool
}
