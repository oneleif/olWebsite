
import FluentSQLite
import Vapor

final class Solution: SQLiteModel {
    var id: Int?
    
    var title: String
    var json: String
    var code: String
    var authorName: String
    var user: User.ID
    
    init(id: Int? = nil, title: String, json: String, code: String, user: User.ID, authorName: String) {
        self.id = id
        self.title = title
        self.json = json
        self.code = code
        self.user = user
        self.authorName = authorName
    }
}

extension Solution: Content {}
extension Solution: Parameter {}

extension Solution {
    var event: Parent<Solution, User> {
        return parent(\.user)
    }
}

extension Solution: Migration {
    // 2
    static func prepare(
        on connection: SQLiteConnection
        ) -> Future<Void> {
        // 3
        return Database.create(self, on: connection) { builder in
            // 4
            try addProperties(to: builder)
            // 5
            builder.reference(from: \.user, to: \User.id)
        }
    }
}
