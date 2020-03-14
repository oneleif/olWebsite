import Vapor
import FluentPostgreSQL
import JWT

class AuthService: Service {
    func createAccessToken(for user: User, on database: DatabaseConnectable) throws -> Future<AccessTokenResponse> {
        let accessToken = try TokenHelpers.createAccessToken(from: user)
        let accessTokenValue = try TokenHelpers.getAccessTokenValue(fromPayloadOf: accessToken)
        let expiresAt = try TokenHelpers.expiredDate(of: accessToken)
        let refreshToken = TokenHelpers.createRefreshToken()
        let accessTokenResponse = AccessTokenResponse(accessToken: accessToken, refreshToken: refreshToken, expiresAt: expiresAt)
        
        return database.transaction(on: .psql) { (database) -> EventLoopFuture<AccessTokenResponse> in
            return RefreshToken(token: refreshToken, userId: try user.requireID())
                .save(on: database)
                .flatMap { refreshTokenModel in
                    return AccessToken(
                        value: accessTokenValue,
                        refreshTokenId: try refreshTokenModel.requireID(),
                        userId: try user.requireID(),
                        expiresAt: expiresAt).save(on: database)
            }.transform(to: accessTokenResponse)
        }
    }
    
    func refreshAccessToken(refreshToken: String, on request: Request) throws -> Future<AccessTokenResponse> {
        let refreshTokenModel = RefreshToken.query(on: request)
            .filter(\.token == refreshToken)
            .first()
            .unwrap(or: Abort(.unauthorized))
        
        return refreshTokenModel.flatMap { refreshTokenModel in
            if refreshTokenModel.expiresAt > Date() {
                return refreshTokenModel.user.get(on: request)
                    .flatMap { user in
                        return try self.createAccessToken(for: user, on: request)
                }.then { accessToken in
                    do {
                        return try refreshTokenModel.accessTokens.query(on: request)
                            .delete()
                            .then { _ in
                                return refreshTokenModel.delete(on: request)
                        }
                        .transform(to: accessToken)
                    } catch {
                        return request.future(error: error)
                    }
                    
                }
            } else {
                return refreshTokenModel.delete(on: request).thenThrowing {
                    throw Abort(.unauthorized)
                }
            }
        }
    }
    
    func findAccessToken(value: String, on request: Request) throws -> Future<AccessToken?> {
        return AccessToken.query(on: request)
            .filter(\.value == value)
            .first()
    }
}
