import Vapor
import FluentSQL
import Crypto
import Authentication

class AuthRouteController: RouteCollection {
    func boot(router: Router) throws {
        let authSessionRouter = router.grouped(User.authSessionsMiddleware())
        let protectedRouter = authSessionRouter.grouped(RedirectMiddleware<User>(path: "/login"))
        protectedRouter.get("dashboard", use: dashboardHandler)
        protectedRouter.get("posts", use: listPostsHandler)
        protectedRouter.get("authIndex", use: authIndexHandler)
        protectedRouter.get("createPost", use: createPostHandler)
    }

    func authIndexHandler(_ req: Request) throws -> Future<View> {
        print(#function)
        let user = try req.requireAuthenticated(User.self)
        return try req.view().render("Children/authIndex", IndexContext(title: "oneleif"))
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
               let context = PostsContext(title: "Posts", user: social, posts: posts)
                return try req.view().render("Children/posts", context) 
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

    // func newSolution(_ req: Request) throws -> Future<Response> {
    //     return try req.content.decode(PostItem.self).flatMap { solution in
    //         solution.json = solution.json.replacingOccurrences(of: "\"", with: "")
    //         return solution.save(on: req).map { _ in
    //             req.redirect(to: "/")
    //         }
    //     }
    // }
}

