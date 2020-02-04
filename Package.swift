// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "olWebsite",
    products: [
        .library(name: "olWebsite", targets: ["App"]),
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),
        .package(url: "https://github.com/vapor/fluent-sqlite.git", from: "3.0.0"),
        .package(url: "https://github.com/vapor/auth.git", from: "2.0.0"),
        .package(url: "https://github.com/vapor-community/Imperial.git", from: "0.7.1"),
        .package(url: "https://github.com/vapor/crypto.git", from: "3.0.0"),
    ],
    targets: [
        .target(name: "App", dependencies: ["FluentSQLite", "Vapor", "Authentication", "Imperial", "Crypto"]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"])
    ]
)

