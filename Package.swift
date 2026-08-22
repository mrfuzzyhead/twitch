// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Twitch",
    platforms: [
        .macOS("26.0")
    ],
    products: [
        .executable(name: "Twitch", targets: ["Twitch"])
    ],
    targets: [
        .target(name: "TwitchCore"),
        .executableTarget(
            name: "Twitch",
            dependencies: ["TwitchCore"]
        ),
        .testTarget(
            name: "TwitchCoreTests",
            dependencies: ["TwitchCore"]
        )
    ]
)
