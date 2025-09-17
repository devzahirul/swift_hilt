// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SwiftHilt",
    platforms: [
        .iOS(.v13),
        .macOS(.v11),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0")
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
        .library(
            name: "SwiftHiltMacros",
            targets: ["SwiftHiltMacros"]
        ),
    ],
    targets: [
        .target(
            name: "SwiftHilt",
            dependencies: [
                // Re-export macros for convenience if present
                .target(name: "SwiftHiltMacros", condition: .when(platforms: [.iOS, .macOS, .tvOS, .watchOS]))
            ],
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
        .macro(
            name: "SwiftHiltMacros",
            dependencies: [
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
            ],
            path: "Sources/SwiftHiltMacros"
        ),
        .testTarget(
            name: "SwiftHiltTests",
            dependencies: ["SwiftHilt"],
            path: "Tests/SwiftHiltTests"
        )
    ]
)
