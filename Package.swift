// swift-tools-version: 5.10
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
        .package(url: "https://github.com/apple/swift-syntax", from: "509.0.2"),
        .package(url: "https://github.com/SwiftDocOrg/GraphViz", from: "0.4.1"),
    ],
    targets: [
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
                .product(name: "GraphViz", package: "GraphViz"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
            ]
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
