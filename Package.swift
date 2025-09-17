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
        ),
        .executable(
            name: "SwiftHiltDemo",
            targets: ["SwiftHiltDemo"]
        ),
        .executable(
            name: "DAGSample",
            targets: ["DAGSample"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SwiftHilt",
            path: "Sources/SwiftHilt"
        ),
        .executableTarget(
            name: "SwiftHiltDemo",
            dependencies: ["SwiftHilt"],
            path: "Examples/SwiftHiltDemo",
            resources: [
                .process("Resources")
            ]
        ),
        .executableTarget(
            name: "SwiftHiltDemo_iOS",
            dependencies: ["SwiftHilt"],
            path: "Examples/SwiftHiltDemo_iOS/SwiftHiltDemo_iOS",
            resources: [
                .process("Resources")
            ]
        ),
        .executableTarget(
            name: "DAGSample",
            dependencies: ["SwiftHilt"],
            path: "Examples/DAGSample"
        ),
        .testTarget(
            name: "SwiftHiltTests",
            dependencies: ["SwiftHilt"],
            path: "Tests/SwiftHiltTests"
        )
    ]
)
