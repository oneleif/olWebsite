import Vapor

struct AccessTokenResponse: Content {
    let accessToken: String
    let expiredAt: Date
}
