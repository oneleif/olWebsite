import FluentPostgreSQL
import Vapor
import JWT

final class RefreshToken: PostgreSQLModel {
    var id: Int?
    
    fileprivate enum Constants {
        static let refreshTokenTime: TimeInterval = 14 * 24 * 60 * 60
    }
    
    var userId: Int
    var token: String
    var expiresAt: Date
    
    init(id: Int? = nil,
         token: String,
         expiresAt: Date = Date().addingTimeInterval(Constants.refreshTokenTime),
         userId: User.ID) {
        self.id = id
        self.token = token
        self.expiresAt = expiresAt
        self.userId = userId
    }
    
    func updateExpiredDate() {
        self.expiresAt = Date().addingTimeInterval(Constants.refreshTokenTime)
    }
}

extension RefreshToken {
    var user: Parent<RefreshToken, User> {
        return self.parent(\.userId)
    }
    
    var accessTokens: Children<RefreshToken, AccessToken> {
        return self.children(\.refreshTokenId)
    }
}

extension RefreshToken: Migration { }
extension RefreshToken: Parameter { }
