import Vapor
import FluentSQL
import Crypto
import Authentication

class AuthRouteController: RouteCollection {
    func boot(router: Router) throws {
        let authSessionRouter = router.grouped(User.authSessionsMiddleware())
        let protectedRouter = authSessionRouter.grouped(RedirectMiddleware<User>(path: "/login"))
        protectedRouter.get(use: indexHandler)
        
    }

    func indexHandler(_ req: Request) throws -> Future<View> {
        return PostItem.query(on: req).all().flatMap { (posts) -> Future<View> in
            let user = try req.requireAuthenticated(User.self)
            return try req.view().render("Children/index")
        }
    }
}

struct LeafContext: Encodable {
    let title: String
    let user: User?
}

// struct SolutionsContext: Encodable {
//     let solutions: [Solution]
//     let user: User
//     let title: String
// }

// struct SolutionContext: Encodable {
//     let solution: Solution
//     let user: User
//     let title: String
// }

struct HomeContext: Encodable {
    let title: String = "Home"
    let user: User
    // let userSolutions: [Solution]
}