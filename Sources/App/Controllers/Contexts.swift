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

struct AuthPostsContext: Encodable {
    let title: String
    let user: SocialInformation
    let posts: [PostItem]
}

struct AuthPostContext: Encodable {
    let title: String
    let user: SocialInformation
    let post: PostItem
}

struct PostsContext: Encodable {
    let title: String
    let posts: [PostItem]
}

struct CreatePostContext: Encodable {
    let title: String
    let user: SocialInformation
}

struct DashboardContext: Encodable {
    let title: String
    let user: SocialInformation
    let posts: [PostItem]
}

struct SocialContext: Encodable {
    let title: String
    let user: SocialInformation
}