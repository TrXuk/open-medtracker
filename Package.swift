// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MedTracker",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "MedTracker",
            targets: ["MedTracker"])
    ],
    dependencies: [
        // Add your Swift package dependencies here
        // Example:
        // .package(url: "https://github.com/example/package.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "MedTracker",
            dependencies: [],
            path: "MedTracker"
        ),
        .testTarget(
            name: "MedTrackerTests",
            dependencies: ["MedTracker"],
            path: "MedTrackerTests"
        )
    ]
)
