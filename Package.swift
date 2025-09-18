// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SwiftHilt",
    platforms: [
        .iOS(.v16),
        .macOS(.v11),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "SwiftHilt",
            targets: ["SwiftHilt"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SwiftHilt",
            path: "Sources/SwiftHilt"
        ),
        .testTarget(
            name: "SwiftHiltTests",
            dependencies: ["SwiftHilt"],
            path: "Tests/SwiftHiltTests"
        )
    ]
)
