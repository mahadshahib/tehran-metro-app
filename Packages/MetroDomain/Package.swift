// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MetroDomain",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [
        .library(name: "MetroDomain", targets: ["MetroDomain"])
    ],
    targets: [
        .target(name: "MetroDomain"),
        .testTarget(
            name: "MetroDomainTests",
            dependencies: ["MetroDomain"]
        )
    ]
)
