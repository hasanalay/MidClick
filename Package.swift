// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "MidClick",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "MidClick", targets: ["MidClick"]),
        .library(name: "MidClickCore", targets: ["MidClickCore"])
    ],
    targets: [
        .target(
            name: "MidClickCore"
        ),
        .executableTarget(
            name: "MidClick",
            dependencies: ["MidClickCore"]
        ),
        .testTarget(
            name: "MidClickCoreTests",
            dependencies: ["MidClickCore"]
        )
    ]
)
