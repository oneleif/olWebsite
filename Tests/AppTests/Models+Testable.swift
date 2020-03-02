@testable import App
import FluentPostgreSQL

extension User {
    static func create(email: String = "test@test.com", password: String = "testPwd",
                       on connection: PostgreSQLConnection) throws -> User {
        let user = User(email: email, password: password)
        return try user.save(on: connection).wait()
    }
}
