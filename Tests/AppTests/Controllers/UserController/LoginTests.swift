//
//  LoginTests.swift
//  App
//
//  Created by Arkadiusz Żmudzin on 14/03/2020.
//

@testable import App
import Vapor
import XCTest
import FluentPostgreSQL

final class LoginTests: XCTestCase {
    let loginUri = "/api/login"
    
    static var app: Application!
    static var connection: PostgreSQLConnection!
    static var userService: UserService!
    
    let userEmail = "test@test.com"
    let userPassword = "Password#1"
    let invalidEmail = "invalid@email.com"
    let invalidPassword = "InvalidPassword:("
    
    var user: User?
    
    public override class func setUp() {
        try! Application.resetDatabase()
        self.app = try! Application.testable()
        
        self.connection = try! app.newConnection(to: .psql).wait()
        self.userService = try! app.make(UserService.self)
    }
    
    public override func setUp() {
        self.clearDatabase()
        
        let registerUser = RegisterUserRequest(email: self.userEmail, password: self.userPassword)
        self.user = try! LoginTests.userService.createUser(registerRequest: registerUser, on: LoginTests.connection).wait()
    }
    
    public override class func tearDown() {
        self.connection.close()
        try? self.app.syncShutdownGracefully()
    }
    
    func testSuccessfulLogin() throws {
        let loginRequest = LoginRequest(email: self.userEmail, password: self.userPassword)
        
        let (response, status) = try self.tryLoginUser(request: loginRequest, decodeTo: LoginResponse.self)
        
        XCTAssertEqual(status, .ok)
        XCTAssertNotNil(response)
        XCTAssertNotNil(response.user)
        XCTAssertNotNil(response.token)
    }
    
    func testShouldReturnAccessToken() throws {
        let loginRequest = LoginRequest(email: self.userEmail, password: self.userPassword)
        
        let (response, _) = try self.tryLoginUser(request: loginRequest, decodeTo: LoginResponse.self)
        
        XCTAssertNotNil(response.token.accessToken)
        XCTAssertNotEqual(response.token.accessToken, "")
        XCTAssertNotNil(response.token.refreshToken)
        XCTAssertNotEqual(response.token.refreshToken, "")
        XCTAssertNotNil(response.token.expiresAt)
    }
    
    func testShouldReturnLoggedInUser() throws {
        let loginRequest = LoginRequest(email: self.userEmail, password: self.userPassword)
        
        let (response, _) = try self.tryLoginUser(request: loginRequest, decodeTo: LoginResponse.self)
        
        XCTAssertNotNil(response.user.id)
        XCTAssertNotNil(response.user.social)
        XCTAssertNotNil(response.user.email)
    }
    
    func testInvalidPassword() throws {
        let loginRequest = LoginRequest(email: self.userEmail, password: self.invalidPassword)
        
        let (_, status) = try self.tryLoginUser(request: loginRequest, decodeTo: ErrorResponse.self)
        
        XCTAssertEqual(status, .unauthorized)
    }
    
    func testInvalidEmail() throws {
        let loginRequest = LoginRequest(email: self.invalidEmail, password: self.userPassword)
        
        let (_, status) = try self.tryLoginUser(request: loginRequest, decodeTo: ErrorResponse.self)
        
        XCTAssertEqual(status, .unauthorized)
    }
    
    func testShouldStoreAccessTokenInDatabase() throws {
        let loginRequest = LoginRequest(email: self.userEmail, password: self.userPassword)
        
        let _ = try self.tryLoginUser(request: loginRequest, decodeTo: LoginResponse.self)
        
        let accessTokensCount = try AccessToken.query(on: LoginTests.connection)
            .count()
            .wait()
        
        XCTAssertEqual(accessTokensCount, 1)
    }
    
    func testShouldStoreRefreshTokenInDatabase() throws {
        let loginRequest = LoginRequest(email: self.userEmail, password: self.userPassword)
        
        let _ = try self.tryLoginUser(request: loginRequest, decodeTo: LoginResponse.self)
        
        let refrehsTokensCount = try RefreshToken.query(on: LoginTests.connection)
            .count()
            .wait()
        
        XCTAssertEqual(refrehsTokensCount, 1)
    }
    
    private func tryLoginUser<T: Content>(request: LoginRequest, decodeTo decodeType: T.Type) throws -> (T, HTTPResponseStatus)  {
        let response = try LoginTests.app.sendRequest(
            to: self.loginUri,
            method: .POST,
            headers: ["Content-Type": "application/json"],
            body: request
        )
        
        let status = response.http.status
        let decoded: T = try response.content.decode(decodeType).wait()
        
        return (decoded, status)
    }
    
    private func clearDatabase() {
        try! LoginTests.connection.delete(from: User.self).run().wait()
        try! LoginTests.connection.delete(from: RefreshToken.self).run().wait()
        try! LoginTests.connection.delete(from: AccessToken.self).run().wait()
    }
    
    public static let allTests = [
        ("testSuccessfulLogin", testSuccessfulLogin),
        ("testShouldReturnAccessToken", testShouldReturnAccessToken),
        ("testShouldReturnLoggedInUser", testShouldReturnLoggedInUser),
        ("testInvalidPassword", testInvalidPassword),
        ("testInvalidEmail", testInvalidEmail),
        ("testShouldStoreAccessTokenInDatabase", testShouldStoreAccessTokenInDatabase),
        ("testShouldStoreRefreshTokenInDatabase", testShouldStoreRefreshTokenInDatabase)
    ]
}
