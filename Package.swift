// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OpenMedTracker",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "OpenMedTracker",
            targets: ["OpenMedTracker"]
        ),
    ],
    dependencies: [
        // Add dependencies here
    ],
    targets: [
        .target(
            name: "OpenMedTracker",
            dependencies: [],
            path: "OpenMedTracker"
        ),
        .testTarget(
            name: "OpenMedTrackerTests",
            dependencies: ["OpenMedTracker"],
            path: "Tests/OpenMedTrackerTests"
        ),
    ]
)
