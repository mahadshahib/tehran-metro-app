// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MetroData",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [
        .library(name: "MetroData", targets: ["MetroData"])
    ],
    dependencies: [
        .package(path: "../MetroDomain")
    ],
    targets: [
        .target(
            name: "MetroData",
            dependencies: ["MetroDomain"],
            resources: [.process("Resources/stations.json")]
        ),
        .testTarget(
            name: "MetroDataTests",
            dependencies: ["MetroData", "MetroDomain"]
        )
    ]
)
