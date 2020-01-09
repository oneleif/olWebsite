import Vapor

extension Request {
    func validate<T: ValidatableContent>(_ validatable: T) throws {
        guard let validator = try? self.make(ValidatorService.self) else { throw ValidatorServiceError.validatorNotRegistered }
        
        try validator.validate(validatable)
    }
}
