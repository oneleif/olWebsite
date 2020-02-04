import Vapor

struct ErrorResponse: Content {
    /// Always `true` to indicate this is a non-typical JSON response.
    var error: Bool

    /// The reason for the error.
    var reason: String
}

