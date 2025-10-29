// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ReelsIOS",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "ReelsIOS",
            targets: ["ReelsIOS"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ReelsIOS",
            dependencies: [],
            path: "Sources/ReelsIOS"
        )
    ]
)
