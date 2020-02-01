@testable import App
import FluentSQLite

extension User {
    static func create(email: String = "test@test.com", password: String = "testPwd",
                       on connection: SQLiteConnection) throws -> User {
        let user = User(email: email, password: password)
        return try user.save(on: connection).wait()
    }
}
