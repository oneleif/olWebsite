import Vapor
import FluentSQL
import Crypto
import Authentication

class BaseRouteController: RouteCollection {
    func boot(router: Router) throws {
        router.get(use: indexHandler)
    }

    func indexHandler(_ req: Request) throws -> Future<View> {
         return PostItem.query(on: req).all().flatMap { (posts) -> Future<View> in
            print("Posts: \(posts)")
            
            return try req.view().render("Children/index", IndexContext(title: "oneleif"))
         }
    }
}

struct IndexContext: Encodable {
    let title: String
}