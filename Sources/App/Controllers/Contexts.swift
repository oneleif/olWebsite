struct LeafContext: Encodable {
    let title: String
    let user: SocialInformation?
}

struct HomeContext: Encodable {
    let title: String = "Home"
    let user: SocialInformation
}

struct IndexContext: Encodable {
    let title: String
}

struct PostsContext: Encodable {
    let title: String
    let user: SocialInformation
    let posts: [PostItem]
}

struct CreatePostContext: Encodable {
    let title: String
    let user: SocialInformation
<<<<<<< HEAD
=======
    let url: String
>>>>>>> 0b51715e508d936f79d6feed4ae31e7b5956cb89
}

struct DashboardContext: Encodable {
    let title: String
    let user: SocialInformation
    let posts: [PostItem]
}