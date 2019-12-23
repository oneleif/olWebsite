@testable import App
import Vapor
import XCTest
import FluentSQLite

class UserControllerTests: XCTestCase {
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
        
        let user = RegisterUserRequest(username: username, password: password)
        let registeredUser = try self.app.getResponse(
            to: self.registerUri,
            method: .POST,
            headers: ["Content-Type": "application/json"],
            data: user,
            decodeTo: PublicUserResponse.self
        )
        
        XCTAssertEqual(registeredUser.username, username)
        XCTAssertNotNil(registeredUser.id)
        XCTAssertNotNil(registeredUser.social)
        
        let dbUser = try User.find(registeredUser.id!, on: self.connection).wait()
        XCTAssertNotNil(dbUser)
    }
}
