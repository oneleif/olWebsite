@testable import App
import FluentSQLite

extension User {
    static func create(username: String = "test", password: String = "testPwd",
                       on connection: SQLiteConnection) throws -> User {
        let user = User(username: username, password: password)
        return try user.save(on: connection).wait()
    }
}
