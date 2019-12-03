import Vapor
import FluentSQL
import Crypto
import Authentication

class AuthRouteController: RouteCollection {
    func boot(router: Router) throws {
        router.get("posts", use: listPostsHandler)

        let authSessionRouter = router.grouped(User.authSessionsMiddleware())
        let protectedRouter = authSessionRouter.grouped(RedirectMiddleware<User>(path: "/login"))
        protectedRouter.get("dashboard", use: dashboardHandler)
    }

    func dashboardHandler(_ req: Request) throws -> Future<View> {
        return PostItem.query(on: req).all().flatMap { (posts) -> Future<View> in
            let user = try req.requireAuthenticated(User.self)
            let context = DashboardContext(title: "Welcome to your dashboard")
            return try req.view().render("Children/dashboard")
        }
    }

    func listPostsHandler(_ req: Request) throws -> Future<View> {
        return PostItem.query(on: req).all().flatMap { (posts) -> Future<View> in
            // let user = try req.requireAuthenticated(User.self)
            return try req.view().render("Children/posts")
        }
    }
}

