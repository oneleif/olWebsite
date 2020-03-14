import Vapor

struct AccessTokenResponse: Content {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
}
