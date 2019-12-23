@testable import App
import Vapor
import XCTest
import FluentSQLite

class RegisterUserTests: XCTestCase {
    let registerUri = "/api/register"
    
    var app: Application!
    var connection: SQLiteConnection!
    
    override func setUp() {
        try! Application.resetDatabase()
        self.app = try! Application.testable()
        self.connection = try! app.newConnection(to: .sqlite).wait()
    }
    
    override func tearDown() {
        self.connection.close()
        try? self.app.syncShutdownGracefully()
    }
    
    func testUserCanRegister() throws {
        let username = "testUsername"
        let password = "testPassword1!"
        
        let request = RegisterUserRequest(username: username, password: password)
        let (registeredUser, status) = try self.tryRegisterUser(request: request, decodeTo: PublicUserResponse.self)
        
        XCTAssertNotNil(registeredUser)
        XCTAssertNotNil(status)
        
        XCTAssertEqual(status, .created)
        
        XCTAssertEqual(registeredUser.username, username)
        XCTAssertNotNil(registeredUser.id)
        XCTAssertNotNil(registeredUser.social)
        
        let dbUser = try User.find(registeredUser.id!, on: self.connection).wait()
        XCTAssertNotNil(dbUser)
    }
    
    func testUsernameTooShortValidation() throws {
        let username = "u"
        let password = "testPassword1!"
        
        let request = RegisterUserRequest(username: username, password: password)
        
        let (errorResponse, status) = try self.tryRegisterUser(request: request, decodeTo: ErrorResponse.self)
        
        XCTAssertNotNil(errorResponse)
        XCTAssertNotNil(status)
        XCTAssertEqual(status, .badRequest)
        XCTAssertTrue(errorResponse.reason.contains("'username' is less than required minimum of 3 characters"))
    }
    
    func testPasswordTooShortValidation() throws {
        let username = "testUser"
        let password = "pwd1$"
        
        let request = RegisterUserRequest(username: username, password: password)
        
        let (errorResponse, status) = try self.tryRegisterUser(request: request, decodeTo: ErrorResponse.self)
        
        XCTAssertNotNil(errorResponse)
        XCTAssertNotNil(status)
        XCTAssertEqual(status, .badRequest)
        XCTAssertTrue(errorResponse.reason.contains("'password' is less than required minimum of 6 characters"))
    }
    
    func testPasswordMissingLowercaseLetterValidation() throws {
        let username = "testUser"
        let password = "TEST_PWD"
        
        let request = RegisterUserRequest(username: username, password: password)
        
        let (errorResponse, status) = try self.tryRegisterUser(request: request, decodeTo: ErrorResponse.self)
        
        XCTAssertNotNil(errorResponse)
        XCTAssertNotNil(status)
        XCTAssertEqual(status, .badRequest)
        XCTAssertTrue(errorResponse.reason.contains("'password' must contain lowercase letter"))
    }
    
    func testPasswordMissingUppercaseLetterValidation() throws {
        let username = "testUser"
        let password = "test_pwd"
        
        let request = RegisterUserRequest(username: username, password: password)
        
        let (errorResponse, status) = try self.tryRegisterUser(request: request, decodeTo: ErrorResponse.self)
        
        XCTAssertNotNil(errorResponse)
        XCTAssertNotNil(status)
        XCTAssertEqual(status, .badRequest)
        XCTAssertTrue(errorResponse.reason.contains("'password' must contain uppercase letter"))
    }
    
    func testPasswordMissingDigitValidation() throws {
        let username = "testUser"
        let password = "test_pwd"
        
        let request = RegisterUserRequest(username: username, password: password)
        
        let (errorResponse, status) = try self.tryRegisterUser(request: request, decodeTo: ErrorResponse.self)
        
        XCTAssertNotNil(errorResponse)
        XCTAssertNotNil(status)
        XCTAssertEqual(status, .badRequest)
        XCTAssertTrue(errorResponse.reason.contains("'password' must contain digit"))
    }
    
    func testPasswordMissingSpecialCharacterValidation() throws {
        let username = "testUser"
        let password = "testpwd"
        
        let request = RegisterUserRequest(username: username, password: password)
        
        let (errorResponse, status) = try self.tryRegisterUser(request: request, decodeTo: ErrorResponse.self)
        
        XCTAssertNotNil(errorResponse)
        XCTAssertNotNil(status)
        XCTAssertEqual(status, .badRequest)
        XCTAssertTrue(errorResponse.reason.contains("'password' must contain special character"))
    }
    
    func testUsernameTakenValidation() throws {
        let username = "testUser"
        let password = "testPwd1#"
        
        let request = RegisterUserRequest(username: username, password: password)
        
        let _ = try self.tryRegisterUser(request: request, decodeTo: PublicUserResponse.self)
        
        let (errorResponse, status) = try self.tryRegisterUser(request: request, decodeTo: ErrorResponse.self)
        
        XCTAssertNotNil(errorResponse)
        XCTAssertNotNil(status)
        XCTAssertEqual(status, .badRequest)
        XCTAssertTrue(errorResponse.reason.contains("username already taken"))
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
}
