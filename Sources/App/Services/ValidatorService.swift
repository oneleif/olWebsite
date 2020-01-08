import Vapor

typealias ValidatableContent = Content & Validatable & Reflectable

enum ValidatorServiceError: Error {
    case validatorNotRegistered
}

/// Service responsible for validating request body, query or parameters.
///
/// Validation can be disabled by setting `skipValidation` to `true`.
struct ValidatorService: Service {
    
    /// Allows to skip validation of each Content passed to `validate` function.
    ///
    /// - Note:
    /// `skipValidation` does not affect Content types that were added explicitly by calling `forceValidation(of:)`
    var skipValidation: Bool = false
    
    private var ignoredContents: [Any.Type] = []
    private var forcedContents: [Any.Type] = []
    
    /// Allows to ignore validation of provided type even if the validation is enabled
    mutating func ignoreValidation<T: ValidatableContent>(of validatableType: T.Type) {
        guard !self.ignoredContents.contains(where: { $0 == validatableType }) else { return }
        self.ignoredContents.append(validatableType)
    }
    
    /// Allows to force validation of provided type even if the validation is disabled
    mutating func forceValidation<T: ValidatableContent>(of validatableType: T.Type) {
        guard !self.forcedContents.contains(where: { $0 == validatableType }) else { return }
        self.forcedContents.append(validatableType)
    }
    
    /// Validates the model, throwing an error if any of the validations fail.
    ///
    /// - Parameters:
    ///     - validatable: Content to validate
    ///
    /// Non-validation errors may also be thrown should the validators encounter unexpected errors.
    func validate<T: ValidatableContent>(_ validatable: T) throws -> Void {
        guard self.shouldValidate(validatable) else { return }
        try validatable.validate()
    }
    
    private func shouldValidate<T: ValidatableContent>(_ validatable: T) -> Bool {
        let validatableType = type(of: validatable)
        
        if self.forcedContents.contains(where: { $0 == validatableType }) {
            return true
        }
        if self.skipValidation {
            return false
        }
        
        return !self.ignoredContents.contains(where: { $0 == validatableType} )
    }
}
