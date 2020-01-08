import Vapor

typealias ValidatableContent = Content & Validatable & Reflectable

enum ValidatorServiceError: Error {
    case validatorNotRegistered
}

struct ValidatorService: Service {
    var skipValidation: Bool = false
    
    func validate<T: ValidatableContent>(_ validatable: T) throws -> Void {
        guard !self.skipValidation else { return }
        try validatable.validate()
    }
}
