// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ConsoleDemo",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "ConsoleDemo", targets: ["ConsoleDemo"]) 
    ],
    dependencies: [
        .package(path: "../../")
    ],
    targets: [
        .executableTarget(
            name: "ConsoleDemo",
            dependencies: [
                .product(name: "SwiftHilt", package: "SwiftHilt")
            ]
        )
    ]
)

