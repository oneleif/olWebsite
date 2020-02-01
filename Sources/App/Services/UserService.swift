import Vapor
import FluentSQL
import Crypto
import Authentication

class UserService: Service {
    func createUser(request: Request, registerRequest: RegisterUserRequest) throws -> Future<User> {
        let hashedPassword = try BCryptDigest().hash(registerRequest.password)
        let user = User(email: registerRequest.email, password: hashedPassword)
        
        return request.transaction(on: .sqlite) { (conn) -> EventLoopFuture<User> in
            return user.save(on: conn).flatMap { (user) -> EventLoopFuture<User> in
                user.social = self.newSocialInformation(for: user)
                return user.save(on: conn)
            }
        }
    }
    
    func isEmailTaken(req: Request, email: String) -> Future<Bool> {
        return User.query(on: req)
            .filter(\User.email == email)
            .first()
            .map { $0 != nil }
    }
    
    func authorize(req: Request, email: String, password: String) -> Future<User?> {
        return User.authenticate(
            username: email,
            password: password,
            using: BCryptDigest(),
            on: req
        )
    }
    
    private func newSocialInformation(for user: User) -> SocialInformation {
        return SocialInformation(
            id: user.id,
            username: "",
            firstName: "",
            lastName: "",
            email: "",
            discordUsername: "",
            githubUsername: "",
            tags: [],
            profileImage: "",
            biography: "",
            links: [],
            location: ""
        )
    }
}
