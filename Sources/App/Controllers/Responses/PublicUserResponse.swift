import Vapor

struct PublicUserResponse: Content {
    var id: Int?
    var email: String
    var social: SocialInformation?
}
