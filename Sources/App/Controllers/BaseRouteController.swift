import Vapor
import FluentSQL
import Crypto
import Authentication

class BaseRouteController: RouteCollection {
    func boot(router: Router) throws {
        router.get(use: indexHandler)
        router.get("register", use: registerHandler)
        router.get("login", use: loginHandler)

        router.post("register", use: register)
        
        let authSessionRouter = router.grouped(User.authSessionsMiddleware())
        authSessionRouter.post("login", use: login)

        router.get("logout", use: logout)
    }

    func indexHandler(_ req: Request) throws -> Future<View> {
        print(#function)
         return PostItem.query(on: req).all().flatMap { (posts) -> Future<View> in
            print("Posts: \(posts)")
            // do {
            //     return try AuthRouteController().dashboardHandler(req)
            // } catch {
                return try req.view().render("Children/index", IndexContext(title: "oneleif"))
            // }
         }
    }

  

    func loginHandler(_ req: Request) throws -> Future<View> {
        print(#function)
        let context = LeafContext(title: "Login", user: nil)
        return try req.view().render("Children/login", context)
    }

    func registerHandler(_ req: Request) throws -> Future<View> {
        print(#function)
        let context = LeafContext(title: "Register", user: nil)
        return try req.view().render("Children/register", context)
    }


    func register(_ req: Request) throws -> Future<Response> {
        print(#function)
        return try req.content.decode(User.self).flatMap { user in
            return try UserController().register(req).map { _ in
                return req.redirect(to: "/login")
            }
        }
    }
    
    func login(_ req: Request) throws -> Future<Response> {
        print(#function)
        return try req.content.decode(User.self).flatMap { user in
            return try UserController().login(req).map { _ in
                //redirect to dashboard
                return req.redirect(to: "/dashboard")
            }
        }
    }

    func logout(_ req: Request) throws -> Future<Response> {
        print(#function)
        try req.unauthenticateSession(User.self)
        return Future.map(on: req) { return req.redirect(to: "/") }
    }
}

