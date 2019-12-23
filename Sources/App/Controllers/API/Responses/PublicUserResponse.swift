import Vapor

struct PublicUserResponse: Content {
    var id: Int?
    var username: String
    var social: SocialInformation?
}
