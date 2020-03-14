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
    
    static var app: Application!
    static var connection: PostgreSQLConnection!
    static var userService: UserService!
    static var authService: AuthService!
    
    let userEmail = "test@test.com"
    let userPassword = "Password#1"
    
    var accessToken: String?
    
    let invalidAccessToken = UUID().uuidString
    
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
        let user = try! LogoutTests.userService.createUser(registerRequest: registerUser, on: LogoutTests.connection).wait()
        
        let tokenResponse = try! LogoutTests.authService.createAccessToken(for: user, on: LogoutTests.connection).wait()
        
        self.accessToken = tokenResponse.accessToken
    }
    
    public override class func tearDown() {
        LogoutTests.connection.close()
        try? LogoutTests.app.syncShutdownGracefully()
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
        
        let accessTokensCount = try AccessToken.query(on: LogoutTests.connection)
            .count()
            .wait()
        
        XCTAssertEqual(accessTokensCount, 0)
    }
    
    func testShouldRemoveRefreshToken() throws {
        let _ = try self.tryLogout(accessToken: self.accessToken, decodeTo: ErrorResponse.self)
        
        let refrehsTokensCount = try RefreshToken.query(on: LogoutTests.connection)
            .count()
            .wait()
        
        XCTAssertEqual(refrehsTokensCount, 0)
    }
    
    private func tryLogout<T: Content>(accessToken: String? = nil, decodeTo decodeType: T.Type) throws -> (T?, HTTPResponseStatus)  {
        let response = try LogoutTests.app.sendRequest(
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
    
    private func clearDatabase() {
        try! LogoutTests.connection.delete(from: User.self).run().wait()
        try! LogoutTests.connection.delete(from: RefreshToken.self).run().wait()
        try! LogoutTests.connection.delete(from: AccessToken.self).run().wait()
    }
    
    public static let allTests = [
        ("testSuccessfulLogout", testSuccessfulLogout),
        ("testInvalidAccessToken", testInvalidAccessToken),
        ("testShouldRemoveAccessToken", testShouldRemoveAccessToken),
        ("testShouldRemoveRefreshToken", testShouldRemoveRefreshToken)
    ]
}
