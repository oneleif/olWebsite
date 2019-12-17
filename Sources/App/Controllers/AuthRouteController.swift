import Vapor
import FluentSQL
import Crypto
import Authentication

class AuthRouteController: RouteCollection {
    func boot(router: Router) throws {
        let authSessionRouter = router.grouped(User.authSessionsMiddleware())
        let protectedRouter = authSessionRouter.grouped(RedirectMiddleware<User>(path: "/login"))
        protectedRouter.get("dashboard", use: dashboardHandler)
        protectedRouter.get("authPosts", use: listPostsHandler)
        protectedRouter.get("authIndex", use: authIndexHandler)
        protectedRouter.get("createPost", use: createPostHandler)
        protectedRouter.get("viewPost", PostItem.parameter, use: viewPostHandler)
        protectedRouter.get("social", use: socialHandler)
        protectedRouter.get("authMembers", use: authMembersHandler)

        protectedRouter.post("createPostAPI", use: createPostAPIHandler)
    }

    func authIndexHandler(_ req: Request) throws -> Future<View> {
        print(#function)
        let user = try req.requireAuthenticated(User.self)
        return try req.view().render("Children/authIndex", IndexContext(title: "oneleif"))
    }

    func authMembersHandler(_ req: Request) throws -> Future<View> {
        print(#function)
         return User.query(on: req).all().flatMap { (users) -> Future<View> in
                let members = users.compactMap { $0.social }

                return try req.view().render("Children/authMembers", MembersContext(title: "Meet The Team", members: members))

         }
    }

    func socialHandler(_ req: Request) throws -> Future<View> {
        print(#function)
        let user = try req.requireAuthenticated(User.self)
        if let social = user.social {
            return try req.view().render("Children/social", SocialContext(title: "Your account", user: social))
        } else {
            return try req.view().render("Children/index", IndexContext(title: "oneleif"))
        }
        
    }

    func dashboardHandler(_ req: Request) throws -> Future<View> {
        print(#function)
        return PostItem.query(on: req).all()
            .flatMap { (posts) -> Future<View> in
            let user = try req.requireAuthenticated(User.self)
            if let social = user.social {
                let context = DashboardContext(title: "Welcome to your dashboard", user: social, posts: posts)
                return try req.view().render("Children/dashboard", context)
            } else {
                return try req.view().render("Children/index", IndexContext(title: "oneleif"))
            }
        }
    }

    func listPostsHandler(_ req: Request) throws -> Future<View> {
        print(#function)
        return PostItem.query(on: req).all().flatMap { (posts) -> Future<View> in
            let user = try req.requireAuthenticated(User.self)
            if let social = user.social {
                let context = AuthPostsContext(title: "Posts", user: social, posts: posts)
                // return req.redirect(to: "/login")
                return try req.view().render("Children/authPosts", context) 
            } else {
                return try req.view().render("Children/index", IndexContext(title: "oneleif"))
            }
        }
    }

    func createPostHandler(_ req: Request) throws -> Future<View> {
        print(#function)
        
        let user = try req.requireAuthenticated(User.self)
        if let social = user.social {
            let context = CreatePostContext(title: "Create Post", user: social)
            return try req.view().render("Children/createPost", context) 
        } else {
            return try req.view().render("Children/index", IndexContext(title: "oneleif"))
        }
    }

    func createPostAPIHandler(_ req: Request) throws -> Future<Response> {
        print(#function)
        let user = try req.requireAuthenticated(User.self)

        if let social = user.social {
            //Create post
            return try PostController().addPostHandler(req).map { post in
                guard let id = post.id else {
                    return req.redirect(to: "authPosts")
                }
                return req.redirect(to: "viewPost/\(id)")
            }
        } else {
            return Future.map(on: req) { 
                return req.redirect(to:"Children/index")
            }
        }
    }

    func viewPostHandler(_ req: Request) throws -> Future<View> {
        print(#function)
        let user = try req.requireAuthenticated(User.self)
        return try req.parameters.next(PostItem.self)
            .flatMap { post in
            if let social = user.social {
                let context = AuthPostContext(title: "Post", user: social, post: post)
                return try req.view().render("Children/authPost", context) 
            } else {
                return try req.view().render("Children/index", IndexContext(title: "oneleif"))
            }
        }
    
    }

}