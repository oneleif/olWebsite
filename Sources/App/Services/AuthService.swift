import Vapor
import FluentPostgreSQL
import JWT

class AuthService: Service {
    func createAccessToken(for user: User, on database: DatabaseConnectable) throws -> Future<AccessTokenResponse> {
        let accessToken = try TokenHelpers.createAccessToken(from: user)
        let expiredAt = try TokenHelpers.expiredDate(of: accessToken)
        
        let accessTokenResponse = AccessTokenResponse(accessToken: accessToken, expiredAt: expiredAt)
        
        return database.future(accessTokenResponse)
    }
}
