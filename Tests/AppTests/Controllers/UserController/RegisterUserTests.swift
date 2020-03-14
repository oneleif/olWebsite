@testable import App
import Vapor
import XCTest
import FluentPostgreSQL

final class RegisterUserTests: XCTestCase {
    let registerUri = "/api/register"
    
    var app: Application!
    var connection: PostgreSQLConnection!
    
    public override func setUp() {
        try! Application.resetDatabase()
        self.app = try! Application.testable()
        self.connection = try! app.newConnection(to: .psql).wait()
    }
    
    public override func tearDown() {
        self.connection.close()
        try? self.app.syncShutdownGracefully()
    }
    
    func testUserCanRegister() throws {
        let email = "test@email.com"
        let password = "testPassword1!"
        
        let request = RegisterUserRequest(email: email, password: password)
        let (registeredUser, status) = try self.tryRegisterUser(request: request, decodeTo: PublicUserResponse.self)
        
        XCTAssertNotNil(registeredUser)
        XCTAssertNotNil(status)
        
        XCTAssertEqual(status, .created)
        
        XCTAssertEqual(registeredUser.email, email)
        XCTAssertNotNil(registeredUser.id)
        XCTAssertNotNil(registeredUser.social)
        
        let dbUser = try User.find(registeredUser.id!, on: self.connection).wait()
        XCTAssertNotNil(dbUser)
    }
    
    func testInvalidEmailValidation() throws {
        let email = "u"
        let password = "testPassword1!"
        
        let request = RegisterUserRequest(email: email, password: password)
        
        let (errorResponse, status) = try self.tryRegisterUser(request: request, decodeTo: ErrorResponse.self)
        
        XCTAssertNotNil(errorResponse)
        XCTAssertNotNil(status)
        XCTAssertEqual(status, .badRequest)
        XCTAssertTrue(errorResponse.reason.contains("'email' is not a valid email address"))
    }
    
    func testPasswordTooShortValidation() throws {
        let email = "test@test.com"
        let password = "pwd1$"
        
        let request = RegisterUserRequest(email: email, password: password)
        
        let (errorResponse, status) = try self.tryRegisterUser(request: request, decodeTo: ErrorResponse.self)
        
        XCTAssertNotNil(errorResponse)
        XCTAssertNotNil(status)
        XCTAssertEqual(status, .badRequest)
        XCTAssertTrue(errorResponse.reason.contains("'password' is less than required minimum of 6 characters"))
    }
    
    func testPasswordMissingLowercaseLetterValidation() throws {
        let email = "test@test.com"
        let password = "TEST_PWD"
        
        let request = RegisterUserRequest(email: email, password: password)
        
        let (errorResponse, status) = try self.tryRegisterUser(request: request, decodeTo: ErrorResponse.self)
        
        XCTAssertNotNil(errorResponse)
        XCTAssertNotNil(status)
        XCTAssertEqual(status, .badRequest)
        XCTAssertTrue(errorResponse.reason.contains("'password' must contain lowercase letter"))
    }
    
    func testPasswordMissingUppercaseLetterValidation() throws {
        let email = "test@test.com"
        let password = "test_pwd"
        
        let request = RegisterUserRequest(email: email, password: password)
        
        let (errorResponse, status) = try self.tryRegisterUser(request: request, decodeTo: ErrorResponse.self)
        
        XCTAssertNotNil(errorResponse)
        XCTAssertNotNil(status)
        XCTAssertEqual(status, .badRequest)
        XCTAssertTrue(errorResponse.reason.contains("'password' must contain uppercase letter"))
    }
    
    func testPasswordMissingDigitValidation() throws {
        let email = "test@test.com"
        let password = "test_pwd"
        
        let request = RegisterUserRequest(email: email, password: password)
        
        let (errorResponse, status) = try self.tryRegisterUser(request: request, decodeTo: ErrorResponse.self)
        
        XCTAssertNotNil(errorResponse)
        XCTAssertNotNil(status)
        XCTAssertEqual(status, .badRequest)
        XCTAssertTrue(errorResponse.reason.contains("'password' must contain digit"))
    }
    
    func testPasswordMissingSpecialCharacterValidation() throws {
        let email = "test@test.com"
        let password = "testpwd"
        
        let request = RegisterUserRequest(email: email, password: password)
        
        let (errorResponse, status) = try self.tryRegisterUser(request: request, decodeTo: ErrorResponse.self)
        
        XCTAssertNotNil(errorResponse)
        XCTAssertNotNil(status)
        XCTAssertEqual(status, .badRequest)
        XCTAssertTrue(errorResponse.reason.contains("'password' must contain special character"))
    }
    
    func testEmailTakenValidation() throws {
        let email = "test@test.com"
        let password = "testPwd1#"
        
        let request = RegisterUserRequest(email: email, password: password)
        
        let _ = try self.tryRegisterUser(request: request, decodeTo: PublicUserResponse.self)
        
        let (errorResponse, status) = try self.tryRegisterUser(request: request, decodeTo: ErrorResponse.self)
        
        XCTAssertNotNil(errorResponse)
        XCTAssertNotNil(status)
        XCTAssertEqual(status, .badRequest)
        XCTAssertTrue(errorResponse.reason.contains("email already taken"))
    }
    
    private func tryRegisterUser<T: Content>(request: RegisterUserRequest, decodeTo decodeType: T.Type) throws -> (T, HTTPResponseStatus)  {
        let response = try self.app.sendRequest(
            to: self.registerUri,
            method: .POST,
            headers: ["Content-Type": "application/json"],
            body: request
        )
        
        let status = response.http.status
        let decoded: T = try response.content.decode(decodeType).wait()
        
        return (decoded, status)
    }

    public static let allTests = [
        ("testEmailTakenValidation", testEmailTakenValidation),
        ("testPasswordMissingSpecialCharacterValidation", testPasswordMissingSpecialCharacterValidation),
        ("testPasswordMissingDigitValidation", testPasswordMissingDigitValidation),
        ("testPasswordMissingUppercaseLetterValidation", testPasswordMissingUppercaseLetterValidation),
        ("testPasswordMissingLowercaseLetterValidation", testPasswordMissingLowercaseLetterValidation),
        ("testPasswordTooShortValidation", testPasswordTooShortValidation),
        ("testInvalidEmailValidation", testInvalidEmailValidation),
        ("testUserCanRegister", testUserCanRegister)
    ]
}
