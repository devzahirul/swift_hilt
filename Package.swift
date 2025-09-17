// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "SwiftHilt",
    platforms: [
        .iOS(.v13),
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
