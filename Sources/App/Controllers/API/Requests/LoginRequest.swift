import Vapor

struct LoginRequest: Content {
    var username: String
    var password: String
}
