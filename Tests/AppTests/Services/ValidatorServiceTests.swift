@testable import App
import Vapor
import XCTest

struct DummyValidatable: ValidatableContent {
    var test: String
    
    static func validations() throws -> Validations<DummyValidatable> {
        var validations = Validations(DummyValidatable.self)
        try validations.add(\.test, .count(3...))
        return validations
    }
}

struct EvenDummierValidatable: ValidatableContent {
    var test: String
    
    static func validations() throws -> Validations<EvenDummierValidatable> {
        var validations = Validations(EvenDummierValidatable.self)
        try validations.add(\.test, .count(3...))
        return validations
    }
}


class ValidatorServiceTests: XCTestCase {
    private var validator: ValidatorService! = nil
    
    var invalidDummy: DummyValidatable! = nil
    var validDummy: DummyValidatable! = nil
    var invalidDummier: EvenDummierValidatable! = nil
    
    let tooShortTest = "a"
    let okTest = "aaaa"
    
    override func setUp() {
        self.invalidDummy = DummyValidatable(test: self.tooShortTest)
        self.validDummy = DummyValidatable(test: self.okTest)
        
        self.invalidDummier = EvenDummierValidatable(test: self.tooShortTest)
        
        self.validator = ValidatorService()
    }
    
    func testShouldValidateWithDefaultSetting() throws {
        XCTAssertThrowsError(try self.validator.validate(self.invalidDummy))
        XCTAssertNoThrow(try self.validator.validate(self.validDummy))
    }
    
    func testShouldSkipAllValidations() throws {
        self.validator.skipValidation = true
        
        XCTAssertNoThrow(try self.validator.validate(self.validDummy))
        XCTAssertNoThrow(try self.validator.validate(self.invalidDummy))
    }
    
    func testShouldNotSkipValidation() throws {
        self.validator.skipValidation = false
        
        XCTAssertThrowsError(try self.validator.validate(self.invalidDummy))
        XCTAssertNoThrow(try self.validator.validate(self.validDummy))
    }
    
    func testShouldValidateForcedEvenWhenValidationIsSkipped() throws {
        self.validator.skipValidation = true
        self.validator.forceValidation(of: EvenDummierValidatable.self)
        
        XCTAssertThrowsError(try self.validator.validate(self.invalidDummier))
        XCTAssertNoThrow(try self.validator.validate(self.invalidDummy))
    }
    
    func testShouldNotValidateIgnored() throws {
        self.validator.ignoreValidation(of: EvenDummierValidatable.self)
        
        XCTAssertThrowsError(try self.validator.validate(self.invalidDummy))
        XCTAssertNoThrow(try self.validator.validate(self.invalidDummier))
    }

    public static var allTests = [
      ("testShouldValidateWithDefaultSetting", testShouldValidateWithDefaultSetting),
      ("testShouldSkipAllValidations", testShouldSkipAllValidations),
      ("testShouldSkipAllValidations", testShouldSkipAllValidations),
      ("testShouldValidateForcedEvenWhenValidationIsSkipped", testShouldValidateForcedEvenWhenValidationIsSkipped),
      ("testShouldNotValidateIgnored", testShouldNotValidateIgnored)
    ]
}
