import Vapor
// import FluentSQL
import FluentPostgreSQL
import Crypto
import Authentication

class UserService: Service {
    func createUser(registerRequest: RegisterUserRequest, on connection: DatabaseConnectable) throws -> Future<User> {
        let hashedPassword = try BCryptDigest().hash(registerRequest.password)
        let user = User(email: registerRequest.email, password: hashedPassword)
        
        return connection.transaction(on: .psql) { (conn) -> EventLoopFuture<User> in
            return user.save(on: conn).flatMap { (user) -> EventLoopFuture<User> in
                user.social = self.newSocialInformation(for: user)
                return user.save(on: connection)
            }
        }
    }
    
    func isEmailTaken(email: String, on connection: DatabaseConnectable) -> Future<Bool> {
        return User.query(on: connection)
            .filter(\User.email == email)
            .first()
            .map { $0 != nil }
    }
    
    func authorize(email: String, password: String, on connection: DatabaseConnectable) -> Future<User?> {
        return User.authenticate(
            username: email,
            password: password,
            using: BCryptDigest(),
            on: connection
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
