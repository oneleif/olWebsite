import Vapor

struct RegisterUserRequest: Content {
    var username: String
    var password: String
}

extension RegisterUserRequest: Validatable, Reflectable {
    static func validations() throws -> Validations<RegisterUserRequest> {
        var validations = Validations(RegisterUserRequest.self)
        
        try validations.add(\.username, .count(3...))
        try validations.add(\.password, .count(6...))
        
        try validations.add(\.password, "contains lowecase letter") { password in
            let regex = NSRegularExpression("[a-z]")
            guard regex.matches(password) else {
                throw BasicValidationError("must contain lowercase letter")
            }
        }
        
        try validations.add(\.password, "contains uppercase letter") { password in
            let regex = NSRegularExpression("[A-Z]")
            guard regex.matches(password) else {
                throw BasicValidationError("must contain uppercase letter")
            }
        }
        
        try validations.add(\.password, "contains digits") { password in
            let regex = NSRegularExpression("\\d")
            guard regex.matches(password) else {
                throw BasicValidationError("must contain digit")
            }
        }
        
        try validations.add(\.password, "contains special characters") { password in
            let regex = NSRegularExpression("[^A-Za-z0-9]")
            guard regex.matches(password) else {
                throw BasicValidationError("must contain special character")
            }
        }
        
        return validations
    }
}
