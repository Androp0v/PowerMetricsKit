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
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0")
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
    ],
    swiftLanguageVersions: [.v5, .version("6")]
)
