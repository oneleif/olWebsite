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


class ValidatorServiceTests: XCTestCase {
    private var validator: ValidatorService! = nil
    
    var invalidDummy: DummyValidatable! = nil
    var validDummy: DummyValidatable! = nil
    
    let tooShortTest = "a"
    let okTest = "aaaa"
    
    override func setUp() {
        self.invalidDummy = DummyValidatable(test: self.tooShortTest)
        self.validDummy = DummyValidatable(test: self.okTest)
        self.validator = ValidatorService()
    }
    
    func testShouldValidateWithDefaultSetting() throws {
        XCTAssertThrowsError(try self.validator.validate(self.invalidDummy))
        XCTAssertNoThrow(try self.validator.validate(self.validDummy))
    }
    
    func testShouldSkipValidation() throws {
        self.validator.skipValidation = true
        
        XCTAssertNoThrow(try self.validator.validate(self.validDummy))
        XCTAssertNoThrow(try self.validator.validate(self.invalidDummy))
    }
    
    func testShouldNotSkipValidation() throws {
        self.validator.skipValidation = false
        
        XCTAssertThrowsError(try self.validator.validate(self.invalidDummy))
        XCTAssertNoThrow(try self.validator.validate(self.validDummy))
    }
}
