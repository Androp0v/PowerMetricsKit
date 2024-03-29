// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "PowerMetricsKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "PowerMetricsKit",
            targets: ["PowerMetricsKit"]
        ),
    ],
    targets: [
        .target(
            name: "SampleThreads",
            dependencies: [],
            path: "Sources/SampleThreads"
        ),
        .target(
            name: "PowerMetricsKit",
            dependencies: [
                .target(name: "SampleThreads")
            ],
            path: "Sources/PowerMetricsKit"
        )
    ]
)
