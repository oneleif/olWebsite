//
//  RefreshTokenTests.swift
//  AppTests
//
//  Created by Arkadiusz Żmudzin on 14/03/2020.
//

@testable import App
import Vapor
import XCTest
import FluentPostgreSQL

final class RefreshTokenTests: XCTestCase {
    let refreshTokenUri = "/api/refresh-token"
    
    static var app: Application!
    static var connection: PostgreSQLConnection!
    static var userService: UserService!
    static var authService: AuthService!
    
    let userEmail = "test@test.com"
    let userPassword = "Password#1"
    
    var accessToken: String!
    var refreshToken: String!
    
    let invalidRefreshToken = "invalidRefreshToken"
    
    public override class func setUp() {
        try! Application.resetDatabase()
        self.app = try! Application.testable()
        
        self.connection = try! app.newConnection(to: .psql).wait()
        self.userService = try! app.make(UserService.self)
        self.authService = try! app.make(AuthService.self)
    }
    
    public override func setUp() {
        self.clearDatabase()
        
        let registerUser = RegisterUserRequest(email: self.userEmail, password: self.userPassword)
        let user = try! RefreshTokenTests.userService.createUser(registerRequest: registerUser, on: RefreshTokenTests.connection).wait()
        
        let tokenResponse = try! RefreshTokenTests.authService.createAccessToken(for: user, on: RefreshTokenTests.connection).wait()
        
        self.accessToken = tokenResponse.accessToken
        self.refreshToken = tokenResponse.refreshToken
    }
    
    public override class func tearDown() {
        self.connection.close()
        try? self.app.syncShutdownGracefully()
    }
    
    func testSuccessfulRefresh() throws {
        let request = RefreshTokenRequest(refreshToken: self.refreshToken)
        let (_, status) = try self.tryRefreshToken(request: request, decodeTo: AccessTokenResponse.self)
        
        XCTAssertEqual(status, .ok)
    }
    
    func testShouldReturnNewAccessToken() throws {
        let request = RefreshTokenRequest(refreshToken: self.refreshToken)
        let (response, _) = try self.tryRefreshToken(request: request, decodeTo: AccessTokenResponse.self)
        
        XCTAssertNotNil(response.accessToken)
        XCTAssertNotEqual(response.accessToken, "")
    }
    
    func testShouldReturnNewRefreshToken() throws {
        let request = RefreshTokenRequest(refreshToken: self.refreshToken)
        let (response, _) = try self.tryRefreshToken(request: request, decodeTo: AccessTokenResponse.self)
        
        XCTAssertNotNil(response.refreshToken)
        XCTAssertNotEqual(response.refreshToken, "")
    }
    
    func testInvalidRefreshToken() throws {
        let request = RefreshTokenRequest(refreshToken: self.invalidRefreshToken)
        let (_, status) = try self.tryRefreshToken(request: request, decodeTo: ErrorResponse.self)
        
        XCTAssertEqual(status, .unauthorized)
    }
    
    func testShouldRemoveOldAccessToken() throws {
        let request = RefreshTokenRequest(refreshToken: self.refreshToken)
        let _ = try self.tryRefreshToken(request: request, decodeTo: AccessTokenResponse.self)
        
        let accessTokenValue = try TokenHelpers.getAccessTokenValue(fromPayloadOf: self.accessToken)
        
        let oldAccessToken = try RefreshTokenTests.authService.findAccessToken(value: accessTokenValue, on: RefreshTokenTests.connection).wait()
        
        XCTAssertNil(oldAccessToken)
    }
    
    func testShouldRemoveOldRefreshToken() throws {
        let request = RefreshTokenRequest(refreshToken: self.refreshToken)
        let _ = try self.tryRefreshToken(request: request, decodeTo: AccessTokenResponse.self)
        
        let oldRefreshToken = try RefreshToken.query(on: RefreshTokenTests.connection)
            .filter(\.token == self.refreshToken)
            .first()
            .wait()
        
        XCTAssertNil(oldRefreshToken)
    }
    
    private func tryRefreshToken<T: Content>(request: RefreshTokenRequest, decodeTo decodeType: T.Type) throws -> (T, HTTPResponseStatus)  {
        let response = try RefreshTokenTests.app.sendRequest(
            to: self.refreshTokenUri,
            method: .POST,
            headers: ["Content-Type": "application/json"],
            body: request
        )
        
        let status = response.http.status
        let decoded: T = try response.content.decode(decodeType).wait()
        
        return (decoded, status)
        
    }
    
    private func clearDatabase() {
        try! RefreshTokenTests.connection.delete(from: User.self).run().wait()
        try! RefreshTokenTests.connection.delete(from: RefreshToken.self).run().wait()
        try! RefreshTokenTests.connection.delete(from: AccessToken.self).run().wait()
    }
    
    public static let allTests = [
        ("testSuccessfulRefresh", testSuccessfulRefresh),
        ("testShouldReturnNewAccessToken", testShouldReturnNewAccessToken),
        ("testShouldReturnNewRefreshToken", testShouldReturnNewRefreshToken),
        ("testInvalidRefreshToken", testInvalidRefreshToken),
        ("testShouldRemoveOldAccessToken", testShouldRemoveOldAccessToken),
        ("testShouldRemoveOldRefreshToken", testShouldRemoveOldRefreshToken)
    ]
}

