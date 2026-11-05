// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "TennisScoring",
    platforms: [
        .watchOS(.v11),
        .iOS(.v18),
        .macOS(.v14)
    ],
    products: [
        .library(name: "TennisScoring", targets: ["TennisScoring"])
    ],
    targets: [
        .target(name: "TennisScoring"),
        .testTarget(name: "TennisScoringTests", dependencies: ["TennisScoring"])
    ]
)
