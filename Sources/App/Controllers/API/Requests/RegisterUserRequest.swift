import Vapor

struct RegisterUserRequest: Content {
    var username: String
    var password: String
}
