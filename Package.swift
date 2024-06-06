// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "UseGraph",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(name: "UseGraph", targets: ["UseGraph"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
        .package(url: "https://github.com/apple/swift-syntax", from: "510.0.2"),
        .package(url: "https://github.com/SwiftDocOrg/GraphViz", from: "0.4.1"),
        .package(url: "https://github.com/tuist/XcodeProj", from: "8.20.0"),
        .package(url: "https://github.com/ileitch/swift-indexstore", from: "9.0.4"),
        .package(url: "https://github.com/rofle100lvl/periphery.git", branch: "SourceGraphPublic")
    ],
    targets: [
        .executableTarget(
            name: "UseGraphPeriphery",
            dependencies: [
                .product(name: "PeripheryKit", package: "periphery"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .executableTarget(
            name: "UseGraph",
            dependencies: [
                "UseGraphCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .target(
            name: "UseGraphCore",
            dependencies: [
                "Utils",
                .product(name: "XcodeProj", package: "XcodeProj"),
                .product(name: "GraphViz", package: "GraphViz"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
            ]
        ),
        .target(
            name: "XcodeSymbols",
            dependencies: [
                "Utils",
                .product(name: "SwiftIndexStore", package: "swift-indexstore")
            ]
        ),
        .target(
            name: "Utils"
        ),
        .testTarget(
            name: "UseGraphTest",
            dependencies: [
                "UseGraphCore",
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
            ]
        )
    ]
)
