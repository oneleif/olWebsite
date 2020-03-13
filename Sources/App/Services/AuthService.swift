import Vapor
import FluentPostgreSQL
import JWT

class AuthService: Service {
    func createAccessToken(for user: User, on database: DatabaseConnectable) throws -> Future<AccessTokenResponse> {
        let accessToken = try TokenHelpers.createAccessToken(from: user)
        let expiredAt = try TokenHelpers.expiredDate(of: accessToken)
        let refreshToken = TokenHelpers.createRefreshToken()
        let accessTokenResponse = AccessTokenResponse(accessToken: accessToken, refreshToken: refreshToken, expiredAt: expiredAt)
        
        return RefreshToken(token: refreshToken, userId: try user.requireID())
            .save(on: database)
            .transform(to: accessTokenResponse)
    }
    
    func refreshAccessToken(refreshToken: String, on request: Request) throws -> Future<AccessTokenResponse> {
        let refreshTokenModel = RefreshToken.query(on: request)
            .filter(\.token == refreshToken)
            .first()
            .unwrap(or: Abort(.unauthorized))
        
        return refreshTokenModel.flatMap { refreshTokenModel in
            if refreshTokenModel.expiredAt > Date() {
                return refreshTokenModel.user.get(on: request)
                    .flatMap { user in
                        return try self.createAccessToken(for: user, on: request)
                }.then { accessToken in
                    return refreshTokenModel.delete(on: request)
                        .transform(to: accessToken)
                }
            } else {
                return refreshTokenModel.delete(on: request).thenThrowing {
                    throw Abort(.unauthorized)
                }
            }
        }
    }
}
