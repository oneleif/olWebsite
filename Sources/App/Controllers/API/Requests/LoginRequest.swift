import Vapor

struct LoginRequest: Content {
    var email: String
    var password: String
}
