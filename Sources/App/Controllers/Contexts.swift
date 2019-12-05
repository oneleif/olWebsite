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

struct DashboardContext: Encodable {
    let title: String
    let user: SocialInformation
    let posts: [PostItem]
}