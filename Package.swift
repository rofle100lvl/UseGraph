// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "UseGraph",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(name: "UseGraphFrontend", targets: ["UseGraphFrontend"]),
        .executable(name: "UseGraph", targets: ["UseGraph"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
        .package(url: "https://github.com/rofle100lvl/periphery/", branch: "PublicPackageAccess"),
        .package(url: "https://github.com/apple/swift-syntax", from: "600.0.1"),
        .package(url: "https://github.com/SwiftDocOrg/GraphViz", from: "0.4.1"),
        .package(url: "https://github.com/tuist/XcodeProj", from: "8.20.0"),
        .package(url: "https://github.com/kateinoigakukun/swift-indexstore", from: "0.3.0"),
    ],
    targets: [
        .target(
            name: "UseGraphPeriphery",
            dependencies: [
                .product(name: "PeripheryKit", package: "periphery"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "GraphViz", package: "GraphViz"),
                .product(name: "SwiftIndexStore", package: "swift-indexstore"),
                "Utils",
                "UseGraphCore"
            ]
        ),
        .executableTarget(
            name: "UseGraph",
            dependencies: [
                "UseGraphFrontend",
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "XcodeProj", package: "XcodeProj"),
            ]
        ),
        .target(
            name: "UseGraphStaticAnalysis",
            dependencies: [
                "UseGraphCore",
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "XcodeProj", package: "XcodeProj"),
                .product(name: "GraphViz", package: "GraphViz"),
            ]
        ),
        .target(
            name: "UseGraphFrontend",
            dependencies: [
                "UseGraphCore",
                "UseGraphStaticAnalysis",
                "UseGraphPeriphery",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .target(
            name: "UseGraphCore",
            dependencies: [
                "Utils",
                .product(name: "GraphViz", package: "GraphViz"),
            ]
        ),
        .target(
            name: "Utils"
        ),
//        .testTarget(
//            name: "UseGraphTest",
//            dependencies: [
//                "UseGraphCore",
//                .product(name: "SwiftSyntax", package: "swift-syntax"),
//                .product(name: "SwiftParser", package: "swift-syntax"),
//            ]
//        ),
    ]
)
