import Vapor

struct RefreshTokenRequest: Content {
    var refreshToken: String
}

extension RefreshTokenRequest: Validatable, Reflectable {
    static func validations() throws -> Validations<RefreshTokenRequest> {
        var validations = Validations(RefreshTokenRequest.self)
        
        try validations.add(\.refreshToken, .alphanumeric)
        try validations.add(\.refreshToken, .count(1...))
        
        return validations
    }
}
