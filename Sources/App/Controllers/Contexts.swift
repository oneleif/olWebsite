struct LeafContext: Encodable {
    let title: String
    let user: User?
}

struct HomeContext: Encodable {
    let title: String = "Home"
    let user: User
}

struct IndexContext: Encodable {
    let title: String
}

struct PostsContext: Encodable {
    let posts: [PostItem]
    let user: User
    let title: String
}

struct DashboardContext: Encodable {
    let title: String
}