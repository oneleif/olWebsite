//
//  LogoutTests.swift
//  AppTests
//
//  Created by Arkadiusz Żmudzin on 14/03/2020.
//

@testable import App
import Vapor
import XCTest
import FluentPostgreSQL

final class LogoutTests: XCTestCase {
    let logoutUri = "/api/logout"
    
    var app: Application!
    var connection: PostgreSQLConnection!
    
    let userEmail = "test@test.com"
    let userPassword = "Password#1"
    
    var accessToken: String?
    var refreshToken: String?
    
    let invalidAccessToken = UUID().uuidString
    
    public override func setUp() {
        try! Application.resetDatabase()
        self.app = try! Application.testable()
        self.connection = try! app.newConnection(to: .psql).wait()
        
        let userService = try! app.make(UserService.self)
        let registerUser = RegisterUserRequest(email: self.userEmail, password: self.userPassword)
        let user = try! userService.createUser(registerRequest: registerUser, on: connection).wait()
        
        let authService = try! app.make(AuthService.self)
        let tokenResponse = try! authService.createAccessToken(for: user, on: self.connection).wait()
        
        self.accessToken = tokenResponse.accessToken
        self.refreshToken = tokenResponse.refreshToken
    }
    
    public override func tearDown() {
        self.connection.close()
        try? self.app.syncShutdownGracefully()
    }
    
    func testSuccessfulLogout() throws {
        let (_, status) = try self.tryLogout(accessToken: self.accessToken, decodeTo: ErrorResponse.self)
        
        XCTAssertEqual(status, .noContent)
    }
    
    func testInvalidAccessToken() throws {
        let (_, status) = try self.tryLogout(accessToken: self.invalidAccessToken, decodeTo: ErrorResponse.self)
        
        XCTAssertEqual(status, .unauthorized)
    }
    
    func testShouldRemoveAccessToken() throws {
        let _ = try self.tryLogout(accessToken: self.accessToken, decodeTo: ErrorResponse.self)
        
        let accessTokensCount = try AccessToken.query(on: self.connection)
        .count()
        .wait()
        
        XCTAssertEqual(accessTokensCount, 0)
    }
    
    func testShouldRemoveRefreshToken() throws {
        let _ = try self.tryLogout(accessToken: self.accessToken, decodeTo: ErrorResponse.self)
        
        let refrehsTokensCount = try RefreshToken.query(on: self.connection)
            .count()
            .wait()
        
        XCTAssertEqual(refrehsTokensCount, 0)
    }
        
    private func tryLogout<T: Content>(accessToken: String? = nil, decodeTo decodeType: T.Type) throws -> (T?, HTTPResponseStatus)  {
        let response = try self.app.sendRequest(
            to: self.logoutUri,
            method: .GET,
            headers: [
                "Content-Type": "application/json",
                "Authorization": "Bearer \(accessToken ?? "")"
            ]
        )
        
        let status = response.http.status
        if status != .noContent {
            let decoded: T = try response.content.decode(decodeType).wait()
            return (decoded, status)
        }
        return (nil, status)
    }

    public static let allTests = [
        ("testSuccessfulLogout", testSuccessfulLogout),
        ("testInvalidAccessToken", testInvalidAccessToken),
        ("testShouldRemoveAccessToken", testShouldRemoveAccessToken),
        ("testShouldRemoveRefreshToken", testShouldRemoveRefreshToken)
    ]
}
