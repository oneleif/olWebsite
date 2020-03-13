import FluentPostgreSQL
import Vapor
import JWT

final class RefreshToken: PostgreSQLModel {
    var id: Int?
    
    fileprivate enum Constants {
        static let refreshTokenTime: TimeInterval = 7 * 60 * 24 * 60 * 60
        
    }
    
    var userId: Int
    var token: String
    var expiredAt: Date
    
    init(id: Int? = nil,
         token: String,
         expiredAt: Date = Date().addingTimeInterval(Constants.refreshTokenTime),
         userId: User.ID) {
        self.id = id
        self.token = token
        self.expiredAt = expiredAt
        self.userId = userId
    }
    
    func updateExpiredDate() {
        self.expiredAt = Date().addingTimeInterval(Constants.refreshTokenTime)
    }
}

extension RefreshToken {
    var user: Parent<RefreshToken, User> {
        return self.parent(\.userId)
    }
}

extension RefreshToken: Migration { }
extension RefreshToken: Parameter { }
