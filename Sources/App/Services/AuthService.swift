import Vapor
import FluentPostgreSQL
import JWT

class AuthService: Service {
    /// Creates new access and refresh token pair for logged in user
    ///
    /// Both access and refresh tokens are stored in the database.
    /// The stored values are used for further refreshing of the token and for invalidating them (logout).
    ///
    /// - Parameters:
    ///   - user: instance of user model that is logging in
    ///   - connection: instance able to connect to the database
    func createAccessToken(for user: User, on connection: DatabaseConnectable) throws -> Future<AccessTokenResponse> {
        let accessToken = try TokenHelpers.createAccessToken(from: user)
        let accessTokenValue = try TokenHelpers.getAccessTokenValue(fromPayloadOf: accessToken)
        let expiresAt = try TokenHelpers.expiredDate(of: accessToken)
        let refreshToken = TokenHelpers.createRefreshToken()
        let accessTokenResponse = AccessTokenResponse(accessToken: accessToken, refreshToken: refreshToken, expiresAt: expiresAt)
        
        return connection.transaction(on: .psql) { (database) -> EventLoopFuture<AccessTokenResponse> in
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
    
    
    /// Refreshes access token by creating new pair of access and refresh token for the same user.
    ///
    /// If provided refresh token is already expired, it throws Unauthorized error.
    ///
    /// Refreshed access token and the provided refresh token are removed from the database
    /// to prevent users from using the same refrehs token again and again.
    ///
    /// - Parameters:
    ///   - refreshToken: refresh token assigned to access token which has to be refreshed
    ///   - connection: instance able to connect to the database
    func refreshAccessToken(refreshToken: String, on connection: DatabaseConnectable) throws -> Future<AccessTokenResponse> {
        let refreshTokenModel = RefreshToken.query(on: connection)
            .filter(\.token == refreshToken)
            .first()
            .unwrap(or: Abort(.unauthorized))
        
        return refreshTokenModel.flatMap { refreshTokenModel in
            if refreshTokenModel.expiresAt > Date() {
                return refreshTokenModel.user.get(on: connection)
                    .flatMap { user in
                        return try self.createAccessToken(for: user, on: connection)
                }.then { accessToken in
                    do {
                        return try refreshTokenModel.accessTokens.query(on: connection)
                            .delete()
                            .then { _ in
                                return refreshTokenModel.delete(on: connection)
                        }
                        .transform(to: accessToken)
                    } catch {
                        return connection.future(error: error)
                    }
                    
                }
            } else {
                return refreshTokenModel.delete(on: connection).thenThrowing {
                    throw Abort(.unauthorized)
                }
            }
        }
    }
    
    
    /// Returns AccessToken model from database which has the same value as provided in parameter
    /// - Parameters:
    ///   - value: value to find
    ///   - connection: instance able to connect to the database
    func findAccessToken(value: String, on connection: DatabaseConnectable) throws -> Future<AccessToken?> {
        return AccessToken.query(on: connection)
            .filter(\.value == value)
            .first()
    }
    
    
    /// Removes access token and associated refresh token from database.
    ///
    /// Removing the tokens from database prevents using the same access/refresh token
    /// after the user logged out.
    ///
    /// - Parameters:
    ///   - token: Bearer token sent by client
    ///   - connection: instance able to connect to the database
    func invalidateToken(_ token: String, on connection: DatabaseConnectable) throws -> Future<Void> {
        let accessToken = try TokenHelpers.verifyToken(token)
        
        return try self.findAccessToken(value: accessToken.value, on: connection)
            .unwrap(or: Abort(.unauthorized))
            .flatMap { accessTokenModel in
                return accessTokenModel.refreshToken
                    .get(on: connection)
                    .delete(on: connection)
                    .transform(to: accessTokenModel)
        }.flatMap { accessTokenModel in
            return accessTokenModel.delete(on: connection)
        }
    }
}
